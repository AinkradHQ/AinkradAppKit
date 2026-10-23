import AinkradAppKitContract
import SwiftUI

/// Toggles a command-menu selection: tapping the already-selected item clears
/// it, tapping any other item selects it. Pure — `AinkradCommandMenu`'s
/// single-select-with-deselect behavior, unit-testable without SwiftUI.
public func commandMenuToggled<T: Hashable>(_ item: T, current: T?) -> T? {
    current == item ? nil : item
}

/// Moves a command-menu keyboard highlight by `delta` within `count` rows.
/// `nil` means "nothing highlighted yet" — the state the menu starts in, so
/// no row is painted as if hovered before the user presses a key. The first
/// ↓ lands on the first row, the first ↑ on the last. Pure, so the palette's
/// key handling is testable without a window.
public func commandMenuHighlightMoved(_ current: Int?, delta: Int, count: Int) -> Int? {
    guard count > 0 else { return nil }
    guard let current else { return delta > 0 ? 0 : count - 1 }
    return min(max(current + delta, 0), count - 1)
}

/// Pairs each item with whether it's the current `selected` value. Pure —
/// `AinkradNavList`'s row model, unit-testable without SwiftUI.
public func navListRows<T: Hashable>(items: [T], selected: T) -> [(item: T, isSelected: Bool)] {
    items.map { ($0, $0 == selected) }
}

