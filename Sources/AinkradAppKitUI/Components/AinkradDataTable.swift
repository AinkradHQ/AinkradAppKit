import SwiftUI
import AinkradAppKitContract

/// A single column of an `AinkradDataTable` — v1 supports text cells only.
/// `id` identifies the column for sort tracking (`AinkradTableSort.columnID`)
/// independent of its display `title`.
public struct AinkradTableColumn<Row: Identifiable> {
    public let id: String
    public let title: String
    public let alignment: HorizontalAlignment
    public let cell: (Row) -> String

    public init(id: String, title: String, alignment: HorizontalAlignment = .leading, cell: @escaping (Row) -> String) {
        self.id = id
        self.title = title
        self.alignment = alignment
        self.cell = cell
    }
}

/// Which column an `AinkradDataTable` is currently sorted by, and direction.
public struct AinkradTableSort: Equatable, Sendable {
    public var columnID: String
    public var ascending: Bool
    public init(columnID: String, ascending: Bool) {
        self.columnID = columnID
        self.ascending = ascending
    }
}

/// `rows` sorted by the text value of the column matching `columnID`
/// (via `localizedStandardCompare`, so numeric-looking text sorts naturally),
/// ascending or descending per `ascending`. An unknown `columnID` (not present
/// in `columns`) returns `rows` unchanged. `Array.sorted(by:)` is a stable
/// sort, so equal cell values preserve their original relative order. Pure —
/// unit-testable without a view.
public func sortedRows<Row: Identifiable>(
    _ rows: [Row],
    by columns: [AinkradTableColumn<Row>],
    column columnID: String,
    ascending: Bool
) -> [Row] {
    guard let column = columns.first(where: { $0.id == columnID }) else { return rows }
    return rows.sorted { lhs, rhs in
        let comparison = column.cell(lhs).localizedStandardCompare(column.cell(rhs))
        return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
    }
}

/// The sort state that should result from clicking `column`'s header, given
/// the table's `current` sort. Clicking a column that isn't already the
/// active sort starts it ascending; clicking the already-active column
/// toggles its direction. Pure — unit-testable without a view.
public func nextSort(current: AinkradTableSort?, column: String) -> AinkradTableSort {
    guard let current, current.columnID == column else {
        return AinkradTableSort(columnID: column, ascending: true)
    }
    return AinkradTableSort(columnID: column, ascending: !current.ascending)
}

/// Cardinal HUD data table — chamfer header row (uppercase/tracked, optional
/// click-to-sort), zebra-free rows (no divider lines; separation via spacing
/// + a subtle hover fill). v1 supports text cells only.
public struct AinkradDataTable<Row: Identifiable>: View {
    private let rows: [Row]
    private let columns: [AinkradTableColumn<Row>]
    private let sort: Binding<AinkradTableSort?>?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hoveredRowID: Row.ID?

    public init(rows: [Row], columns: [AinkradTableColumn<Row>], sort: Binding<AinkradTableSort?>? = nil) {
        self.rows = rows
        self.columns = columns
        self.sort = sort
    }

    private var displayedRows: [Row] {
        guard let current = sort?.wrappedValue else { return rows }
        return sortedRows(rows, by: columns, column: current.columnID, ascending: current.ascending)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.xs) {
            header
            // Lazy, so a table inside a `ScrollView` builds only the rows on
            // screen. The eager `VStack` built every row: Thrall had to fold
            // 135 volumes into disclosure groups just to keep its storage
            // area openable.
            LazyVStack(spacing: 2) {
                ForEach(displayedRows) { row in rowView(row) }
            }
        }
    }

    private var header: some View {
        HStack(spacing: AinkradSpacing.md) {
            ForEach(columns, id: \.id) { column in
                headerCell(column)
            }
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 6, corners: .topLeft.union(.topRight)).fill(theme.surfaceElevated.opacity(0.7)))
    }

    private func headerCell(_ column: AinkradTableColumn<Row>) -> some View {
        Button {
            guard let sort else { return }
            sort.wrappedValue = nextSort(current: sort.wrappedValue, column: column.id)
        } label: {
            HStack(spacing: 3) {
                Text(column.title.uppercased())
                    .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                    .tracking(0.8)
                if sort?.wrappedValue?.columnID == column.id {
                    Image(systemName: sort?.wrappedValue?.ascending == true ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
            }
            .foregroundStyle(theme.foreground.opacity(0.75))
            .frame(maxWidth: .infinity, alignment: alignmentFor(column.alignment))
        }
        .buttonStyle(.plain)
        .disabled(sort == nil)
    }

    private func rowView(_ row: Row) -> some View {
        HStack(spacing: AinkradSpacing.md) {
            ForEach(columns, id: \.id) { column in
                Text(column.cell(row))
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.9))
                    // One line, truncated in the middle. A wrapping cell makes
                    // its row as tall as its longest value — image names broke
                    // mid-word onto three lines — and middle truncation keeps
                    // both ends of an identifier, such as the tag in `name:latest`.
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: alignmentFor(column.alignment))
            }
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 4).fill(hoveredRowID == row.id ? theme.surfaceElevated.opacity(0.4) : .clear))
        .contentShape(Rectangle())
        .onHover { isHovering in hoveredRowID = isHovering ? row.id : (hoveredRowID == row.id ? nil : hoveredRowID) }
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: hoveredRowID)
    }

    private func alignmentFor(_ alignment: HorizontalAlignment) -> Alignment {
        switch alignment {
        case .trailing: return .trailing
        case .center: return .center
        default: return .leading
        }
    }
}
