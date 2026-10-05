import AinkradAppKitContract
import SwiftUI

/// Index of `selection` within `items`, or nil. Pure — unit tested.
public func pickerSelectionIndex<T: Hashable>(items: [T], selection: T) -> Int? {
    items.firstIndex(of: selection)
}

/// Custom segmented control — chamfer segments with a luminous accent fill
/// on the selected item and a hover glow on the rest (never a native
/// `Picker`).
public struct AinkradSegmentedPicker<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let label: (T) -> String
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var hoveredItem: T?

    public init(items: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self.label = label
    }
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: skin.spacing.xs + 2) {
                ForEach(items, id: \.self) { item in segment(item) }
            }
        }
        .animation(AinkradMotion.hover, value: selection)
    }
    @ViewBuilder private func segment(_ item: T) -> some View {
        let picker = skin.components.segmentedPicker
        let shape = AinkradSkinShape(token: picker.shape)
        let selected = item == selection
        let hovered = hoveredItem == item
        var state: AinkradControlState = []
        if selected { state.insert(.selected) }
        if hovered { state.insert(.hover) }
        return Button {
            selection = item
        } label: {
            Text(label(item))
                .font(skin.font(selected ? picker.labelSelectedFont : picker.labelFont, typography: typo))
                .foregroundStyle(
                    selected
                        ? skin.color(skin.palette.accentPrimary).contrastingText : skin.color(picker.fg, state: state)
                )
                .padding(.horizontal, skin.spacing.md).padding(.vertical, skin.spacing.xs + 2)
                .background(shape.fill(skin.color(picker.fill, state: state)))
                .overlay(
                    shape.strokeBorder(
                        skin.color(picker.stroke.color, state: state), lineWidth: picker.stroke.width.resolve(state))
                )
                .shadow(color: skin.color(picker.glow.color, state: state), radius: picker.glow.radius.resolve(state))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
        .animation(AinkradMotion.hover, value: hovered)
        .onHover { hovering in hoveredItem = hovering ? item : (hoveredItem == item ? nil : hoveredItem) }
    }
}

/// Pairs each item with whether it is the current selection. Pure — the shape
/// `AinkradSelect`'s option rows are built from, unit-testable without SwiftUI.
public func selectOptionRows<T: Hashable>(items: [T], selected: T) -> [(item: T, isSelected: Bool)] {
    items.map { ($0, $0 == selected) }
}

/// Whether a picker row should render a leading color swatch for `item` — i.e.
/// the row's `swatch(item)` resolved to a non-nil color. Pure — the swatch-
/// visibility rule shared by the color-labeled `AinkradSelect`/
/// `AinkradMultiSelect` overloads, unit-testable without SwiftUI.
func shouldShowSwatch<T>(_ swatch: (T) -> Color?, for item: T) -> Bool {
    swatch(item) != nil
}

/// Toggles `item`'s membership in `selection` — present items are removed,
/// absent items are added. Pure — the reducer `AinkradMultiSelect` rows call
/// on tap, unit-testable without SwiftUI.
public func toggledSelection<T: Hashable>(_ item: T, in selection: Set<T>) -> Set<T> {
    var result = selection
    if result.contains(item) { result.remove(item) } else { result.insert(item) }
    return result
}

/// Items whose `label` contains `query` (case-insensitive substring match).
/// An empty query returns every item unfiltered. Pure — `AinkradCombobox`'s
/// filtering logic, unit-testable without SwiftUI.
public func comboboxFilter<T>(items: [T], query: String, label: (T) -> String) -> [T] {
    guard !query.isEmpty else { return items }
    return items.filter { label($0).range(of: query, options: .caseInsensitive) != nil }
}

/// Moves a highlighted-row index by `delta`, clamped to `0..<count` (or `0`
/// when `count <= 0`, i.e. an empty/filtered-to-nothing list). Pure — the
/// arrow-key nav math shared by `AinkradSelect`/`AinkradMultiSelect`/
/// `AinkradSearchableSelect`'s floating panels, unit-testable without
/// SwiftUI. `count` is re-evaluated by the caller on every keystroke so this
/// clamps correctly against a live-filtered row count, not just the static
/// item list.
public func movedHighlight(current: Int, delta: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(max(current + delta, 0), count - 1)
}