/// The SAO vertical menu-bar motif: a stack of chamfer buttons, each with a
/// leading icon and label, hover scan-line, and a glowing accent fill when
/// selected. `selection` is optional — tapping the selected row deselects it.
///
/// `detail` and `value` are additive, optional per-item slots (both default
/// to `nil`) for a secondary line (e.g. a breadcrumb) and a trailing value —
/// added so richer result lists (settings search) don't need a look-alike.
/// `uppercased` (default `true`, matching the original motif) turns off the
/// shouty label transform for content where sentence case matters.
/// `emptyState` (default `nil`) renders in place of the row stack when
/// `items` is empty.
///
/// Keyboard highlight: `highlight` (default `nil`) lets an owner drive the
/// ↑/↓ highlight from OUTSIDE — necessary whenever focus lives somewhere else
/// (a search field in another pane), because `.onKeyPress` only ever fires
/// for the focus chain and this menu is not focusable. `nil` keeps a private
/// highlight, and that highlight starts UNSET so no row is emphasised until a
/// key actually moves it. `handlesKeyPresses` (default `false`) opts a
/// focusable call site into the menu's own ↑/↓/Return handling; off by
/// default so consumers that never asked for keyboard nav don't have those
/// keys swallowed.
public struct AinkradCommandMenu<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T?
    private let icon: (T) -> String
    private let label: (T) -> String
    private let detail: ((T) -> String?)?
    private let value: ((T) -> String?)?
    private let uppercased: Bool
    private let emptyState: (() -> AnyView)?
    private let externalHighlight: Binding<Int?>?
    private let handlesKeyPresses: Bool
    // Opt-ins set by the modifier methods below (not init params: a defaulted
    // parameter is not ABI-compatible).
    var usesPaletteRows = false
    var matchedCharacters: ((T) -> [Int])?
    var sectionTitle: ((T) -> String?)?
    var glyphTint: ((T) -> Color?)?
    var glyphSize: CGFloat?
    var kind: ((T) -> String?)?
    var kindTint: ((T) -> Color?)?

    @Environment(\.ainkradReduceMotion) private var reduceMotion
    /// Starts unset: `emphasized` is `hovering || isHighlighted`, so seeding
    /// this to 0 painted the first row of EVERY consumer as permanently
    /// hovered — elevated fill plus accent border — before any key was pressed.
    @State private var internalHighlight: Int?

    private var highlightedIndex: Int? { externalHighlight?.wrappedValue ?? internalHighlight }

    private func setHighlight(_ value: Int?) {
        if let externalHighlight { externalHighlight.wrappedValue = value } else { internalHighlight = value }
    }

    public init(
        items: [T],
        selection: Binding<T?>,
        icon: @escaping (T) -> String,
        label: @escaping (T) -> String,
        detail: ((T) -> String?)? = nil,
        value: ((T) -> String?)? = nil,
        uppercased: Bool = true,
        emptyState: (() -> AnyView)? = nil,
        highlight: Binding<Int?>? = nil,
        handlesKeyPresses: Bool = false
    ) {
        self.externalHighlight = highlight
        self.handlesKeyPresses = handlesKeyPresses
        self.items = items
        self._selection = selection
        self.icon = icon
        self.label = label
        self.detail = detail
        self.value = value
        self.uppercased = uppercased
        self.emptyState = emptyState
    }

    /// Draws the rows as the Forge palettes do (quick open, command palette):
    /// one flat line each — title, the `detail` inline after it in faint
    /// mono, the `value` as outlined keycaps (space-separated: `"⌘K ⌘\\"`
    /// is two caps) — with only the highlighted row filled, and a `↵` cap on
    /// a highlighted row that has no shortcut. Labels keep their case. An
    /// empty `icon` string draws no glyph.
    public func paletteRows() -> Self {
        var copy = self
        copy.usesPaletteRows = true
        return copy
    }

    /// Character offsets into each item's label to draw bold in the accent —
    /// the letters a fuzzy query matched.
    public func matchedCharacters(_ offsets: @escaping (T) -> [Int]) -> Self {
        var copy = self
        copy.matchedCharacters = offsets
        return copy
    }

    /// A caption above the first item of each run of items sharing a section
    /// ("Recently opened", "Files"); `nil` starts no section. Items are drawn
    /// in the order given, so group them before passing them in.
    public func sections(_ title: @escaping (T) -> String?) -> Self {
        var copy = self
        copy.sectionTitle = title
        return copy
    }

    /// Under `paletteRows()`, draws each `icon` string as a text glyph (`"◆"`,
    /// `"≡"`, `"#"`) instead of an SF Symbol name, in `tint(item)` — the
    /// secondary accent when `nil`. Forge's quick open colours each file type
    /// (mockup 02).
    public func iconGlyphs(tint: @escaping (T) -> Color?) -> Self {
        var copy = self
        copy.glyphTint = tint
        return copy
    }

    /// `iconGlyphs(tint:)` with the glyphs drawn at `size` points instead of
    /// the row's 13 — the mockups' `◆` reads a little larger (mockup 02).
    public func iconGlyphs(tint: @escaping (T) -> Color?, size: CGFloat) -> Self {
        var copy = iconGlyphs(tint: tint)
        copy.glyphSize = size
        return copy
    }

    /// Under `paletteRows()`, leads a row with `kind(item)` — the symbol's
    /// kind, `"struct"` or `"func"` — in place of its icon, drawn in
    /// `tint(item)`, or the editor's type colour when `nil`, as Forge's quick
    /// open lists symbols (mockup 02). Items whose kind is `nil` keep their icon.
    public func kinds(_ kind: @escaping (T) -> String?, tint: @escaping (T) -> Color?) -> Self {
        var copy = self
        copy.kind = kind
        copy.kindTint = tint
        return copy
    }

    /// The section caption to draw above `items[index]`, if it starts one.
    func sectionStart(at index: Int) -> String? {
        guard let sectionTitle, let title = sectionTitle(items[index]) else { return nil }
        return index > 0 && sectionTitle(items[index - 1]) == title ? nil : title
    }

    public var body: some View {
        if items.isEmpty, let emptyState {
            emptyState()
        } else {
            VStack(spacing: usesPaletteRows ? 0 : AinkradSpacing.xs) {
                // Keyed by the ITEM, not its position: with positional ids a
                // re-ranked result list makes every row reuse the state of
                // whatever used to sit at its index, so a reorder animates as
                // a set of edits.
                ForEach(Array(items.enumerated()), id: \.element) { index, item in
                    if let section = sectionStart(at: index) {
                        AinkradPaletteSectionHeader(title: section)
                    }
                    row(item, index: index)
                }
            }
            .modifier(
                CommandMenuKeys(
                    enabled: handlesKeyPresses,
                    move: { delta in
                        setHighlight(commandMenuHighlightMoved(highlightedIndex, delta: delta, count: items.count))
                    },
                    activateHighlighted: {
                        guard let index = highlightedIndex, items.indices.contains(index) else { return false }
                        activate(items[index])
                        return true
                    })
            )
            .onChange(of: items.count) { _, newCount in
                guard let index = highlightedIndex else { return }
                setHighlight(newCount == 0 ? nil : min(index, newCount - 1))
            }
        }
    }

    @ViewBuilder private func row(_ item: T, index: Int) -> some View {
        if usesPaletteRows {
            AinkradPaletteRow(
                icon: icon(item), label: label(item), matched: Set(matchedCharacters?(item) ?? []),
                detail: detail.flatMap { $0(item) }, value: value.flatMap { $0(item) },
                isHighlighted: index == highlightedIndex, showsReturnKey: true,
                iconIsGlyph: glyphTint != nil, iconTint: glyphTint?(item), iconGlyphSize: glyphSize,
                kind: kind?(item), kindTint: kindTint?(item)
            ) { activate(item) }
        } else {
            AinkradCommandMenuRow(
                icon: icon(item),
                label: label(item),
                detail: detail.flatMap { $0(item) },
                value: value.flatMap { $0(item) },
                uppercased: uppercased,
                isSelected: item == selection,
                isHighlighted: index == highlightedIndex,
                matched: Set(matchedCharacters?(item) ?? [])
            ) {
                activate(item)
            }
        }
    }

    private func activate(_ item: T) {
        let next = commandMenuToggled(item, current: selection)
        if reduceMotion {
            selection = next
        } else {
            withAnimation(AinkradMotion.materialize) { selection = next }
        }
    }
}

