import Foundation

public struct AinkradDiffLine: Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case context, insertion, deletion }
    public let kind: Kind
    public let oldNumber: Int?  // 1-based line number in the original, nil for insertions
    public let newNumber: Int?  // 1-based line number in the updated file, nil for deletions
    public let text: String

    public init(kind: Kind, oldNumber: Int?, newNumber: Int?, text: String) {
        self.kind = kind
        self.oldNumber = oldNumber
        self.newNumber = newNumber
        self.text = text
    }
}

public struct AinkradDiffHunk: Equatable, Sendable, Identifiable {
    public let id: Int  // stable index within the AinkradFileDiff (0-based)
    public let oldStart: Int  // 1-based first original line the hunk covers (0 if pure insertion at top)
    public let oldCount: Int
    public let newStart: Int
    public let newCount: Int
    public let lines: [AinkradDiffLine]

    public init(id: Int, oldStart: Int, oldCount: Int, newStart: Int, newCount: Int, lines: [AinkradDiffLine]) {
        self.id = id
        self.oldStart = oldStart
        self.oldCount = oldCount
        self.newStart = newStart
        self.newCount = newCount
        self.lines = lines
    }

    public var oldLines: [String] { lines.filter { $0.kind != .insertion }.map(\.text) }
    public var newLines: [String] { lines.filter { $0.kind != .deletion }.map(\.text) }
}

public struct AinkradFileDiff: Equatable, Sendable {
    public let path: String
    public let original: String
    public let hunks: [AinkradDiffHunk]

    public init(path: String, original: String, hunks: [AinkradDiffHunk]) {
        self.path = path
        self.original = original
        self.hunks = hunks
    }
}

/// Line-level diff via a classic LCS table, grouped into hunks with `context`
/// unchanged lines of padding. Sufficient for edit-approval review — not a
/// minimal-edit myers diff, but stable and correct for reconstruction.
public enum AinkradDiffEngine {
    public static func compute(old: String, new: String, path: String, context: Int = 3) -> AinkradFileDiff {
        let a = old.isEmpty ? [] : old.components(separatedBy: "\n")
        let b = new.isEmpty ? [] : new.components(separatedBy: "\n")

        // LCS length table.
        var lcs = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        if a.count > 0 && b.count > 0 {
            for i in stride(from: a.count - 1, through: 0, by: -1) {
                for j in stride(from: b.count - 1, through: 0, by: -1) {
                    lcs[i][j] = a[i] == b[j] ? lcs[i + 1][j + 1] + 1 : max(lcs[i + 1][j], lcs[i][j + 1])
                }
            }
        }
        // Backtrack into a flat op list.
        enum Op {
            case ctx(String, Int, Int)
            case ins(String, Int)
            case del(String, Int)
        }
        var ops: [Op] = []
        var i = 0
        var j = 0
        while i < a.count && j < b.count {
            if a[i] == b[j] {
                ops.append(.ctx(a[i], i + 1, j + 1))
                i += 1
                j += 1
            } else if lcs[i + 1][j] >= lcs[i][j + 1] {
                ops.append(.del(a[i], i + 1))
                i += 1
            } else {
                ops.append(.ins(b[j], j + 1))
                j += 1
            }
        }
        while i < a.count {
            ops.append(.del(a[i], i + 1))
            i += 1
        }
        while j < b.count {
            ops.append(.ins(b[j], j + 1))
            j += 1
        }

        // Indices of changed ops, expanded by `context`, coalesced into ranges.
        let changed = ops.enumerated().filter { if case .ctx = $0.element { return false } else { return true } }.map(
            \.offset)
        guard !changed.isEmpty else { return AinkradFileDiff(path: path, original: old, hunks: []) }
        var ranges: [(Int, Int)] = []
        for idx in changed {
            let lo = max(0, idx - context)
            let hi = min(ops.count - 1, idx + context)
            if var last = ranges.last, lo <= last.1 + 1 {
                last.1 = max(last.1, hi)
                ranges[ranges.count - 1] = last
            } else {
                ranges.append((lo, hi))
            }
        }

        var hunks: [AinkradDiffHunk] = []
        for (hIndex, range) in ranges.enumerated() {
            var dlines: [AinkradDiffLine] = []
            var oStart = 0
            var nStart = 0
            var oCount = 0
            var nCount = 0
            for k in range.0...range.1 {
                switch ops[k] {
                case .ctx(let t, let on, let nn):
                    dlines.append(AinkradDiffLine(kind: .context, oldNumber: on, newNumber: nn, text: t))
                    if oStart == 0 { oStart = on }
                    if nStart == 0 { nStart = nn }
                    oCount += 1
                    nCount += 1
                case .del(let t, let on):
                    dlines.append(AinkradDiffLine(kind: .deletion, oldNumber: on, newNumber: nil, text: t))
                    if oStart == 0 { oStart = on }
                    oCount += 1
                case .ins(let t, let nn):
                    dlines.append(AinkradDiffLine(kind: .insertion, oldNumber: nil, newNumber: nn, text: t))
                    if nStart == 0 { nStart = nn }
                    nCount += 1
                }
            }
            hunks.append(
                AinkradDiffHunk(
                    id: hIndex, oldStart: oStart, oldCount: oCount,
                    newStart: nStart, newCount: nCount, lines: dlines))
        }
        return AinkradFileDiff(path: path, original: old, hunks: hunks)
    }
}
