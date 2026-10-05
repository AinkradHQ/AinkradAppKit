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

    @Environment(\.ainkradSkin) private var skin
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
        let group = skin.components.disclosureGroup
        let shape = AinkradSkinShape(token: group.headerShape)
        VStack(alignment: .leading, spacing: skin.spacing.sm) {
            Button {
                isExpanded.wrappedValue.toggle()
            } label: {
                HStack(spacing: skin.spacing.xs) {
                    Image(systemName: Self.chevron(isExpanded: isExpanded.wrappedValue))
                        // SF Symbol glyph sizing.
                        .font(skin.font(group.chevronFont, typography: typo))
                        .foregroundStyle(skin.color(group.chevronColor))
                    Text(title.uppercased())
                        .font(skin.font(group.titleFont, typography: typo))
                        .foregroundStyle(skin.color(group.titleColor))
                        .tracking(group.titleFont.tracking ?? 0)
                    if hitCount > 0 {
                        AinkradBadge(text: "\(hitCount)", tint: skin.color(skin.palette.accentSecondary))
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, skin.spacing.xs)
                .padding(.horizontal, skin.spacing.sm)
                .background(
                    shape
                        .fill(skin.color(group.headerFill, state: state))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHovered = $0 }
            .animation(reduceMotion ? nil : skin.animation(group.hoverAnimation), value: isHovered)

            if isExpanded.wrappedValue {
                content
                    .padding(.leading, skin.spacing.sm)
                    .transition(reduceMotion ? .identity : .opacity)
            }
        }
        .animation(
            reduceMotion ? nil : skin.animation(group.expandAnimation),
            value: isExpanded.wrappedValue)
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if isHovered { state.insert(.hover) }
        return state
    }
}
