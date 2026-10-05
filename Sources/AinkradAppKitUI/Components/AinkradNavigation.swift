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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(tabs: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.tabs = tabs
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        HStack(spacing: skin.spacing.xs) {
            ForEach(tabs, id: \.self) { tab in
                AinkradTabButton(title: label(tab), isSelected: tab == selection) {
                    if reduceMotion {
                        selection = tab
                    } else {
                        withAnimation(AinkradMotion.materialize) { selection = tab }
                    }
                }
            }
        }
        .padding(skin.spacing.xs / 2)
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
                Text(title.uppercased())
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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(items: [String], onSelect: ((Int) -> Void)? = nil) {
        self.items = items
        self.onSelect = onSelect
    }

    public var body: some View {
        let bread = skin.components.breadcrumb
        HStack(spacing: skin.spacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isLast = index == items.count - 1
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
        let labelFontToken = isLast ? bread.activeFont : bread.font
        let label = Text(text.uppercased())
            .font(skin.font(labelFontToken, typography: typo))
            .tracking(labelFontToken.tracking ?? 0.6)
            .foregroundStyle(skin.color(isLast ? bread.activeColor : bread.itemColor))

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
