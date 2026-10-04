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

    public var body: some View {
        if items.isEmpty, let emptyState {
            emptyState()
        } else {
            VStack(spacing: AinkradSpacing.xs) {
                // Keyed by the ITEM, not its position: with positional ids a
                // re-ranked result list makes every row reuse the state of
                // whatever used to sit at its index, so a reorder animates as
                // a set of edits.
                ForEach(Array(items.enumerated()), id: \.element) { index, item in
                    AinkradCommandMenuRow(
                        icon: icon(item),
                        label: label(item),
                        detail: detail.flatMap { $0(item) },
                        value: value.flatMap { $0(item) },
                        uppercased: uppercased,
                        isSelected: item == selection,
                        isHighlighted: index == highlightedIndex
                    ) {
                        activate(item)
                    }
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
    let action: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    private var emphasized: Bool { hovering || isHighlighted }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AinkradSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
                    Text(uppercased ? label.uppercased() : label)
                        .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                        .tracking(uppercased ? 0.6 : 0)
                    if let detail {
                        Text(detail)
                            .font(AinkradFontResolver.font(.mono, typography: typo))
                            .foregroundStyle(theme.foreground.opacity(0.45))
                    }
                }
                Spacer(minLength: AinkradSpacing.sm)
                if let value, !value.isEmpty {
                    Text(value)
                        .font(AinkradFontResolver.font(.mono, typography: typo))
                        .foregroundStyle(theme.accentSecondary.opacity(0.85))
                }
            }
            .foregroundStyle(
                isSelected ? theme.accentPrimary.contrastingText : theme.foreground.opacity(emphasized ? 0.9 : 0.65)
            )
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(
                ChamferShape(cut: 6)
                    .fill(
                        isSelected
                            ? theme.accentPrimary.opacity(0.85) : theme.surfaceElevated.opacity(emphasized ? 0.5 : 0.2))
            )
            .overlay(
                ChamferShape(cut: 6)
                    .strokeBorder(
                        theme.accentSecondary.opacity(isSelected ? 0.9 : (emphasized ? 0.5 : 0)), lineWidth: 1.25)
            )
            .shadow(color: theme.accentSecondary.opacity(isSelected ? 0.5 : 0), radius: isSelected ? 5 : 0)
            .scanlineOverlay(active: hovering && !isSelected)
            .contentShape(ChamferShape(cut: 6))
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? 1.015 : 1.0)
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

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(items: [T], selection: Binding<T>, icon: @escaping (T) -> String?, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self.icon = icon
        self.label = label
    }

    public var body: some View {
        VStack(spacing: AinkradSpacing.xs / 2) {
            ForEach(navListRows(items: items, selected: selection), id: \.item) { row in
                AinkradNavListRow(icon: icon(row.item), label: label(row.item), isSelected: row.isSelected) {
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
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AinkradSpacing.sm) {
                Rectangle()
                    .fill(theme.accentSecondary)
                    .frame(width: 2)
                    .opacity(isSelected ? 1 : 0)
                    .shadow(color: theme.accentSecondary.opacity(isSelected ? 0.6 : 0), radius: 2)
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 16)
                }
                Text(label)
                    .font(AinkradFontResolver.font(.body, weight: isSelected ? .semibold : .regular, typography: typo))
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? theme.foreground : theme.foreground.opacity(hovering ? 0.85 : 0.6))
            .padding(.vertical, AinkradSpacing.sm)
            .padding(.horizontal, AinkradSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AinkradRadius.sm)
                    .fill(
                        isSelected
                            ? theme.surfaceElevated.opacity(0.6)
                            : (hovering ? theme.surfaceElevated.opacity(0.3) : .clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}
