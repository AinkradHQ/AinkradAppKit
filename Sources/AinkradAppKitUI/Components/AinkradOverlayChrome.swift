import AinkradAppKitContract
import AppKit
import SwiftUI

/// The shared panel finish: a translucent + optionally blurred background,
/// chamfered clip, and the Cardinal HUD edge-ring + panel glow. Applied to a
/// summoned overlay's outermost panel container. Opacity and blur come from the
/// caller when set, otherwise from the skin's overlay and material tokens.
private struct AinkradOverlayChromeModifier: ViewModifier {
    let backgroundOpacity: Double?
    let blurEnabled: Bool?
    /// How the blur samples what it sits over.
    ///
    /// `.withinWindow` is right for an overlay drawn INSIDE the app window —
    /// it blurs the app content behind it. A panel hosted in its own
    /// `NSPanel` (anything presented via `ainkradFloatingPanel`) has nothing
    /// behind it within that window, so the blur renders as a flat fill and
    /// the panel reads opaque; those need `.behindWindow`.
    let blending: NSVisualEffectView.BlendingMode
    @Environment(\.ainkradSkin) private var skin

    func body(content: Content) -> some View {
        let overlay = skin.chrome.overlay
        content
            .background {
                ZStack {
                    if blurEnabled ?? skin.material.blurEnabled {
                        AinkradMaterialBackground(blending: blending)
                    }
                    skin.color(skin.palette.background).opacity(backgroundOpacity ?? overlay.backgroundOpacity)
                }
            }
            .clipShape(skin.shape(cut: skin.radius.panel))
            // Accent border must follow the panel SHAPE (the SDK `.ainkradEdgeRing`
            // strokes the same shape, but this gradient is the overlay's own
            // token pair), so the frame reads as Cardinal HUD.
            .overlay(
                skin.shape(cut: skin.radius.panel)
                    .strokeBorder(
                        LinearGradient(
                            colors: [skin.color(overlay.edgeFrom), skin.color(overlay.edgeTo)],
                            startPoint: .top, endPoint: .bottom),
                        lineWidth: overlay.edgeWidth)
            )
            .ainkradPanelGlow()
    }
}

extension View {
    /// Opacity and blur from the skin's overlay and material tokens.
    public func ainkradOverlayChrome(blending: NSVisualEffectView.BlendingMode) -> some View {
        modifier(AinkradOverlayChromeModifier(backgroundOpacity: nil, blurEnabled: nil, blending: blending))
    }

    /// Explicit values, for the host's user-set overlay opacity and blur toggle.
    public func ainkradOverlayChrome(
        backgroundOpacity: Double, blurEnabled: Bool, blending: NSVisualEffectView.BlendingMode
    ) -> some View {
        modifier(
            AinkradOverlayChromeModifier(
                backgroundOpacity: backgroundOpacity, blurEnabled: blurEnabled, blending: blending))
    }
}
