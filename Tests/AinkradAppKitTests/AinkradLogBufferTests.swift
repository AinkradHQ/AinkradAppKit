import Foundation
import Testing
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

// Ported from Thrall's ThrallLogBufferTests when the buffer moved into the kit;
// the last four tests are new and cover the fixes made on the way.
@Suite("AinkradLogBuffer")
struct AinkradLogBufferTests {
    @Test("text splits into lines")
    func splitsLines() {
        var buffer = AinkradLogBuffer()
        buffer.append("one\ntwo\nthree\n")
        #expect(buffer.all.map(\.plainText) == ["one", "two", "three"])
    }

    /// A read boundary lands mid-line constantly, so the carry is the normal path.
    @Test("a line split across reads is joined")
    func joinsAcrossReads() {
        var buffer = AinkradLogBuffer()
        buffer.append("par")
        buffer.append("tial\n")
        #expect(buffer.all.map(\.plainText) == ["partial"])
    }

    /// Swift treats "\r\n" as one grapheme, so a naive `firstIndex(of: "\n")`
    /// misses it and a CRLF log arrives as one unbroken line.
    @Test("CRLF endings lose the carriage return")
    func crlf() {
        var buffer = AinkradLogBuffer()
        buffer.append("line one\r\nline two\r\n")
        #expect(buffer.all.map(\.plainText) == ["line one", "line two"])
    }

    @Test("a bare CR keeps only the last segment, like a terminal")
    func bareCarriageReturn() {
        var buffer = AinkradLogBuffer()
        buffer.append("10%\r50%\r100% done\n")
        #expect(buffer.all.map(\.plainText) == ["100% done"])
    }

    @Test("the buffer is capped and drops the oldest")
    func capped() {
        var buffer = AinkradLogBuffer(capacity: 100)
        for index in 0..<1_000 { buffer.append("line \(index)\n") }
        #expect(buffer.count == 100)
        #expect(buffer.all.first?.plainText == "line 900")
        #expect(buffer.droppedLines == 900)
    }

    @Test("an absurdly long line is truncated rather than held whole")
    func longLineTruncated() {
        var buffer = AinkradLogBuffer()
        buffer.append(String(repeating: "x", count: 40_000))
        #expect(buffer.count == 1)
        #expect(buffer.all[0].plainText.count <= 8 * 1024)
    }

    @Test("carry and colour state are per source")
    func perSourceState() {
        var buffer = AinkradLogBuffer()
        buffer.append("\u{1B}[31mfrom-a-par", source: "a")
        buffer.append("from-b\n", source: "b")
        buffer.append("t\n", source: "a")
        let bySource = Dictionary(grouping: buffer.all, by: { $0.source ?? "" })
        #expect(bySource["b"]?.map(\.plainText) == ["from-b"])
        #expect(bySource["a"]?.map(\.plainText) == ["from-a-part"])
        #expect(bySource["b"]?.first?.runs.first?.colorSlot == nil)
        #expect(bySource["a"]?.first?.runs.first?.colorSlot == 1)
    }

    @Test("stderr lines keep their stream, so a view can dim them")
    func streamPreserved() {
        var buffer = AinkradLogBuffer()
        buffer.append("bad\n", stream: .stderr)
        #expect(buffer.all.first?.stream == .stderr)
    }

    @Test("flush emits a trailing partial line")
    func flush() {
        var buffer = AinkradLogBuffer()
        buffer.append("no newline")
        #expect(buffer.count == 0)
        buffer.flush()
        #expect(buffer.all.map(\.plainText) == ["no newline"])
    }

    @Test("the filter is case-insensitive over plain text, ignoring colour")
    func filtering() {
        var buffer = AinkradLogBuffer()
        buffer.append("\u{1B}[31mConnection REFUSED\u{1B}[0m\nall good\n")
        #expect(buffer.filtered("refused").count == 1)
        #expect(buffer.filtered("good").count == 1)
        #expect(buffer.filtered("").count == 2)
        #expect(buffer.filtered("31m").isEmpty)
    }

    @Test("ids are unique so a view cannot drop lines")
    func uniqueIDs() {
        var buffer = AinkradLogBuffer(capacity: 50)
        for index in 0..<200 { buffer.append("l\(index)\n") }
        #expect(Set(buffer.all.map(\.id)).count == buffer.count)
    }

    @Test("a 24-source burst stays bounded and intact")
    func twentyFourSourceBurst() {
        var buffer = AinkradLogBuffer(capacity: 5_000)
        for tick in 0..<500 { for source in 1...24 { buffer.append("worker-\(source) tick \(tick)\n", source: "worker-\(source)") } }
        #expect(buffer.count == 5_000)
        #expect(buffer.droppedLines == 12_000 - 5_000)
        #expect(buffer.all.allSatisfy { $0.plainText.contains("tick") })
    }

    @Test("clear resets everything, including the dropped count")
    func clear() {
        var buffer = AinkradLogBuffer(capacity: 10)
        for index in 0..<50 { buffer.append("l\(index)\n") }
        buffer.clear()
        #expect(buffer.count == 0)
        #expect(buffer.droppedLines == 0)
    }

    // New: fixes made on the way into the kit.

    /// Decoding each read on its own turns a character whose bytes straddle a
    /// boundary into two replacement characters. The byte path holds them.
    @Test("a UTF-8 character split across two reads is rejoined")
    func utf8SplitAcrossReads() {
        let bytes = Data("naïve café\n".utf8)   // "ï" is bytes 2–3
        var buffer = AinkradLogBuffer()
        buffer.append(bytes.prefix(3))
        buffer.append(bytes.dropFirst(3))
        #expect(buffer.all.map(\.plainText) == ["naïve café"])
    }

    /// A "\r" ending one read and a "\n" starting the next only become a line
    /// ending once joined — so normalising must happen after the join.
    @Test("a CRLF split across reads still ends the line")
    func crlfSplitAcrossReads() {
        var buffer = AinkradLogBuffer()
        buffer.append("one\r")
        buffer.append("\ntwo\n")
        #expect(buffer.all.map(\.plainText) == ["one", "two"])
    }

    @Test("flush keeps the stream of the partial line")
    func flushKeepsStream() {
        var buffer = AinkradLogBuffer()
        buffer.append("oops", stream: .stderr)
        buffer.flush()
        #expect(buffer.all.first?.stream == .stderr)
    }

    @Test("the incomplete UTF-8 tail is measured correctly", arguments: [
        ([0x61], 0), ([0xE2], 1), ([0xE2, 0x82], 2), ([0xE2, 0x82, 0xAC], 0),
        ([0xC3], 1), ([0xC3, 0xAF], 0), ([0xF0, 0x9F, 0x98], 3), ([], 0),
    ] as [([UInt8], Int)])
    func incompleteTail(bytes: [UInt8], expected: Int) {
        #expect(AinkradLogBuffer.incompleteUTF8Tail(of: Data(bytes)) == expected)
    }
}
