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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var highlightedIndex = 0
    @State private var hoveredItem: T?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                optionRow(item, index: index)
            }
        }
        .padding(AinkradSpacing.xs)
        .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.97)))
        .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentSecondary.opacity(0.55), lineWidth: 1.25))
        .shadow(color: theme.accentSecondary.opacity(0.35), radius: 10, y: 4)
        .frame(minWidth: 160)
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
        // Reads live from the `@Binding` on every call — this view's own
        // `body` re-invokes whenever `selection` changes (it's a real
        // `@Binding` on a real mounted `View`), so `isSelected` is never
        // stale the way a value baked into a one-shot closure would be.
        let isSelected = selection.contains(item)
        let isHovered = hoveredItem == item
        let isHighlighted = index == highlightedIndex
        return Button {
            selection = toggledSelection(item, in: selection)
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                ZStack {
                    ChamferShape(cut: 2)
                        .strokeBorder(theme.accentSecondary.opacity(0.6), lineWidth: 1)
                        .frame(width: 12, height: 12)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(theme.accentSecondary)
                    }
                }
                if let dot = swatch(item) {
                    ColorSwatchDot(color: dot, size: 9)
                }
                Text(label(item))
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs + 2)
            .background(
                ChamferShape(cut: 4).fill((isHovered || isHighlighted) ? theme.accentSecondary.opacity(0.18) : .clear)
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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var query = ""
    @State private var highlightedIndex = 0
    @State private var hoveredItem: T?
    @FocusState private var searchFocused: Bool

    private var filtered: [T] { comboboxFilter(items: items, query: query, label: label) }

    var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.xs) {
            searchField
            if filtered.isEmpty {
                Text("No matches")
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.5))
                    .padding(.horizontal, AinkradSpacing.sm)
                    .padding(.vertical, AinkradSpacing.xs)
            } else {
                ForEach(Array(filtered.enumerated()), id: \.offset) { index, item in
                    optionRow(item, index: index)
                }
            }
        }
        .padding(AinkradSpacing.xs)
        .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.97)))
        .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentSecondary.opacity(0.55), lineWidth: 1.25))
        .shadow(color: theme.accentSecondary.opacity(0.35), radius: 10, y: 4)
        .frame(minWidth: 200)
        // `@FocusState` across a freshly-presented nonactivating `NSPanel` is
        // flaky the instant the panel appears — the async hop gives the
        // hosted view one more runloop tick to actually attach to the now-key
        // window before SwiftUI tries to move first responder. Belt-and-
        // suspenders: `AinkradFloatingPanelController` ALSO walks the hosted
        // `NSHostingView`'s subviews for the backing `NSTextField` and calls
        // `makeFirstResponder` on it directly via `autofocusTextField`.
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
        TextField(placeholder, text: $query)
            .textFieldStyle(.plain)
            .focused($searchFocused)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .onSubmit {
                if filtered.indices.contains(highlightedIndex) {
                    selection = filtered[highlightedIndex]
                    onClose()
                } else if let first = filtered.first {
                    selection = first
                    onClose()
                }
            }
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs + 2)
            .background(ChamferShape(cut: 4).fill(theme.surface.opacity(0.7)))
            .overlay(ChamferShape(cut: 4).strokeBorder(theme.accentPrimary.opacity(0.3), lineWidth: 1))
    }

    private func optionRow(_ item: T, index: Int) -> some View {
        let isSelected = item == selection
        let isHovered = hoveredItem == item
        let isHighlighted = index == highlightedIndex
        return Button {
            selection = item
            onClose()
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 6))
                    .foregroundStyle(theme.accentSecondary)
                    .opacity(isSelected ? 1 : 0)
                if let dot = swatch(item) {
                    ColorSwatchDot(color: dot, size: 9)
                }
                Text(label(item))
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs + 2)
            .background(
                ChamferShape(cut: 4).fill((isHovered || isHighlighted) ? theme.accentSecondary.opacity(0.18) : .clear)
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
