import AinkradAppKitContract
import SwiftUI

/// Hosted content of `AinkradSelect`/`AinkradMultiSelect`/
/// `AinkradSearchableSelect`'s floating panels.
///
/// These are dedicated `View` conformers rather than computed properties
/// built once (inside a closure captured at present-time) on the trigger
/// struct. That distinction is load-bearing: `AinkradFloatingPanelController`
/// hosts panel content in its own top-level `NSHostingView`, and a `some
/// View` value assembled by a plain computed property is evaluated ONCE, the
/// instant the closure passed to `present()` runs — any `ForEach` built from
/// it is handed a static, baked-in array forever after. A genuine `View`
/// struct with its own `@State`/`@Binding` doesn't have that problem:
/// SwiftUI re-invokes ITS `body` whenever that state changes, because the
/// state is now owned by the view actually mounted in the hosted graph, not
/// by a copy of some other struct captured in a one-shot closure. That was
/// the root cause of two reported bugs: the searchable select's rows never
/// re-filtered as the user typed, and the multi-select's checkmarks never
/// flipped until the panel was re-presented — both were reading state from a
/// snapshot that was never going to be re-read. See the wave3 follow-up
/// report for the full writeup.

/// `AinkradMultiSelect`'s option list: each row's checkmark reads `selection`
/// live from the `@Binding<Set<T>>` on every render, so a tap flips it
/// immediately without re-presenting the panel. Return toggles the
/// highlighted row instead of closing the panel (multi-select stays open
/// after every pick, same as a mouse click).
struct MultiSelectPanelView<T: Hashable>: View {
    let items: [T]
    @Binding var selection: Set<T>
    let label: (T) -> String
    var swatch: (T) -> Color? = { _ in nil }

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var highlightedIndex = 0
    @State private var hoveredItem: T?
    @FocusState private var focused: Bool

    var body: some View {
        let popover = skin.roles.popover
        let shape = AinkradSkinShape(token: popover.shape)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                optionRow(item, index: index)
            }
        }
        .padding(skin.spacing.xs)
        .background(shape.fill(skin.color(popover.fill)))
        .overlay(shape.strokeBorder(skin.color(popover.stroke.color), lineWidth: popover.stroke.width.resolve([])))
        .shadow(color: skin.color(popover.shadow.color), radius: popover.shadow.radius, y: popover.shadow.y)
        .frame(minWidth: popover.minWidth)
        .focusable()
        .focused($focused)
        .onAppear { DispatchQueue.main.async { focused = true } }
        .onKeyPress(.upArrow) { move(-1) }
        .onKeyPress(.downArrow) { move(1) }
        .onKeyPress(.return) { toggleHighlighted() }
    }

    private func move(_ delta: Int) -> KeyPress.Result {
        highlightedIndex = movedHighlight(current: highlightedIndex, delta: delta, count: items.count)
        return .handled
    }

    private func toggleHighlighted() -> KeyPress.Result {
        guard items.indices.contains(highlightedIndex) else { return .ignored }
        selection = toggledSelection(items[highlightedIndex], in: selection)
        return .handled
    }

    private func optionRow(_ item: T, index: Int) -> some View {
        let isSelected = selection.contains(item)
        let isHovered = hoveredItem == item
        let isHighlighted = index == highlightedIndex
        let check = skin.components.multiSelectCheck
        let checkShape = AinkradSkinShape(token: check.shape)
        let row = skin.roles.optionRow
        let rowShape = AinkradSkinShape(token: row.shape)
        return Button {
            selection = toggledSelection(item, in: selection)
        } label: {
            HStack(spacing: skin.spacing.xs) {
                ZStack {
                    checkShape
                        .strokeBorder(skin.color(check.stroke.color), lineWidth: check.stroke.width.resolve([]))
                        .frame(width: check.size, height: check.size)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(skin.font(check.glyphFont, typography: typo))
                            .foregroundStyle(skin.color(check.stroke.color))
                    }
                }
                if let dot = swatch(item) {
                    ColorSwatchDot(color: dot, size: row.swatchDotSize)
                }
                Text(label(item))
                    .font(skin.font(AinkradFontToken(role: "body"), typography: typo))
                    .foregroundStyle(skin.color(skin.palette.foreground))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, skin.spacing.sm)
            .padding(.vertical, row.paddingV)
            .background(
                rowShape.fill(skin.color(row.fill, state: (isHovered || isHighlighted) ? [.hover] : []))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: isHovered)
        .onHover { hovering in
            hoveredItem = hovering ? item : (hoveredItem == item ? nil : hoveredItem)
            if hovering { highlightedIndex = index }
        }
    }
}