/// Fades + scales option-panel content in on appear, then holds steady — the
/// "materialize" look shared by every picker's floating panel content, now
/// that the panel itself lives in a separate top-level `NSPanel` (so a
/// SwiftUI `.transition` on the same view tree no longer applies). Skips the
/// animation entirely under Reduce Motion.
private struct PanelMaterialize<Content: View>: View {
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

/// Custom Cardinal HUD dropdown — chamfer trigger field + a custom-drawn
/// option panel presented in a top-level `AinkradFloatingPanel` (never a
/// native `Menu`/`Picker`/`.popover`), so it floats above ALL app content and
/// is never clipped by an ancestor's bounds. Dismisses on selection, outside
/// click, Esc, or the host window losing key/moving — all handled by the
/// floating panel itself.
///
/// The dropdown ALWAYS carries a live-filter search field pinned to the top
/// of its panel (typing narrows the rows via `comboboxFilter`), and the panel
/// is floored to the trigger's own width so it never renders narrower than the
/// field that opened it. `AinkradSearchableSelect` is now a thin alias of this
/// type (kept for source/ABI compatibility).
public struct AinkradSelect<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let label: (T) -> String
    private var swatch: (T) -> Color? = { _ in nil }
    private var searchPlaceholder: String = "Search…"

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var isOpen = false

    public init(items: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self.label = label
    }

    public init(
        items: [T], selection: Binding<T>, label: @escaping (T) -> String,
        swatch: @escaping (T) -> Color?
    ) {
        self.items = items
        self._selection = selection
        self.label = label
        self.swatch = swatch
    }

    public init(
        items: [T], selection: Binding<T>, label: @escaping (T) -> String,
        searchPlaceholder: String
    ) {
        self.items = items
        self._selection = selection
        self.label = label
        self.searchPlaceholder = searchPlaceholder
    }

    public var body: some View {
        trigger
            .ainkradFloatingPanel(isPresented: $isOpen, autofocusTextField: true, matchAnchorWidth: true) {
                PanelMaterialize {
                    SearchableSelectPanelView(
                        items: items, selection: $selection, label: label,
                        placeholder: searchPlaceholder, swatch: swatch, onClose: close)
                }
            }
    }

    private func open() { isOpen = true }
    private func close() { isOpen = false }

