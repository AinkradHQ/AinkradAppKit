import AinkradAppKitContract
import AppKit
import SwiftUI

public enum AinkradBlurLevel: Equatable, Sendable {
    case panel, hud
    public var material: NSVisualEffectView.Material {
        switch self {
        case .panel: return .hudWindow
        case .hud: return .fullScreenUI
        }
    }
}

/// Blurs the app content behind the view. Ported from the host so plugins get
/// the identical panel backing.
///
/// `blendingMode` defaults to `.withinWindow` (blur other layers within this
/// same window — the usual in-app panel look) but a modal presented in its
/// own top-level window (e.g. a floating panel from
/// `View.ainkradFloatingPanel(...)`) needs `.behindWindow` instead, so it
/// samples the parent window's content sitting behind it rather than its own
/// near-empty panel window.
public struct VisualEffectBlur: NSViewRepresentable {
    public var level: AinkradBlurLevel = .panel
    public var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    public init(level: AinkradBlurLevel = .panel, blendingMode: NSVisualEffectView.BlendingMode = .withinWindow) {
        self.level = level
        self.blendingMode = blendingMode
    }
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = level.material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }
    public func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = level.material
        v.blendingMode = blendingMode
    }
}

private struct EdgeRing: ViewModifier {
    let radius: CGFloat
    @Environment(\.ainkradTheme) private var theme
    func body(content: Content) -> some View {
        content.overlay(
            ChamferShape(cut: radius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.accentSecondary.opacity(0.45),
                            theme.accentPrimary.opacity(0.18),
                        ],
                        startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
        )
    }
}

private struct PanelGlow: ViewModifier {
    @Environment(\.ainkradTheme) private var theme
    func body(content: Content) -> some View {
        content
            // Match the established overlay bloom (previously host `hudPanelChrome`):
            // a wide accent halo + a deep contact shadow, so overlays read as
            // glowing like the Launcher/App Store panels.
            .shadow(color: theme.accentPrimary.opacity(0.35), radius: 42)
            .shadow(color: .black.opacity(0.5), radius: 24, y: 10)
    }
}

extension View {
    /// The shared 1-pt gradient edge highlight used by panels and cards.
    public func ainkradEdgeRing(radius: CGFloat = AinkradRadius.panel) -> some View {
        modifier(EdgeRing(radius: radius))
    }
    /// The shared two-layer accent glow + contact shadow for elevated panels.
    public func ainkradPanelGlow() -> some View { modifier(PanelGlow()) }
}
