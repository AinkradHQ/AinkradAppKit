import SwiftUI

/// An inline disclosure: a tappable title row that expands to reveal its
/// content in place. Distinct from `AinkradDrawer`, which is a slide-in
/// overlay panel with a dimmed backdrop — this one never leaves the flow.
///
/// Expansion is caller-owned via a `Binding` so the parent can restore it,
/// deep-link into it, or force it open when a search filter matches inside.
public struct AinkradDisclosureGroup<Content: View>: View {
    public let title: String
    public let isExpanded: Binding<Bool>
    /// Matches inside this group while a filter is active; 0 hides the badge.
    public let hitCount: Int
    private let content: Content

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var isHovered = false

    public init(
        title: String,
        isExpanded: Binding<Bool>,
        hitCount: Int = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isExpanded = isExpanded
        self.hitCount = hitCount
        self.content = content()
    }

    public static func chevron(isExpanded: Bool) -> String {
        isExpanded ? "chevron.down" : "chevron.right"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.sm) {
            Button {
                isExpanded.wrappedValue.toggle()
            } label: {
                HStack(spacing: AinkradSpacing.xs) {
                    Image(systemName: Self.chevron(isExpanded: isExpanded.wrappedValue))
                        // SF Symbol glyph sizing.
                        .font(.system(size: 10))
                        .foregroundStyle(theme.foreground.opacity(0.5))
                    Text(title.uppercased())
                        .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.7))
                        .tracking(1.2)
                    if hitCount > 0 {
                        AinkradBadge(text: "\(hitCount)", tint: theme.accentSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, AinkradSpacing.xs)
                .padding(.horizontal, AinkradSpacing.sm)
                .background(
                    ChamferShape(cut: AinkradRadius.sm)
                        .fill(theme.surfaceElevated.opacity(isHovered ? 0.5 : 0))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: AinkradMotion.durationFast), value: isHovered)

            if isExpanded.wrappedValue {
                content
                    .padding(.leading, AinkradSpacing.sm)
                    .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .animation(
            reduceMotion ? nil : .easeOut(duration: AinkradMotion.durationBase),
            value: isExpanded.wrappedValue)
    }
}
