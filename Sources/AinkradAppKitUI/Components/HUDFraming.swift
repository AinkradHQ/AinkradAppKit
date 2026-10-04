import AinkradAppKitContract
import SwiftUI

/// Draws the four L-shaped corner brackets used by `View.cornerBrackets(_:_:)`.
/// A `Shape`, not a `View`, so it can be stroked/shadowed like any path.
private struct CornerBracketsShape: Shape {
    var length: CGFloat

    func path(in rect: CGRect) -> Path {
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
    @Environment(\.ainkradTheme) private var theme

    func body(content: Content) -> some View {
        content.overlay(
            CornerBracketsShape(length: length)
                .stroke(theme.accentSecondary, lineWidth: 1.25)
                .shadow(color: theme.accentSecondary.opacity(0.55), radius: 2.5)
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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typography

    public init(label: String? = nil) {
        self.label = label
    }

    public var body: some View {
        HStack(spacing: AinkradSpacing.xs) {
            Rectangle()
                .fill(theme.accentSecondary)
                .frame(width: 18, height: 2)
                .shadow(color: theme.accentSecondary.opacity(0.6), radius: 2)

            if let label {
                Text(label.uppercased())
                    .font(AinkradFontResolver.font(.caption, typography: typography))
                    .tracking(1.5)
                    .foregroundStyle(theme.foreground.opacity(0.7))
            }
        }
        .fixedSize()
    }
}
