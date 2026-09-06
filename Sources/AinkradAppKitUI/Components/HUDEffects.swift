import SwiftUI
import AinkradAppKitContract

/// Faint horizontal scanline sweep — a HUD "scan" texture. Animated via
/// `TimelineView` only while `active` and motion isn't reduced; otherwise a
/// static (or omitted) faint line pattern, kept very low-opacity so it never
/// competes with content.
private struct ScanlineOverlayModifier: ViewModifier {
    var active: Bool
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay(scanlines.allowsHitTesting(false))
    }

    @ViewBuilder
    private var scanlines: some View {
        if active {
            if reduceMotion {
                Canvas { context, size in Self.drawStaticLines(context, size) }
                    .opacity(0.05)
            } else {
                BudgetedTimelineView { date in
                    Canvas { context, size in
                        Self.drawMovingBand(context, size, time: date.timeIntervalSinceReferenceDate)
                    }
                }
                .opacity(0.08)
            }
        }
    }

    private static func drawStaticLines(_ context: GraphicsContext, _ size: CGSize) {
        var y: CGFloat = 0
        while y < size.height {
            context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.white))
            y += 4
        }
    }

    private static func drawMovingBand(_ context: GraphicsContext, _ size: CGSize, time: Double) {
        let period = 3.5
        let progress = (time.truncatingRemainder(dividingBy: period)) / period
        let bandHeight: CGFloat = size.height * 0.12
        let y = CGFloat(progress) * (size.height + bandHeight) - bandHeight
        let gradient = Gradient(colors: [.clear, .white.opacity(0.6), .clear])
        context.fill(
            Path(CGRect(x: 0, y: y, width: size.width, height: bandHeight)),
            with: .linearGradient(gradient, startPoint: CGPoint(x: 0, y: y),
                                  endPoint: CGPoint(x: 0, y: y + bandHeight))
        )
    }
}

/// Low-opacity hexagon grid painted behind the content — a static texture
/// (no per-frame work), so it renders identically regardless of Reduce
/// Motion. Omitted entirely when `active` is false.
private struct HexGridBackgroundModifier: ViewModifier {
    var active: Bool
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.background(hexGrid.allowsHitTesting(false))
    }

    @ViewBuilder
    private var hexGrid: some View {
        if active {
            Canvas { context, size in Self.draw(context, size) }
                .opacity(reduceMotion ? 0.04 : 0.05)
        }
    }

    private static func draw(_ context: GraphicsContext, _ size: CGSize) {
        let hexRadius: CGFloat = 14
        let hexWidth = sqrt(3) * hexRadius
        let vertSpacing = hexRadius * 1.5
        var row = 0
        var y: CGFloat = 0
        while y < size.height + hexRadius * 2 {
            let xOffset = row.isMultiple(of: 2) ? 0 : hexWidth / 2
            var x: CGFloat = xOffset
            while x < size.width + hexWidth {
                context.stroke(hexPath(center: CGPoint(x: x, y: y), radius: hexRadius),
                                with: .color(.white), lineWidth: 0.5)
                x += hexWidth
            }
            y += vertSpacing
            row += 1
        }
    }

    private static func hexPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        for i in 0..<6 {
            let angle = Angle(degrees: Double(i) * 60 - 30).radians
            let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// Soft radial accent glow behind the content, using the host theme's
/// primary accent. A static gradient (nothing to animate), so it's
/// unaffected by Reduce Motion; only `active` gates it.
private struct GlowBloomModifier: ViewModifier {
    var active: Bool
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.background(glow.allowsHitTesting(false))
    }

    @ViewBuilder
    private var glow: some View {
        if active {
            RadialGradient(
                colors: [theme.accentPrimary.opacity(reduceMotion ? 0.16 : 0.20), .clear],
                center: .center, startRadius: 0, endRadius: 140
            )
        }
    }
}

public extension View {
    /// Faint moving scanline sweep (Cardinal HUD "scan" texture). Disabled
    /// (falls back to a static faint line pattern) under Reduce Motion, and
    /// fully omitted when `active` is false.
    func scanlineOverlay(active: Bool = true) -> some View {
        modifier(ScanlineOverlayModifier(active: active))
    }

    /// Low-opacity hexagon grid background texture.
    func hexGridBackground(active: Bool = true) -> some View {
        modifier(HexGridBackgroundModifier(active: active))
    }

    /// Soft radial accent glow behind the content, using `ainkradTheme.accentPrimary`.
    func glowBloom(active: Bool = true) -> some View {
        modifier(GlowBloomModifier(active: active))
    }
}