/// `AinkradSearchableSelect`'s search field + option list. `query` and
/// `highlightedIndex` are `@State` owned by THIS view (not the trigger
/// struct captured into a closure), so every keystroke re-invokes `body`,
/// recomputes `filtered` via `comboboxFilter`, and re-renders the `ForEach`
/// against the new array — the fix for the filter never updating live.
struct SearchableSelectPanelView<T: Hashable>: View {
    let items: [T]
    @Binding var selection: T
    let label: (T) -> String
    let placeholder: String
    /// Optional leading color swatch per row (see `AinkradSelect.swatch`).
    /// Defaulted so callers that don't need swatches stay unchanged.
    var swatch: (T) -> Color? = { _ in nil }
    let onClose: () -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var query = ""
    @State private var highlightedIndex = 0
    @State private var hoveredItem: T?
    @FocusState private var searchFocused: Bool

    private var filtered: [T] { comboboxFilter(items: items, query: query, label: label) }

    var body: some View {
        let popover = skin.roles.popover
        let shape = AinkradSkinShape(token: popover.shape)
        VStack(alignment: .leading, spacing: skin.spacing.xs) {
            searchField
            if filtered.isEmpty {
                Text("No matches")
                    .font(skin.font(AinkradFontToken(role: "caption"), typography: typo))
                    .foregroundStyle(skin.color(skin.text.muted))
                    .padding(.horizontal, skin.spacing.sm)
                    .padding(.vertical, skin.spacing.xs)
            } else {
                ForEach(Array(filtered.enumerated()), id: \.offset) { index, item in
                    optionRow(item, index: index)
                }
            }
        }
        .padding(skin.spacing.xs)
        .background(shape.fill(skin.color(popover.fill)))
        .overlay(shape.strokeBorder(skin.color(popover.stroke.color), lineWidth: popover.stroke.width.resolve([])))
        .shadow(color: skin.color(popover.shadow.color), radius: popover.shadow.radius, y: popover.shadow.y)
        .frame(minWidth: skin.roles.panelSearch.panelMinWidth)
        .onAppear { DispatchQueue.main.async { searchFocused = true } }
        .onChange(of: query) { _, _ in highlightedIndex = 0 }
        .onKeyPress(.upArrow) { move(-1) }
        .onKeyPress(.downArrow) { move(1) }
    }

    private func move(_ delta: Int) -> KeyPress.Result {
        highlightedIndex = movedHighlight(current: highlightedIndex, delta: delta, count: filtered.count)
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
                if filtered.indices.contains(highlightedIndex) {
                    selection = filtered[highlightedIndex]
                    onClose()
                } else if let first = filtered.first {
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

    private func optionRow(_ item: T, index: Int) -> some View {
        let isSelected = item == selection
        let isHovered = hoveredItem == item
        let isHighlighted = index == highlightedIndex
        let row = skin.roles.optionRow
        let rowShape = AinkradSkinShape(token: row.shape)
        return Button {
            selection = item
            onClose()
        } label: {
            HStack(spacing: skin.spacing.xs) {
                Image(systemName: "diamond.fill")
                    .font(skin.font(row.selectedDot, typography: typo))
                    .foregroundStyle(skin.color(skin.palette.accentSecondary))
                    .opacity(isSelected ? 1 : 0)
                if let dot = swatch(item) {
                    ColorSwatchDot(color: dot, size: row.swatchDotSize)
                }
                Text(label(item))
                    .font(skin.font(AinkradFontToken(role: "body"), typography: typo))
                    .foregroundStyle(skin.color(skin.palette.foreground))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, skin.spacing.sm)
            .padding(.vertical, row.paddingV)
            .background(
                rowShape.fill(skin.color(row.fill, state: (isHovered || isHighlighted) ? [.hover] : []))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: isHovered)
        .onHover { hovering in
            hoveredItem = hovering ? item : (hoveredItem == item ? nil : hoveredItem)
            if hovering { highlightedIndex = index }
        }
    }
}
