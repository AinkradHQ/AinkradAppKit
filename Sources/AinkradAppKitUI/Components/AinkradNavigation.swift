import AinkradAppKitContract
import SwiftUI

/// Clamps `page` into `0..<count` (or `0` when `count <= 0`, i.e. no pages).
/// Pure — the paging math shared by `AinkradPagination` and `AinkradTabs`-
/// adjacent index bookkeeping, unit-testable without SwiftUI.
public func clampedPage(_ page: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(max(page, 0), count - 1)
}

/// Cardinal HUD tab strip — chamfer tab buttons, the selected tab lit with an
/// accent fill and a glowing underline tick, materializing in on selection
/// change. Reads colors from `@Environment(\.ainkradTheme)`.
public struct AinkradTabs<T: Hashable>: View {
    private let tabs: [T]
    @Binding private var selection: T
    private let label: (T) -> String
    /// Set by `textTabs()`.
    var usesTextTabs = false

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(tabs: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.tabs = tabs
        self._selection = selection
        self.label = label
    }

    /// Plain text tabs, as Forge's sidebar draws "Files  Changes 2  Search
    /// Issues 5" (mockup 01): under Neon 11 pt muted text with the selected
    /// tab in the foreground on a faint pill; under Glass one glass capsule
    /// whose tabs share its width, the selected one a light pill. Labels keep
    /// their case; put a count in the label.
    public func textTabs() -> Self {
        var copy = self
        copy.usesTextTabs = true
        return copy
    }

    private func select(_ tab: T) {
        if reduceMotion {
            selection = tab
        } else {
            withAnimation(AinkradMotion.materialize) { selection = tab }
        }
    }

    public var body: some View {
        if usesTextTabs {
            AinkradTextTabRow(titles: tabs.map(label), selected: tabs.firstIndex(of: selection)) { select(tabs[$0]) }
        } else {
            HStack(spacing: skin.spacing.xs) {
                ForEach(tabs, id: \.self) { tab in
                    AinkradTabButton(title: label(tab), isSelected: tab == selection) { select(tab) }
                }
            }
            .padding(skin.spacing.xs / 2)
        }
    }
}

/// `AinkradTabs.textTabs()`: the mockup's `.side-tabs`.
private struct AinkradTextTabRow: View {
    let titles: [String]
    let selected: Int?
    let onSelect: (Int) -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovered: Int?

    private var isGlass: Bool {
        if #available(macOS 26, *) { return skin.usesNativeGlass }
        return false
    }

    var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            row.padding(skin.size.s3).glassEffect(.regular, in: .capsule)
        } else {
            row
        }
    }

    private var row: some View {
        HStack(spacing: isGlass ? skin.size.s2 : skin.size.s4) {
            ForEach(titles.indices, id: \.self) { index in tab(index) }
        }
    }

    private func tab(_ index: Int) -> some View {
        let isSelected = index == selected
        return Button {
            onSelect(index)
        } label: {
            Text(titles[index])
                .font(AinkradFontResolver.font(size: 11, typography: typo))
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(
                    isSelected || hovered == index ? theme.foreground : theme.foreground.opacity(skin.opacity.o55)
                )
                .padding(.horizontal, skin.size.s8).padding(.vertical, skin.size.s4)
                .frame(maxWidth: isGlass ? .infinity : nil)
                .background { pill(isSelected) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 ? index : (hovered == index ? nil : hovered) }
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: hovered)
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: selected)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder private func pill(_ isSelected: Bool) -> some View {
        if isGlass {
            Capsule().fill(theme.foreground.opacity(isSelected ? skin.opacity.o20 : 0))
        } else {
            RoundedRectangle(cornerRadius: skin.size.s6)
                .fill(isSelected ? theme.surfaceElevated.opacity(skin.opacity.o60) : .clear)
        }
    }
}