/// The menu's own ↑/↓/Return handling, applied only when a call site opts in.
/// `.onKeyPress` is delivered through the focus chain, so this fires only when
/// the menu (or a descendant) is focused — which is exactly why it is off by
/// default and why an owner whose focus lives elsewhere drives the highlight
/// through the `highlight` binding instead.
private struct CommandMenuKeys: ViewModifier {
    let enabled: Bool
    let move: (Int) -> Void
    let activateHighlighted: () -> Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .focusable()
                .onKeyPress(.downArrow) {
                    move(1)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    move(-1)
                    return .handled
                }
                .onKeyPress(.return) { activateHighlighted() ? .handled : .ignored }
        } else {
            content
        }
    }
}

private struct AinkradCommandMenuRow: View {
    let icon: String
    let label: String
    let detail: String?
    let value: String?
    let uppercased: Bool
    let isSelected: Bool
    let isHighlighted: Bool
    let matched: Set<Int>
    let action: () -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    private var emphasized: Bool { hovering || isHighlighted }

    /// The label, its matched letters bold in the secondary accent.
    private var title: AttributedString {
        let text = uppercased ? skin.labelCased(label) : label
        var out = AttributedString()
        for run in ainkradMatchRuns(text, matched: matched) {
            var piece = AttributedString(run.text)
            if run.isMatch {
                piece.foregroundColor = skin.color(skin.palette.accentSecondary)
                piece.inlinePresentationIntent = .stronglyEmphasized
            }
            out += piece
        }
        return out
    }

