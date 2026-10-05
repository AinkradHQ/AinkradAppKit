import AinkradAppKitContract
import SwiftUI

/// Titled chamfer-bordered container — an accent-tick, uppercase-title header
/// atop a chamfered-border body. No separator line between header and body;
/// the accent tick + spacing carry that distinction instead.
public struct AinkradSectionFrame<Content: View>: View {
    private let title: String
    private let content: Content

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        let frame = skin.components.sectionFrame
        let tick = skin.roles.accentTick
        let shape = AinkradSkinShape(token: frame.bodyShape)
        VStack(alignment: .leading, spacing: AinkradSpacing.sm) {
            HStack(spacing: AinkradSpacing.xs) {
                Rectangle()
                    .fill(skin.color(tick.fill))
                    .frame(width: frame.tickWidth, height: frame.tickHeight)
                    .shadow(color: skin.color(tick.glow.color.rest), radius: tick.glow.radius.rest)
                Text(title.uppercased())
                    .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                    .foregroundStyle(skin.color(frame.titleColor))
                    .tracking(frame.titleFont.tracking ?? 0)
            }
            content
        }
        .padding(AinkradSpacing.md)
        .background(shape.fill(skin.color(frame.bodyFill)))
        .overlay(shape.strokeBorder(skin.color(frame.bodyStroke.color), lineWidth: frame.bodyStroke.width.resolve([])))
    }
}
