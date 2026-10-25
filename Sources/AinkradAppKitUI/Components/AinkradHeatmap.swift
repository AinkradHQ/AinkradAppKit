import SwiftUI

/// Rows by columns of cells whose fill strength is the value (a weekday by hour activity map), with row and column
/// labels; the cells fade in one after another (at once under Reduce Motion). `cellHelp` words each cell's tooltip.
public struct AinkradHeatmap: View {
    private let rows: [String]
    private let columns: [String]
    private let values: [[Int]]
    private let tint: Color?
    private let cellHelp: ((_ row: String, _ column: String, _ value: Int) -> String)?
    @State private var shown = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// - Parameter values: `values[row][column]`; a missing cell reads as zero.
    public init(
        rows: [String], columns: [String], values: [[Int]], tint: Color? = nil,
        cellHelp: ((_ row: String, _ column: String, _ value: Int) -> String)? = nil
    ) {
        self.rows = rows
        self.columns = columns
        self.values = values
        self.tint = tint
        self.cellHelp = cellHelp
    }

    public var body: some View {
        let peak = max(1, values.flatMap { $0 }.max() ?? 1)
        let color = tint ?? skin.color(skin.palette.accentSecondary)
        Grid(horizontalSpacing: skin.size.s4, verticalSpacing: skin.size.s4) {
            GridRow {
                Color.clear.frame(width: skin.size.s30, height: skin.size.s1)
                ForEach(columns, id: \.self) { Text($0).frame(maxWidth: .infinity) }
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { r, row in
                GridRow {
                    Text(row).frame(width: skin.size.s30, alignment: .leading)
                    ForEach(Array(columns.indices), id: \.self) { c in
                        let value = cell(r, c)
                        RoundedRectangle(cornerRadius: skin.size.s4)
                            .fill(color.opacity(skin.opacity.o07 + Double(value) / Double(peak) * skin.opacity.o75))
                            .frame(maxWidth: .infinity, minHeight: skin.size.s16, maxHeight: skin.size.s16)
                            .opacity(shown || reduceMotion ? 1 : 0)
                            .animation(
                                skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 0.4))
                                    .delay(Double(r * columns.count + c) * 0.018), value: shown
                            )
                            .help(cellHelp?(row, columns[c], value) ?? "")
                    }
                }
            }
        }
        .kitFont("t9_5", mono: true)
        .foregroundStyle(skin.color(skin.text.faint))
        .onAppear { shown = true }
    }

    private func cell(_ row: Int, _ column: Int) -> Int {
        guard values.indices.contains(row), values[row].indices.contains(column) else { return 0 }
        return values[row][column]
    }
}