    private var trigger: some View {
        let trig = skin.components.selectTrigger
        let shape = AinkradSkinShape(token: trig.shape)
        var state: AinkradControlState = []
        if isOpen { state.insert(.selected) }
        return Button {
            isOpen ? close() : open()
        } label: {
            HStack(spacing: skin.spacing.xs) {
                Text(label(selection))
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

/// Multi-selection variant of `AinkradSelect` — same custom anchored overlay,
/// but tapping a row toggles its membership in `selection` (via
/// `toggledSelection`) instead of replacing it, and rows show a custom
/// checkmark glyph rather than a diamond. Same NO-native-menu contract.
public struct AinkradMultiSelect<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: Set<T>
    private let label: (T) -> String
    private var swatch: (T) -> Color? = { _ in nil }

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var isOpen = false

    public init(items: [T], selection: Binding<Set<T>>, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self.label = label
    }

    public init(
        items: [T], selection: Binding<Set<T>>, label: @escaping (T) -> String,
        swatch: @escaping (T) -> Color?
    ) {
        self.items = items
        self._selection = selection
        self.label = label
        self.swatch = swatch
    }

    private var triggerText: String {
        selection.isEmpty ? "Select…" : items.filter(selection.contains).map(label).joined(separator: ", ")
    }

    public var body: some View {
        trigger
            .ainkradFloatingPanel(isPresented: $isOpen, matchAnchorWidth: true) {
                PanelMaterialize {
                    MultiSelectPanelView(items: items, selection: $selection, label: label, swatch: swatch)
                }
            }
    }

    private func open() { isOpen = true }
    private func close() { isOpen = false }

    private var trigger: some View {
        let trig = skin.components.multiSelectTrigger
        let shape = AinkradSkinShape(token: trig.shape)
        var state: AinkradControlState = []
        if isOpen { state.insert(.selected) }
        return Button {
            isOpen ? close() : open()
        } label: {
            HStack(spacing: skin.spacing.xs) {
                Text(triggerText)
                    .font(skin.font(AinkradFontToken(role: "body"), typography: typo))
                    .foregroundStyle(skin.color(skin.palette.foreground))
                    .lineLimit(1)
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

/// Text-entry + filtered custom option list. Typing filters `items` (via
/// `comboboxFilter`); picking a row sets both `selection` and `text`. The
/// option list is presented in a top-level `AinkradFloatingPanel`, so it's
/// never clipped and floats above all app content. Freeform typing without a
/// pick leaves `selection` nil. Custom panel only — no native
/// menu/popover/list chrome.
public struct AinkradCombobox<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T?
    @Binding private var text: String
    private let label: (T) -> String

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool
    @State private var hoveredItem: T?

    public init(items: [T], selection: Binding<T?>, text: Binding<String>, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self._text = text
        self.label = label
    }

    private var filtered: [T] { comboboxFilter(items: items, query: text, label: label) }
    private var isOpen: Bool { isFocused && !filtered.isEmpty }

    private var panelBinding: Binding<Bool> {
        Binding(
            get: { isOpen },
            set: { newValue in if !newValue { isFocused = false } }
        )
    }

    public var body: some View {
        field
            .ainkradFloatingPanel(isPresented: panelBinding, matchAnchorWidth: true) {
                PanelMaterialize { optionsPanel }
            }
    }

    private var field: some View {
        let fieldTokens = skin.components.combobox
        let shape = AinkradSkinShape(token: fieldTokens.shape)
        var state: AinkradControlState = []
        if isFocused { state.insert(.focused) }
        return TextField("", text: $text)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .font(skin.font(AinkradFontToken(role: "body"), typography: typo))
            .foregroundStyle(skin.color(skin.palette.foreground))
            .tint(skin.color(skin.palette.accentSecondary))
            .padding(.horizontal, skin.spacing.md)
            .padding(.vertical, skin.spacing.sm)
            .background(shape.fill(skin.color(fieldTokens.fill)))
            .overlay(
                shape.strokeBorder(
                    skin.color(fieldTokens.stroke.color, state: state),
                    lineWidth: fieldTokens.stroke.width.resolve(state))
            )
            .shadow(
                color: skin.color(fieldTokens.glow.color, state: state), radius: fieldTokens.glow.radius.resolve(state))
    }

    private var optionsPanel: some View {
        let popover = skin.roles.popover
        let shape = AinkradSkinShape(token: popover.shape)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(filtered, id: \.self) { item in optionRow(item) }
        }
        .padding(skin.spacing.xs)
        .background(shape.fill(skin.color(popover.fill)))
        .overlay(shape.strokeBorder(skin.color(popover.stroke.color), lineWidth: popover.stroke.width.resolve([])))
        .shadow(color: skin.color(popover.shadow.color), radius: popover.shadow.radius, y: popover.shadow.y)
        .frame(minWidth: popover.minWidth)
    }

    private func optionRow(_ item: T) -> some View {
        let isSelected = selection == item
        let isHovered = hoveredItem == item
        let row = skin.roles.optionRow
        let rowShape = AinkradSkinShape(token: row.shape)
        return Button {
            selection = item
            text = label(item)
            isFocused = false
        } label: {
            HStack(spacing: skin.spacing.xs) {
                Image(systemName: "diamond.fill")
                    .font(skin.font(row.selectedDot, typography: typo))
                    .foregroundStyle(skin.color(skin.palette.accentSecondary))
                    .opacity(isSelected ? 1 : 0)
                Text(label(item))
                    .font(skin.font(AinkradFontToken(role: "body"), typography: typo))
                    .foregroundStyle(skin.color(skin.palette.foreground))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, skin.spacing.sm)
            .padding(.vertical, row.paddingV)
            .background(rowShape.fill(skin.color(row.fill, state: isHovered ? [.hover] : [])))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: isHovered)
        .onHover { hovering in hoveredItem = hovering ? item : (hoveredItem == item ? nil : hoveredItem) }
    }
}

/// Thin alias of `AinkradSelect` — kept so existing call sites and the
/// exported symbol keep working after search became the default on every
/// `AinkradSelect`. Its `placeholder:` maps straight to the select's
/// always-present search field. Prefer `AinkradSelect` directly in new code.
public struct AinkradSearchableSelect<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let label: (T) -> String
    private let placeholder: String

    public init(
        items: [T],
        selection: Binding<T>,
        label: @escaping (T) -> String,
        placeholder: String = "Search…"
    ) {
        self.items = items
        self._selection = selection
        self.label = label
        self.placeholder = placeholder
    }

    public var body: some View {
        AinkradSelect(items: items, selection: $selection, label: label, searchPlaceholder: placeholder)
    }
}
