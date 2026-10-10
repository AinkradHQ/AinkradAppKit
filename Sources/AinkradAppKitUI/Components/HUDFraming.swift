import AinkradAppKitContract
import SwiftUI

/// The targeting-bracket shape — four L-shaped corner brackets, the Cardinal
/// HUD "targeting frame" motif drawn by the host Launcher and others. A `Shape`,
/// not a `View`, so call sites can stroke, shadow and inset it like any path.
/// Carries no tokens: call sites stroke it with color and shape tokens (see
/// `View.cornerBrackets(_:_:)`).
public struct AinkradCornerBrackets: Shape {
    /// Length of each bracket arm.
    public var length: CGFloat

    public init(length: CGFloat = 8) {
        self.length = length
    }

    public func path(in rect: CGRect) -> Path {
        let l = max(0, min(length, min(rect.width, rect.height) / 2))
        var path = Path()

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))

        return path
    }
}

private struct CornerBracketsModifier: ViewModifier {
    var length: CGFloat
    var inset: CGFloat
    @Environment(\.ainkradSkin) private var skin

    func body(content: Content) -> some View {
        let b = skin.effects.brackets
        content.overlay(
            AinkradCornerBrackets(length: length)
                .stroke(skin.color(b.stroke), lineWidth: b.width)
                .shadow(color: skin.color(b.glow), radius: b.glowRadius)
                .padding(inset)
                .allowsHitTesting(false)
        )
    }
}

extension View {
    /// Overlays luminous L-shaped accent brackets at the view's four corners —
    /// the Cardinal HUD "targeting frame" motif. Reads `accentSecondary` from
    /// the host theme. `inset` pulls the brackets in from the view's edge.
    public func cornerBrackets(length: CGFloat = 12, inset: CGFloat = 0) -> some View {
        modifier(CornerBracketsModifier(length: length, inset: inset))
    }
}

/// A short HUD-style accent tick, optionally labeled — NOT a full-width
/// divider. Cardinal HUD never uses plain separator lines; this is the
/// replacement: a glowing accent mark plus small uppercase, tracked caption.
public struct AccentRule: View {
    public var label: String?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typography

    public init(label: String? = nil) {
        self.label = label
    }

    public var body: some View {
        let rule = skin.effects.accentRule
        let tick = skin.roles.accentTick
        HStack(spacing: AinkradSpacing.xs) {
            Rectangle()
                .fill(skin.color(tick.fill))
                .frame(width: rule.width, height: rule.height)
                .shadow(color: skin.color(tick.glow.color.rest), radius: tick.glow.radius.rest)

            if let label {
                Text(skin.labelCased(label))
                    .font(AinkradFontResolver.font(.caption, typography: typography))
                    .tracking(rule.labelFont.tracking ?? 0)
                    .foregroundStyle(skin.color(rule.labelColor))
            }
        }
        .fixedSize()
    }
}