/// A single chamfer tab button — extracted so `AinkradTabs` stays a plain
/// `ForEach` and each tab owns its own hover state.
private struct AinkradTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        let tabs = skin.components.tabs
        let tick = skin.roles.accentTick
        let shape = AinkradSkinShape(token: tabs.shape)
        var state: AinkradControlState = []
        if isSelected { state.insert(.selected) }
        if hovering { state.insert(.hover) }

        return Button(action: action) {
            VStack(spacing: tabs.labelGap) {
                Text(skin.labelCased(title))
                    .font(skin.font(tabs.labelFont, typography: typo))
                    .tracking(tabs.labelFont.tracking ?? 0)
                    .foregroundStyle(
                        isSelected
                            ? skin.color(skin.palette.accentPrimary).contrastingText
                            : skin.color(tabs.fg, state: hovering ? [.hover] : [])
                    )
                Rectangle()
                    .fill(skin.color(tick.fill))
                    .frame(height: tabs.tickHeight)
                    .opacity(isSelected ? 1 : 0)
                    .shadow(
                        color: skin.color(tick.glow.color, state: isSelected ? [.selected] : []),
                        radius: tick.glow.radius.rest)
            }
            .padding(.horizontal, skin.spacing.md)
            .padding(.vertical, skin.spacing.sm)
            .background(shape.fill(skin.color(tabs.fill, state: state)))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !isSelected && !reduceMotion ? tabs.hoverScale : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// HUD breadcrumb trail — crumbs separated by a small glowing chevron glyph
/// (never a divider line, per the Cardinal HUD "no separator lines" rule).
/// The trailing crumb reads as the current location (accent, not tappable);
/// earlier crumbs invoke `onSelect(index)` when supplied.
public struct AinkradBreadcrumb: View {
    private let items: [String]
    private let onSelect: ((Int) -> Void)?
    /// Set by `preservesCase()`.
    var keepsCase = false
    /// Set by `icon(at:_:)`: one leading glyph before the crumb at `index`.
    var segmentIcon: (index: Int, view: AnyView)?
    /// Set by `segmentColors(_:)`.
    var segmentColor: ((Int) -> Color?)?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(items: [String], onSelect: ((Int) -> Void)? = nil) {
        self.items = items
        self.onSelect = onSelect
    }

    /// Crumbs as written, untracked — a path reads `Sources › SidebarRow.swift`,
    /// not Neon's `SOURCES › SIDEBARROW.SWIFT` (the Forge mockup's editor
    /// breadcrumb). Without it the crumbs follow the skin's label case.
    public func preservesCase() -> Self {
        var copy = self
        copy.keepsCase = true
        return copy
    }

    /// Draws `icon` just before the crumb at `index`, e.g. the file-type glyph
    /// before the file segment of an editor breadcrumb. One icon per trail.
    public func icon<Icon: View>(at index: Int, @ViewBuilder _ icon: () -> Icon) -> Self {
        var copy = self
        copy.segmentIcon = (index, AnyView(icon()))
        return copy
    }

    /// Colours each crumb by index — `nil` keeps the plain crumb colour — and
    /// stops the trailing crumb being drawn as the accent "current" one: the
    /// editor breadcrumb's file name in the foreground and its type symbol in
    /// the syntax colour, the member after it plain (Forge mockup 01).
    public func segmentColors(_ color: @escaping (Int) -> Color?) -> Self {
        var copy = self
        copy.segmentColor = color
        return copy
    }

    public var body: some View {
        let bread = skin.components.breadcrumb
        HStack(spacing: skin.spacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isLast = index == items.count - 1
                if let segmentIcon, segmentIcon.index == index { segmentIcon.view }
                crumb(item, isLast: isLast, index: index, bread: bread)
                if !isLast {
                    Image(systemName: "chevron.compact.right")
                        .font(skin.font(bread.chevronFont, typography: typo))
                        .foregroundStyle(skin.color(bread.chevronColor))
                }
            }
        }
    }

    @ViewBuilder
    private func crumb(_ text: String, isLast: Bool, index: Int, bread: BreadcrumbTokens) -> some View {
        let isCurrent = isLast && segmentColor == nil
        let labelFontToken = isCurrent ? bread.activeFont : bread.font
        let label = Text(keepsCase ? text : skin.labelCased(text))
            .font(skin.font(labelFontToken, typography: typo))
            .tracking(keepsCase ? 0 : labelFontToken.tracking ?? 0.6)
            .foregroundStyle(
                segmentColor?(index) ?? skin.color(isCurrent ? bread.activeColor : bread.itemColor))

        if let onSelect, !isLast {
            Button {
                onSelect(index)
            } label: {
                label
            }
            .buttonStyle(.plain)
        } else {
            label
        }
    }
}

/// HP-bar-adjacent pager: chamfer prev/next arrows flanking small page-marker
/// dots, the current page lit with the theme's primary accent glow.
public struct AinkradPagination: View {
    @Binding private var page: Int
    private let pageCount: Int

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(page: Binding<Int>, pageCount: Int) {
        self._page = page
        self.pageCount = pageCount
    }

    public var body: some View {
        let pag = skin.components.pagination
        HStack(spacing: skin.spacing.sm) {
            pagerButton(systemName: "chevron.left", enabled: page > 0) {
                page = clampedPage(page - 1, count: pageCount)
            }
            HStack(spacing: skin.spacing.xs) {
                ForEach(0..<max(pageCount, 0), id: \.self) { index in
                    let isCurrent = index == page
                    Circle()
                        .fill(skin.color(isCurrent ? pag.currentFill : pag.dotFill))
                        .frame(
                            width: isCurrent ? pag.currentDotSize : pag.dotSize,
                            height: isCurrent ? pag.currentDotSize : pag.dotSize
                        )
                        .shadow(
                            color: skin.color(pag.currentGlow.color, state: isCurrent ? [.selected] : []),
                            radius: pag.currentGlow.radius.resolve(isCurrent ? [.selected] : [])
                        )
                        .onTapGesture { page = clampedPage(index, count: pageCount) }
                }
            }
            .animation(reduceMotion ? nil : AinkradMotion.hover, value: page)
            pagerButton(systemName: "chevron.right", enabled: page < pageCount - 1) {
                page = clampedPage(page + 1, count: pageCount)
            }
        }
    }

    private func pagerButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        let pag = skin.components.pagination
        return AinkradIconButton(systemName: systemName, action: action)
            .opacity(enabled ? 1 : pag.disabledOpacity)
            .allowsHitTesting(enabled)
    }
}
