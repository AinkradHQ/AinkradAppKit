import AinkradAppKitContract
import SwiftUI

/// One row's presentation in a grouped select — an option value plus its
/// display title, optional trailing metadata (e.g. "128k · cloud"), optional
/// leading SF Symbol, optional leading color swatch, and whether the row is
/// selectable at all.
public struct AinkradGroupedRow<T: Hashable>: Hashable {
    public let value: T
    public let title: String
    public let detail: String?
    public let icon: String?
    public let swatch: Color?
    public let isEnabled: Bool

    public init(
        value: T, title: String, detail: String? = nil, icon: String? = nil,
        swatch: Color? = nil, isEnabled: Bool = true
    ) {
        self.value = value
        self.title = title
        self.detail = detail
        self.icon = icon
        self.swatch = swatch
        self.isEnabled = isEnabled
    }
}

/// A section: a non-selectable header + its rows.
public struct AinkradGroupedSection<T: Hashable>: Hashable {
    public let header: String
    public let rows: [AinkradGroupedRow<T>]

    public init(header: String, rows: [AinkradGroupedRow<T>]) {
        self.header = header
        self.rows = rows
    }
}

/// Sections whose rows match `query` (by title, case-insensitive), each trimmed
/// to its matching rows; empty query returns all sections unchanged. Pure —
/// the grouped-select analogue of `comboboxFilter`, unit-testable without
/// SwiftUI.
public func filterGroupedSections<T>(_ sections: [AinkradGroupedSection<T>], query: String) -> [AinkradGroupedSection<
    T
>] {
    let q = query.trimmingCharacters(in: .whitespaces).lowercased()
    guard !q.isEmpty else { return sections }
    return sections.compactMap { section in
        // A header match (e.g. a connection/provider name) keeps the whole
        // section; otherwise keep only rows whose title matches. This lets a
        // grouped select be searched by group name as well as by row.
        if section.header.lowercased().contains(q) { return section }
        let rows = section.rows.filter { $0.title.lowercased().contains(q) }
        return rows.isEmpty ? nil : AinkradGroupedSection(header: section.header, rows: rows)
    }
}

/// All selectable (enabled) row values across sections, in order. Pure — used
/// to drive keyboard highlight/`onSubmit` so disabled rows are never reachable.
public func selectableValues<T>(_ sections: [AinkradGroupedSection<T>]) -> [T] {
    sections.flatMap { $0.rows.filter(\.isEnabled).map(\.value) }
}

/// Fades + scales the panel content in on appear, then holds steady — same
/// "materialize" look as `AinkradSelect`'s panel (duplicated here rather than
/// shared since the original is file-private to `AinkradPickers.swift`).
/// Skips the animation entirely under Reduce Motion.
private struct GroupedPanelMaterialize<Content: View>: View {
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var appeared = false
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.96, anchor: .top)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(AinkradMotion.materialize) { appeared = true }
                }
            }
    }
}

/// Grouped, searchable, no-native-menu select. Sections render a header; rows
/// show optional leading icon/swatch, title, and trailing detail; disabled rows
/// are dimmed and unselectable. Same floating-panel + search contract as
/// `AinkradSelect` — a custom chamfer trigger + a top-level floating panel,
/// never a native `Menu`/`Picker`/`.popover`.
public struct AinkradGroupedSelect<T: Hashable>: View {
    private let sections: [AinkradGroupedSection<T>]
    @Binding private var selection: T
    private let triggerLabel: String
    private let searchPlaceholder: String

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var isOpen = false

    public init(
        sections: [AinkradGroupedSection<T>], selection: Binding<T>,
        triggerLabel: String, searchPlaceholder: String = "Search…"
    ) {
        self.sections = sections
        self._selection = selection
        self.triggerLabel = triggerLabel
        self.searchPlaceholder = searchPlaceholder
    }

    public var body: some View {
        trigger
            .ainkradFloatingPanel(isPresented: $isOpen, autofocusTextField: true, matchAnchorWidth: true) {
                GroupedPanelMaterialize {
                    GroupedSelectPanelView(
                        sections: sections, selection: $selection,
                        placeholder: searchPlaceholder, onClose: close)
                }
            }
    }

    private func open() { isOpen = true }
    private func close() { isOpen = false }

    private var trigger: some View {
        Button {
            isOpen ? close() : open()
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                Text(triggerLabel)
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground)
                Spacer(minLength: AinkradSpacing.sm)
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.accentSecondary.opacity(0.85))
            }
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(
                ChamferShape(cut: 8).strokeBorder(theme.accentPrimary.opacity(isOpen ? 0.75 : 0.3), lineWidth: 1.25)
            )
            .shadow(color: theme.accentPrimary.opacity(isOpen ? 0.4 : 0), radius: isOpen ? 5 : 0)
            .contentShape(ChamferShape(cut: 8))
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: isOpen)
    }
}

