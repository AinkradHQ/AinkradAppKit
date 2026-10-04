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

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(tabs: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.tabs = tabs
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        HStack(spacing: AinkradSpacing.xs) {
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
        .padding(AinkradSpacing.xs / 2)
    }
}

/// A single chamfer tab button — extracted so `AinkradTabs` stays a plain
/// `ForEach` and each tab owns its own hover state.
private struct AinkradTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(title.uppercased())
                    .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                    .tracking(0.8)
                    .foregroundStyle(
                        isSelected
                            ? theme.accentPrimary.contrastingText : theme.foreground.opacity(hovering ? 0.9 : 0.6))
                Rectangle()
                    .fill(theme.accentSecondary)
                    .frame(height: 2)
                    .opacity(isSelected ? 1 : 0)
                    .shadow(color: theme.accentSecondary.opacity(isSelected ? 0.6 : 0), radius: 2)
            }
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(
                ChamferShape(cut: 6)
                    .fill(
                        isSelected
                            ? theme.accentPrimary.opacity(0.85) : theme.surfaceElevated.opacity(hovering ? 0.5 : 0.25))
            )
            .contentShape(ChamferShape(cut: 6))
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !isSelected && !reduceMotion ? 1.02 : 1.0)
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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(items: [String], onSelect: ((Int) -> Void)? = nil) {
        self.items = items
        self.onSelect = onSelect
    }

    public var body: some View {
        HStack(spacing: AinkradSpacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let isLast = index == items.count - 1
                crumb(item, isLast: isLast, index: index)
                if !isLast {
                    Image(systemName: "chevron.compact.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.accentSecondary.opacity(0.55))
                }
            }
        }
    }

    @ViewBuilder
    private func crumb(_ text: String, isLast: Bool, index: Int) -> some View {
        let label = Text(text.uppercased())
            .font(AinkradFontResolver.font(.caption, weight: isLast ? .semibold : .regular, typography: typo))
            .tracking(0.6)
            .foregroundStyle(isLast ? theme.accentSecondary : theme.foreground.opacity(0.6))

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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(page: Binding<Int>, pageCount: Int) {
        self._page = page
        self.pageCount = pageCount
    }

    public var body: some View {
        HStack(spacing: AinkradSpacing.sm) {
            pagerButton(systemName: "chevron.left", enabled: page > 0) {
                page = clampedPage(page - 1, count: pageCount)
            }
            HStack(spacing: AinkradSpacing.xs) {
                ForEach(0..<max(pageCount, 0), id: \.self) { index in
                    let isCurrent = index == page
                    Circle()
                        .fill(isCurrent ? theme.accentPrimary : theme.foreground.opacity(0.25))
                        .frame(width: isCurrent ? 8 : 6, height: isCurrent ? 8 : 6)
                        .shadow(color: theme.accentPrimary.opacity(isCurrent ? 0.6 : 0), radius: 3)
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
        AinkradIconButton(systemName: systemName, action: action)
            .opacity(enabled ? 1 : 0.3)
            .allowsHitTesting(enabled)
    }
}
