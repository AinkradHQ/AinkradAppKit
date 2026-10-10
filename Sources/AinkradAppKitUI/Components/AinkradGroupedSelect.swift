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
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var appeared = false
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        let mat = skin.roles.materialize
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : mat.scale, anchor: .top)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(skin.animation(mat.animation)) { appeared = true }
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

    @Environment(\.ainkradSkin) private var skin
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
        let trig = skin.components.groupedSelectTrigger
        let shape = AinkradSkinShape(token: trig.shape)
        var state: AinkradControlState = []
        if isOpen { state.insert(.selected) }
        return Button {
            isOpen ? close() : open()
        } label: {
            HStack(spacing: skin.spacing.xs) {
                Text(triggerLabel)
                    .font(skin.font(AinkradFontToken(role: "body"), typography: typo))
                    .foregroundStyle(skin.color(skin.palette.foreground))
                Spacer(minLength: skin.spacing.sm)
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .font(skin.font(trig.chevron, typography: typo))
                    .foregroundStyle(skin.color(trig.chevronColor))
            }
            .padding(.horizontal, skin.spacing.md)
            .padding(.vertical, skin.spacing.sm)
            .background(shape.fill(skin.color(trig.fill)))
            .overlay(
                shape.strokeBorder(
                    skin.color(trig.stroke.color, state: state), lineWidth: trig.stroke.width.resolve(state))
            )
            .shadow(color: skin.color(trig.glow.color, state: state), radius: trig.glow.radius.resolve(state))
            .contentShape(shape)
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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var query = ""
    @State private var highlightedIndex = 0
    @State private var hoveredValue: T?
    @FocusState private var searchFocused: Bool

    private var filteredSections: [AinkradGroupedSection<T>] { filterGroupedSections(sections, query: query) }
    private var highlightableValues: [T] { selectableValues(filteredSections) }

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
        let popover = skin.roles.popover
        let shape = AinkradSkinShape(token: popover.shape)
        VStack(alignment: .leading, spacing: skin.spacing.xs) {
            searchField
            if filteredSections.isEmpty {
                Text("No matches")
                    .font(skin.font(AinkradFontToken(role: "caption"), typography: typo))
                    .foregroundStyle(skin.color(skin.text.muted))
                    .padding(.horizontal, skin.spacing.sm)
                    .padding(.vertical, skin.spacing.xs)
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
                .frame(maxHeight: skin.components.groupedSelectRows.panelMaxHeight)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .padding(skin.spacing.xs)
        .background(shape.fill(skin.color(popover.fill)))
        .overlay(shape.strokeBorder(skin.color(popover.stroke.color), lineWidth: popover.stroke.width.resolve([])))
        .shadow(color: skin.color(popover.shadow.color), radius: popover.shadow.radius, y: popover.shadow.y)
        .frame(minWidth: skin.components.groupedSelectRows.panelMinWidth)
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
        let panelSearch = skin.roles.panelSearch
        let searchShape = AinkradSkinShape(token: panelSearch.shape)
        return TextField(placeholder, text: $query)
            .textFieldStyle(.plain)
            .focused($searchFocused)
            .font(skin.font(AinkradFontToken(role: "body"), typography: typo))
            .foregroundStyle(skin.color(skin.palette.foreground))
            .tint(skin.color(skin.palette.accentSecondary))
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
            .padding(.horizontal, skin.spacing.sm)
            .padding(.vertical, panelSearch.paddingV)
            .background(searchShape.fill(skin.color(panelSearch.fill)))
            .overlay(
                searchShape.strokeBorder(
                    skin.color(panelSearch.stroke.color), lineWidth: panelSearch.stroke.width.resolve([])))
    }

    private func headerView(_ header: String) -> some View {
        let grp = skin.components.groupedSelectRows
        return Text(skin.labelCased(header))
            .font(skin.font(grp.headerFont, typography: typo))
            .foregroundStyle(skin.color(grp.headerColor))
            .kerning(grp.headerKerning)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, skin.spacing.sm)
            .padding(.top, skin.spacing.xs)
            .padding(.bottom, grp.headerPadBottom)
    }

    private func optionRow(_ row: AinkradGroupedRow<T>) -> some View {
        let isSelected = row.value == selection
        let isHovered = row.isEnabled && hoveredValue == row.value
        let isHighlighted = row.isEnabled && highlightableValues.firstIndex(of: row.value) == highlightedIndex
        let grp = skin.components.groupedSelectRows
        let rowRole = skin.roles.optionRow
        let rowShape = AinkradSkinShape(token: rowRole.shape)
        var iconState: AinkradControlState = []
        if !row.isEnabled { iconState.insert(.disabled) }
        let content = HStack(spacing: skin.spacing.xs) {
            Image(systemName: "diamond.fill")
                .font(skin.font(rowRole.selectedDot, typography: typo))
                .foregroundStyle(skin.color(skin.palette.accentSecondary))
                .opacity(isSelected ? 1 : 0)
            if let icon = row.icon {
                Image(systemName: icon)
                    .font(skin.font(grp.iconFont, typography: typo))
                    .foregroundStyle(skin.color(grp.iconColor, state: iconState))
            }
            if let dot = row.swatch {
                ColorSwatchDot(color: dot, size: rowRole.swatchDotSize)
            }
            Text(row.title)
                .font(skin.font(grp.titleFont, typography: typo))
                .foregroundStyle(skin.color(grp.titleColor, state: iconState))
            Spacer(minLength: skin.spacing.sm)
            if let detail = row.detail {
                Text(detail)
                    .font(skin.font(grp.detailFont, typography: typo))
                    .foregroundStyle(skin.color(grp.detailColor, state: iconState))
            }
        }
        .padding(.horizontal, skin.spacing.sm)
        .padding(.vertical, rowRole.paddingV)
        .background(
            rowShape.fill(skin.color(rowRole.fill, state: (isHovered || isHighlighted) ? [.hover] : []))
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
