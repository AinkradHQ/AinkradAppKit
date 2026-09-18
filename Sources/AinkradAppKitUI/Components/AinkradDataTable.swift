import SwiftUI
import AppKit
import AinkradAppKitContract

/// A single column of an `AinkradDataTable`: text cells, or — through
/// `accessory(id:title:alignment:content:)` — views such as a per-row button,
/// a badge or a spinner. `id` identifies the column for sort tracking
/// (`AinkradTableSort.columnID`) independent of its display `title`.
public struct AinkradTableColumn<Row: Identifiable> {
    public let id: String
    public let title: String
    public let alignment: HorizontalAlignment
    /// The cell's text, and the value the column sorts by. Empty for an
    /// accessory column, which does not sort.
    public let cell: (Row) -> String
    /// Set only for an accessory column. Internal, so the public surface grows
    /// by one factory and nothing else.
    let accessory: (@MainActor (Row) -> AnyView)?

    public init(id: String, title: String, alignment: HorizontalAlignment = .leading, cell: @escaping (Row) -> String) {
        self.id = id
        self.title = title
        self.alignment = alignment
        self.cell = cell
        self.accessory = nil
    }

    private init(id: String, title: String, alignment: HorizontalAlignment,
                 accessory: @escaping @MainActor (Row) -> AnyView) {
        self.id = id
        self.title = title
        self.alignment = alignment
        self.cell = { _ in "" }
        self.accessory = accessory
    }

    /// A column whose cells are views — per-row verbs, badges, spinners —
    /// rather than text. It has no sort value, so its header does not sort.
    ///
    /// A static factory, not a second type: the table takes one
    /// `[AinkradTableColumn<Row>]`, and a separate accessory type could not
    /// share that array without type erasure at every call site.
    public static func accessory<Content: View>(
        id: String,
        title: String = "",
        alignment: HorizontalAlignment = .trailing,
        @ViewBuilder content: @escaping @MainActor (Row) -> Content
    ) -> AinkradTableColumn<Row> {
        AinkradTableColumn(id: id, title: title, alignment: alignment,
                           accessory: { @MainActor row in AnyView(content(row)) })
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
/// in `columns`), or an accessory column's, returns `rows` unchanged. `Array.sorted(by:)` is a stable
/// sort, so equal cell values preserve their original relative order. Pure —
/// unit-testable without a view.
public func sortedRows<Row: Identifiable>(
    _ rows: [Row],
    by columns: [AinkradTableColumn<Row>],
    column columnID: String,
    ascending: Bool
) -> [Row] {
    guard let column = columns.first(where: { $0.id == columnID }), column.accessory == nil else { return rows }
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

/// How a click changes a table's selection: a plain click, a ⌘-click that
/// toggles, or a ⇧-click that extends a range.
enum AinkradSelectionGesture { case plain, toggle, extend }

/// The selection — and the anchor a later ⇧-click extends from — after
/// `gesture` on `clicked`, given the IDs in the order rows are *shown*. A range
/// is taken from that order, so it respects the current sort. A ⇧-click with
/// no anchor, or one no longer shown, acts as a plain click. Pure —
/// unit-testable without a view.
func nextSelection<ID: Hashable>(
    current: Set<ID>, anchor: ID?, clicked: ID, in orderedIDs: [ID], gesture: AinkradSelectionGesture
) -> (selection: Set<ID>, anchor: ID?) {
    switch gesture {
    case .plain:
        return ([clicked], clicked)
    case .toggle:
        return (current.symmetricDifference([clicked]), clicked)
    case .extend:
        guard let anchor, let from = orderedIDs.firstIndex(of: anchor),
              let to = orderedIDs.firstIndex(of: clicked) else { return ([clicked], clicked) }
        return (Set(orderedIDs[min(from, to)...max(from, to)]), anchor)
    }
}

/// Cardinal HUD data table — chamfer header row (uppercase/tracked, optional
/// click-to-sort), zebra-free rows (no divider lines; separation via spacing
/// + a subtle hover fill). Cells are text, or views through an accessory column;
/// rows are optionally selectable.
public struct AinkradDataTable<Row: Identifiable>: View {
    private let rows: [Row]
    private let columns: [AinkradTableColumn<Row>]
    private let sort: Binding<AinkradTableSort?>?
    private let selection: Binding<Set<Row.ID>>?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hoveredRowID: Row.ID?
    /// Where a ⇧-click range starts. View state, not the caller's: the caller
    /// owns which rows are selected, not how the user got there.
    @State private var selectionAnchor: Row.ID?

    public init(rows: [Row], columns: [AinkradTableColumn<Row>], sort: Binding<AinkradTableSort?>? = nil) {
        self.rows = rows
        self.columns = columns
        self.sort = sort
        self.selection = nil
    }

    /// A selectable table: a click selects a row, ⌘-click toggles one, and
    /// ⇧-click selects the range from the last click, in the order rows are
    /// shown. Selection is keyed by row ID, so it survives a re-sort.
    ///
    /// A second initializer, not a defaulted parameter on the first: adding a
    /// parameter changes the initializer's mangled name, and a plugin built
    /// against the old one would then fail to load.
    public init(rows: [Row], columns: [AinkradTableColumn<Row>], sort: Binding<AinkradTableSort?>? = nil,
                selection: Binding<Set<Row.ID>>) {
        self.rows = rows
        self.columns = columns
        self.sort = sort
        self.selection = selection
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
            // An accessory column has no sort value, so its header click does
            // nothing — it is not `.disabled`, which would grey out that one
            // header among its neighbours and read as a disabled column.
            guard let sort, column.accessory == nil else { return }
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
                if let accessory = column.accessory {
                    accessory(row)
                        .frame(maxWidth: .infinity, alignment: alignmentFor(column.alignment))
                } else {
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
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 4).fill(rowFill(row.id)))
        // Selection reads like `AinkradListRow`'s — an accent fill and a lit
        // leading bar — so a selected table row and a selected list row match.
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(theme.accentSecondary)
                .frame(width: isSelected(row.id) ? 2 : 0)
                .shadow(color: theme.accentSecondary.opacity(0.6), radius: 3)
        }
        .contentShape(Rectangle())
        .onTapGesture { click(row.id) }
        .onHover { isHovering in hoveredRowID = isHovering ? row.id : (hoveredRowID == row.id ? nil : hoveredRowID) }
        .accessibilityAddTraits(isSelected(row.id) ? .isSelected : [])
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: hoveredRowID)
    }

    private func isSelected(_ id: Row.ID) -> Bool { selection?.wrappedValue.contains(id) ?? false }

    private func rowFill(_ id: Row.ID) -> Color {
        if isSelected(id) { return theme.accentPrimary.opacity(0.16) }
        if hoveredRowID == id { return theme.surfaceElevated.opacity(0.4) }
        return .clear
    }

    /// A no-op without a selection binding, so a plain table ignores clicks.
    private func click(_ id: Row.ID) {
        guard let selection else { return }
        let flags = NSEvent.modifierFlags
        let gesture: AinkradSelectionGesture = flags.contains(.command) ? .toggle
            : flags.contains(.shift) ? .extend : .plain
        let next = nextSelection(current: selection.wrappedValue, anchor: selectionAnchor, clicked: id,
                                 in: displayedRows.map(\.id), gesture: gesture)
        selection.wrappedValue = next.selection
        selectionAnchor = next.anchor
    }

    private func alignmentFor(_ alignment: HorizontalAlignment) -> Alignment {
        switch alignment {
        case .trailing: return .trailing
        case .center: return .center
        default: return .leading
        }
    }
}