/// `AinkradGroupedSelect`'s search field + sectioned option list. `query` and
/// `highlightedIndex` are `@State` owned by this view (not the trigger struct
/// captured into a closure) so every keystroke re-invokes `body` and
/// recomputes `filtered` — same fix `SearchableSelectPanelView` needed for its
/// live filtering. `highlightedIndex` and keyboard nav walk only the flattened
/// SELECTABLE (enabled) rows, via `selectableValues`, so disabled rows are
/// never reachable from the keyboard.
struct GroupedSelectPanelView<T: Hashable>: View {
    let sections: [AinkradGroupedSection<T>]
    @Binding var selection: T
    let placeholder: String
    let onClose: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var query = ""
    @State private var highlightedIndex = 0
    @State private var hoveredValue: T?
    @FocusState private var searchFocused: Bool

    private var filteredSections: [AinkradGroupedSection<T>] { filterGroupedSections(sections, query: query) }
    private var highlightableValues: [T] { selectableValues(filteredSections) }

    /// One flattened, lazily-rendered stream of headers + rows. Flattening (rather
    /// than nesting a VStack of rows per section) keeps rendering cheap even when a
    /// single provider returns hundreds of models — only near-visible items are
    /// realized by the `LazyVStack`, so opening the panel stays snappy.
    private enum PanelItem: Hashable {
        case header(String)
        case row(AinkradGroupedRow<T>)
    }
    private var flatItems: [PanelItem] {
        filteredSections.flatMap { section -> [PanelItem] in
            (section.header.isEmpty ? [] : [.header(section.header)]) + section.rows.map { PanelItem.row($0) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.xs) {
            searchField
            if filteredSections.isEmpty {
                Text("No matches")
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.5))
                    .padding(.horizontal, AinkradSpacing.sm)
                    .padding(.vertical, AinkradSpacing.xs)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(flatItems, id: \.self) { item in
                            switch item {
                            case .header(let header): headerView(header)
                            case .row(let row): optionRow(row)
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(AinkradSpacing.xs)
        .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.97)))
        .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentSecondary.opacity(0.55), lineWidth: 1.25))
        .shadow(color: theme.accentSecondary.opacity(0.35), radius: 10, y: 4)
        .frame(minWidth: 340)
        .onAppear { DispatchQueue.main.async { searchFocused = true } }
        .onChange(of: query) { _, _ in highlightedIndex = 0 }
        .onKeyPress(.upArrow) { move(-1) }
        .onKeyPress(.downArrow) { move(1) }
    }

    private func move(_ delta: Int) -> KeyPress.Result {
        highlightedIndex = movedHighlight(current: highlightedIndex, delta: delta, count: highlightableValues.count)
        return .handled
    }

    private var searchField: some View {
        TextField(placeholder, text: $query)
            .textFieldStyle(.plain)
            .focused($searchFocused)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .onSubmit {
                let values = highlightableValues
                if values.indices.contains(highlightedIndex) {
                    selection = values[highlightedIndex]
                    onClose()
                } else if let first = values.first {
                    selection = first
                    onClose()
                }
            }
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs + 2)
            .background(ChamferShape(cut: 4).fill(theme.surface.opacity(0.7)))
            .overlay(ChamferShape(cut: 4).strokeBorder(theme.accentPrimary.opacity(0.3), lineWidth: 1))
    }

    // Section header row in the flattened `LazyVStack`. Empty headers are never
    // emitted into `flatItems`, so this always renders a real label.
    private func headerView(_ header: String) -> some View {
        Text(header.uppercased())
            .font(AinkradFontResolver.font(.caption, typography: typo))
            .foregroundStyle(theme.foreground.opacity(0.45))
            .kerning(1.0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.top, AinkradSpacing.xs)
            .padding(.bottom, 2)
    }

    private func optionRow(_ row: AinkradGroupedRow<T>) -> some View {
        let isSelected = row.value == selection
        let isHovered = row.isEnabled && hoveredValue == row.value
        let isHighlighted = row.isEnabled && highlightableValues.firstIndex(of: row.value) == highlightedIndex
        let content = HStack(spacing: AinkradSpacing.xs) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 6))
                .foregroundStyle(theme.accentSecondary)
                .opacity(isSelected ? 1 : 0)
            if let icon = row.icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.foreground.opacity(row.isEnabled ? 0.75 : 0.4))
            }
            if let dot = row.swatch {
                ColorSwatchDot(color: dot, size: 9)
            }
            Text(row.title)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground.opacity(row.isEnabled ? 1 : 0.4))
            Spacer(minLength: AinkradSpacing.sm)
            if let detail = row.detail {
                Text(detail)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(row.isEnabled ? 0.5 : 0.3))
            }
        }
        .padding(.horizontal, AinkradSpacing.sm)
        .padding(.vertical, AinkradSpacing.xs + 2)
        .background(
            ChamferShape(cut: 4).fill((isHovered || isHighlighted) ? theme.accentSecondary.opacity(0.18) : .clear)
        )
        .contentShape(Rectangle())

        return Group {
            if row.isEnabled {
                Button {
                    selection = row.value
                    onClose()
                } label: {
                    content
                }
                .buttonStyle(.plain)
                .animation(AinkradMotion.hover, value: isHovered)
                .onHover { hovering in
                    hoveredValue = hovering ? row.value : (hoveredValue == row.value ? nil : hoveredValue)
                    if hovering, let index = highlightableValues.firstIndex(of: row.value) {
                        highlightedIndex = index
                    }
                }
            } else {
                content
            }
        }
    }
}