    var body: some View {
        let cmd = skin.components.commandMenuRow
        let shape = AinkradSkinShape(token: cmd.shape)
        var state: AinkradControlState = []
        if isSelected { state.insert(.selected) }
        if emphasized { state.insert(.hover) }

        return Button(action: action) {
            HStack(spacing: skin.spacing.sm) {
                Image(systemName: icon)
                    .font(skin.font(cmd.glyphFont, typography: typo))
                    .frame(width: cmd.glyphWidth)
                VStack(alignment: .leading, spacing: skin.spacing.xs / 2) {
                    Text(title)
                        .font(skin.font(cmd.titleFont, typography: typo))
                        .tracking(uppercased ? cmd.uppercasedTracking : 0)
                    if let detail {
                        Text(detail)
                            .font(skin.font(cmd.detailFont, typography: typo))
                            .foregroundStyle(skin.color(cmd.detailColor))
                    }
                }
                Spacer(minLength: skin.spacing.sm)
                if let value, !value.isEmpty {
                    Text(value)
                        .font(skin.font(cmd.valueFont, typography: typo))
                        .foregroundStyle(skin.color(cmd.valueColor))
                }
            }
            .foregroundStyle(
                isSelected ? skin.color(skin.palette.accentPrimary).contrastingText : skin.color(cmd.fg, state: state)
            )
            .padding(.horizontal, skin.spacing.md)
            .padding(.vertical, skin.spacing.sm)
            .modifier(CommandRowChrome(shape: shape, state: state, isSelected: isSelected, emphasized: emphasized))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion && !skin.usesNativeGlass ? cmd.hoverScale : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// Sidebar-style navigation list — single-select rows, an accent bar leading
/// the selected row, and no divider lines between rows.
public struct AinkradNavList<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let icon: (T) -> String?
    private let label: (T) -> String
    /// Set by `counts(_:)`.
    var count: ((T) -> AinkradNavCount?)?

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// A trailing count or badge per row; `nil` shows none for that row.
    public func counts(_ count: @escaping (T) -> AinkradNavCount?) -> Self {
        var copy = self
        copy.count = count
        return copy
    }

    public init(items: [T], selection: Binding<T>, icon: @escaping (T) -> String?, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self.icon = icon
        self.label = label
    }

    public var body: some View {
        VStack(spacing: AinkradSpacing.xs / 2) {
            ForEach(navListRows(items: items, selected: selection), id: \.item) { row in
                AinkradNavListRow(
                    icon: icon(row.item), label: label(row.item), count: count?(row.item), isSelected: row.isSelected
                ) {
                    if reduceMotion {
                        selection = row.item
                    } else {
                        withAnimation(AinkradMotion.materialize) { selection = row.item }
                    }
                }
            }
        }
    }
}

private struct AinkradNavListRow: View {
    let icon: String?
    let label: String
    let count: AinkradNavCount?
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    @ViewBuilder private var countView: some View {
        if let count {
            let font = skin.font(
                AinkradFontToken(sizeKey: "t10", weight: count.tone == nil ? nil : "semibold", mono: "family"))
            if let tone = count.tone {
                let fill = tone.color(skin)
                Text(count.text).font(font).foregroundStyle(fill.contrastingText)
                    .padding(.horizontal, skin.size.s6)
                    .background(fill, in: Capsule())
            } else {
                Text(count.text).font(font).foregroundStyle(skin.color(skin.text.faint))
            }
        }
    }

    var body: some View {
        let nav = skin.components.navListRow
        let tick = skin.roles.accentTick
        let shape = AinkradSkinShape(token: nav.shape)
        var state: AinkradControlState = []
        if isSelected { state.insert(.selected) }
        if hovering { state.insert(.hover) }

        return Button(action: action) {
            HStack(spacing: skin.spacing.sm) {
                Rectangle()
                    .fill(skin.color(tick.fill))
                    .frame(width: skin.usesNativeGlass ? 0 : nav.tickWidth)
                    .opacity(isSelected && !skin.usesNativeGlass ? 1 : 0)
                    .shadow(
                        color: skin.color(tick.glow.color, state: isSelected ? [.selected] : []),
                        radius: tick.glow.radius.rest)
                if let icon {
                    Image(systemName: icon)
                        .font(skin.font(nav.glyphFont, typography: typo))
                        .frame(width: nav.glyphWidth)
                }
                Text(label)
                    .font(skin.font(isSelected ? nav.bodySelectedFont : nav.bodyFont, typography: typo))
                Spacer(minLength: 0)
                countView
            }
            .foregroundStyle(
                skin.usesNativeGlass
                    ? (isSelected
                        ? skin.color(skin.palette.accentPrimary).contrastingText : skin.color(skin.text.primary))
                    : skin.color(nav.fg, state: state)
            )
            .padding(.vertical, skin.spacing.sm)
            .padding(.horizontal, skin.spacing.sm)
            .background {
                if skin.usesNativeGlass {
                    NativeSelectionBackground(
                        isSelected: isSelected, isHovered: hovering, accent: skin.color(skin.palette.accentPrimary))
                } else {
                    shape.fill(skin.color(nav.fill, state: state))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// A command row's chrome: Neon's fill, stroke, glow and scanline, or the
/// macOS menu highlight under Glass Native.
private struct CommandRowChrome: ViewModifier {
    let shape: AinkradSkinShape
    let state: AinkradControlState
    let isSelected: Bool
    let emphasized: Bool

    @Environment(\.ainkradSkin) private var skin

    @ViewBuilder func body(content: Content) -> some View {
        if skin.usesNativeGlass {
            content.background(
                NativeSelectionBackground(
                    isSelected: isSelected, isHovered: emphasized, accent: skin.color(skin.palette.accentPrimary)))
        } else {
            let cmd = skin.components.commandMenuRow
            content
                .background(shape.fill(skin.color(cmd.fill, state: state)))
                .overlay(
                    shape.strokeBorder(
                        skin.color(cmd.stroke.color, state: state), lineWidth: cmd.stroke.width.resolve(state))
                )
                .shadow(color: skin.color(cmd.glow.color, state: state), radius: cmd.glow.radius.resolve(state))
                .scanlineOverlay(active: emphasized && !isSelected)
        }
    }
}
