import AinkradAppKitContract
import SwiftUI

/// A GFM pipe table. Cells hold raw inline markdown, resolved by the view.
public struct AinkradMarkdownTable: Equatable, Sendable {
    /// A column's alignment from its separator cell: `---` none, `:--` leading, `:-:` center, `--:` trailing.
    public enum Alignment: Equatable, Sendable { case none, leading, center, trailing }

    public let header: [String]
    public let alignments: [Alignment]
    /// Body rows, each padded or cut to the header's width.
    public let rows: [[String]]

    public init(header: [String], alignments: [Alignment], rows: [[String]]) {
        self.header = header
        self.alignments = alignments
        self.rows = rows
    }

    /// A column whose body cells are all numbers (`96 + 14`, `$0.42`, `12%`) reads right-aligned in mono.
    public func isNumeric(column: Int) -> Bool {
        let cells = rows.map { $0[column].trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return !cells.isEmpty
            && cells.allSatisfy { cell in
                cell.contains(where: \.isNumber) && cell.allSatisfy { $0.isNumber || " +-−.,%$€£×x/:".contains($0) }
            }
    }

    // MARK: - Parsing

    /// `line` as a header row when `separator` is a matching `---` row; no rows yet.
    static func header(_ line: String, separator: String) -> AinkradMarkdownTable? {
        guard let header = row(line), let marks = row(separator), marks.count == header.count else { return nil }
        var alignments: [Alignment] = []
        for mark in marks {
            let m = mark.trimmingCharacters(in: .whitespaces)
            let dashes = m.drop { $0 == ":" }.reversed().drop { $0 == ":" }
            guard !dashes.isEmpty, dashes.allSatisfy({ $0 == "-" }) else { return nil }
            switch (m.hasPrefix(":"), m.hasSuffix(":")) {
            case (true, true): alignments.append(.center)
            case (true, false): alignments.append(.leading)
            case (false, true): alignments.append(.trailing)
            case (false, false): alignments.append(.none)
            }
        }
        return AinkradMarkdownTable(header: header, alignments: alignments, rows: [])
    }

    /// The cells of a `| a | b |` line (outer pipes optional, `\|` stays a pipe); nil when it holds no pipe.
    static func row(_ line: String) -> [String]? {
        var text = line.trimmingCharacters(in: .whitespaces)
        guard text.contains("|") else { return nil }
        if text.hasPrefix("|") { text.removeFirst() }
        if text.hasSuffix("|"), !text.hasSuffix("\\|") { text.removeLast() }
        var cells: [String] = []
        var cell = ""
        var escaped = false
        for c in text {
            if escaped {
                cell.append(c == "|" ? "|" : "\\\(c)")
                escaped = false
            } else if c == "\\" {
                escaped = true
            } else if c == "|" {
                cells.append(cell.trimmingCharacters(in: .whitespaces))
                cell = ""
            } else {
                cell.append(c)
            }
        }
        if escaped { cell.append("\\") }
        cells.append(cell.trimmingCharacters(in: .whitespaces))
        return cells
    }

    func with(rows: [[String]]) -> AinkradMarkdownTable {
        let width = header.count
        let fitted = rows.map { Array(($0 + Array(repeating: "", count: max(0, width - $0.count))).prefix(width)) }
        return AinkradMarkdownTable(header: header, alignments: alignments, rows: fitted)
    }
}

/// One surface (the code block's fill and shape), no grid lines: a label-cased header row, faintly striped body
/// rows with a hover tint, number columns right-aligned in mono. Wide tables scroll sideways inside the card.
struct AinkradMarkdownTableView: View {
    let table: AinkradMarkdownTable
    let typography: AinkradTypography
    let inline: (String) -> Text

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hoveredRow: Int?
    /// The card's width: the grid fills at least this, and scrolls sideways past it.
    @State private var width: CGFloat = 0

    var body: some View {
        let block = skin.components.codeBlock
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(table.header.indices, id: \.self) { column in
                        Text(skin.labelCased(table.header[column]))
                            .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typography))
                            .tracking(block.headerFont.tracking ?? 0)
                            .foregroundStyle(skin.color(block.headerColor))
                            .modifier(Cell(alignment: alignment(column), top: true))
                    }
                }
                ForEach(table.rows.indices, id: \.self) { row in
                    GridRow {
                        ForEach(table.header.indices, id: \.self) { column in
                            inline(table.rows[row][column])
                                .font(
                                    table.isNumeric(column: column)
                                        ? AinkradFontResolver.font(size: 12, mono: true, typography: typography)
                                        : AinkradFontResolver.font(size: 12.5, typography: typography)
                                )
                                .foregroundStyle(theme.foreground.opacity(skin.opacity.o90))
                                .modifier(Cell(alignment: alignment(column), top: false))
                                .background(stripe(row))
                        }
                    }
                    .onHover { hoveredRow = $0 ? row : (hoveredRow == row ? nil : hoveredRow) }
                }
            }
            .padding(.bottom, skin.size.s4)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minWidth: width, alignment: .leading)
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hoveredRow)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .background(AinkradSkinShape(token: block.shape).fill(skin.color(block.fill)))
        .clipShape(AinkradSkinShape(token: block.shape))
    }

    private func alignment(_ column: Int) -> Alignment {
        switch table.alignments[column] {
        case .center: .center
        case .trailing: .trailing
        case .leading: .leading
        case .none: table.isNumeric(column: column) ? .trailing : .leading
        }
    }

    private func stripe(_ row: Int) -> Color {
        if hoveredRow == row { return theme.accentPrimary.opacity(skin.opacity.o12) }
        return row.isMultiple(of: 2) ? theme.foreground.opacity(skin.opacity.o03) : .clear
    }

    private struct Cell: ViewModifier {
        let alignment: Alignment
        let top: Bool
        @Environment(\.ainkradSkin) private var skin

        func body(content: Content) -> some View {
            content
                .textSelection(.enabled)
                .padding(.horizontal, skin.size.s12)
                .padding(.top, top ? skin.size.s8 : skin.size.s5)
                .padding(.bottom, top ? skin.size.s5 : skin.size.s5)
                // Fill the row's height too, so a shorter mono cell doesn't break the stripe.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        }
    }
}
