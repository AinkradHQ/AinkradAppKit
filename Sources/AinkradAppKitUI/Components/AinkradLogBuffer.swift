import Foundation

/// Which output stream a log line came from. `stderr` lines are the ones a view dims.
public enum AinkradLogStream: Hashable, Sendable {
    case stdout
    case stderr
}

/// One line of process output, ready to render.
public struct AinkradLogLine: Equatable, Sendable, Identifiable {
    public let id: Int
    public let stream: AinkradLogStream
    /// Which source produced it — a service, a process, an agent. Non-nil only
    /// when several sources share one pane, where it becomes the line's prefix.
    public let source: String?
    public let runs: [AinkradStyledRun]

    public var plainText: String { runs.map(\.text).joined() }
}

/// A bounded, append-only line store for a log pane.
///
/// **A ring buffer, and the bound is the point.** 24 services at follow produce
/// hundreds of lines a second; an unbounded store is an out-of-memory in a few
/// minutes, and a SwiftUI list diffing it dies long before that. Dropping the
/// oldest lines is the correct behaviour for a log tail — that is what `tail`
/// means. A view renders it with whole-buffer replace on change, never an
/// incremental append that has to reason about lines dropping off the front.
///
/// Source-agnostic: it takes text or raw bytes, never a transport's frame type.
/// Moved here from Thrall's `ThrallLogBuffer`, with three fixes: a UTF-8
/// character split across reads, a CRLF split across reads, and the stream a
/// flushed partial line is labelled with.
public struct AinkradLogBuffer {
    /// A line longer than this is a minified blob or a base64 payload, and
    /// holding it whole would let one line defeat the whole cap.
    static let maximumLineLength = 8 * 1024

    public let capacity: Int
    private var lines: [AinkradLogLine] = []
    private var nextID = 0
    /// Partial trailing text per source, since a read boundary lands mid-line constantly.
    private var carry: [String: String] = [:]
    /// Bytes of a UTF-8 character that has not finished arriving, per source.
    private var byteCarry: [String: Data] = [:]
    private var lastStream: [String: AinkradLogStream] = [:]
    private var parsers: [String: AinkradANSIParser] = [:]
    public private(set) var droppedLines = 0

    public init(capacity: Int = 5_000) {
        self.capacity = max(1, capacity)
        lines.reserveCapacity(min(self.capacity, 1_024))
    }

    public var all: [AinkradLogLine] { lines }
    public var count: Int { lines.count }

    /// Appends raw output bytes. A multi-byte UTF-8 character split across two
    /// reads is held back and rejoined, not decoded as two replacement characters.
    public mutating func append(_ data: Data, stream: AinkradLogStream = .stdout, source: String? = nil) {
        let key = source ?? ""
        let bytes = (byteCarry[key] ?? Data()) + data
        let tail = Self.incompleteUTF8Tail(of: bytes)
        byteCarry[key] = tail > 0 ? Data(bytes.suffix(tail)) : nil
        append(String(decoding: Data(bytes.prefix(bytes.count - tail)), as: UTF8.self), stream: stream, source: source)
    }

    /// Appends decoded output text, splitting it into lines.
    ///
    /// `source` keys the carry and the colour state, so two sources interleaving
    /// on one pane cannot inherit each other's half-line or colour.
    public mutating func append(_ text: String, stream: AinkradLogStream = .stdout, source: String? = nil) {
        let key = source ?? ""
        lastStream[key] = stream
        // **CRLF is normalised after joining the carry, before any splitting.**
        // Swift treats "\r\n" as a single grapheme cluster, so
        // `firstIndex(of: "\n")` does not find it; and a "\r" ending one read
        // with a "\n" starting the next only becomes "\r\n" once joined. Code
        // that reasons about line endings must work on normalised text or on
        // scalars, never on `Character`.
        var pending = ((carry[key] ?? "") + text).replacingOccurrences(of: "\r\n", with: "\n")
        var completed: [String] = []
        while let newline = pending.firstIndex(of: "\n") {
            let line = String(pending[pending.startIndex..<newline])
            // A bare CR is a progress bar overwriting its own line. Keeping only
            // the text after the last one is what a terminal shows, and stops
            // one download turning into a single 200 KB line.
            completed.append(line.contains("\r") ? String(line.split(separator: "\r").last ?? "") : line)
            pending = String(pending[pending.index(after: newline)...])
        }
        if pending.count > Self.maximumLineLength {
            completed.append(String(pending.prefix(Self.maximumLineLength)))
            pending = ""
        }
        carry[key] = pending

        var parser = parsers[key] ?? AinkradANSIParser()
        for line in completed {
            let runs = parser.parse(line)
            push(AinkradLogLine(id: nextID, stream: stream, source: source,
                                runs: runs.isEmpty ? [AinkradStyledRun(colorSlot: nil, text: "")] : runs))
            nextID += 1
        }
        parsers[key] = parser
    }

    /// Flushes any partial trailing line, for when a stream ends.
    public mutating func flush() {
        for (key, bytes) in byteCarry where !bytes.isEmpty {
            carry[key, default: ""] += String(decoding: bytes, as: UTF8.self)
        }
        byteCarry = [:]
        for (key, pending) in carry where !pending.isEmpty {
            var parser = parsers[key] ?? AinkradANSIParser()
            push(AinkradLogLine(id: nextID, stream: lastStream[key] ?? .stdout,
                                source: key.isEmpty ? nil : key, runs: parser.parse(pending)))
            nextID += 1
            parsers[key] = parser
        }
        carry = [:]
    }

    public mutating func clear() {
        lines.removeAll(keepingCapacity: true)
        carry = [:]
        byteCarry = [:]
        lastStream = [:]
        parsers = [:]
        droppedLines = 0
    }

    /// Case-insensitive substring filter over plain text, so colour codes never match.
    public func filtered(_ query: String) -> [AinkradLogLine] {
        guard !query.isEmpty else { return lines }
        let needle = query.lowercased()
        return lines.filter { $0.plainText.lowercased().contains(needle) }
    }

    private mutating func push(_ line: AinkradLogLine) {
        lines.append(line)
        guard lines.count > capacity else { return }
        let excess = lines.count - capacity
        lines.removeFirst(excess)
        droppedLines += excess
    }

    /// How many trailing bytes of `data` begin a UTF-8 character that has not
    /// finished arriving — 0 to 3.
    static func incompleteUTF8Tail(of data: Data) -> Int {
        let bytes = [UInt8](data.suffix(3))
        guard !bytes.isEmpty else { return 0 }
        for back in 1...bytes.count {
            let byte = bytes[bytes.count - back]
            if byte & 0b1100_0000 == 0b1000_0000 { continue }   // a continuation byte
            let needed = byte >= 0b1111_0000 ? 4 : byte >= 0b1110_0000 ? 3 : byte >= 0b1100_0000 ? 2 : 1
            return needed > back ? back : 0
        }
        return 0
    }
}
