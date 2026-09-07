import SwiftUI
import AppKit
import AinkradAppKitContract

/// The shared HUD panel finish: blur backing + translucent theme background +
/// chamfered clip + luminous accent stroke + optional corner brackets +
/// elevation glow. Generalizes the host's `hudPanelChrome`. Reads the theme
/// from `@Environment(\.ainkradTheme)`.
public struct AinkradPanel<Content: View>: View {
    private let blur: AinkradBlurLevel
    private let blending: NSVisualEffectView.BlendingMode
    private let backgroundOpacity: Double
    private let showsBrackets: Bool
    private let content: Content
    @Environment(\.ainkradTheme) private var theme
    /// Settings → Appearance → Overlays, injected by the host. Nil means the
    /// host has not spoken, so the call site's own choice stands.
    @Environment(\.ainkradSurfaceOpacity) private var surfaceOpacity
    @Environment(\.ainkradSurfaceBlur) private var surfaceBlur

    /// - Parameter blending: how the blur samples what it sits over.
    ///   `.withinWindow` — the default, and right for a panel drawn INSIDE the
    ///   app window — blurs the content behind it in that same window. A panel
    ///   hosted in its own `NSPanel` (anything presented through
    ///   `View.ainkradFloatingPanel(...)`) has nothing behind it within that
    ///   window, so a `.withinWindow` blur has nothing to sample and renders as
    ///   a flat fill: the panel reads as an opaque slab rather than glass.
    ///   Those need `.behindWindow`.
    public init(blur: AinkradBlurLevel = .panel,
                blending: NSVisualEffectView.BlendingMode = .withinWindow,
                backgroundOpacity: Double = 0.94,
                showsBrackets: Bool = false,
                @ViewBuilder content: () -> Content) {
        self.blur = blur; self.blending = blending
        self.backgroundOpacity = backgroundOpacity
        self.showsBrackets = showsBrackets; self.content = content()
    }
    public var body: some View {
        content
            .background {
                ZStack {
                    // Skipped rather than made transparent: an inactive
                    // NSVisualEffectView still costs a backdrop sample, and a
                    // user who turned blur off is usually asking for the cost
                    // back as much as for the look.
                    if surfaceBlur { VisualEffectBlur(level: blur, blendingMode: blending) }
                    theme.background.opacity(surfaceOpacity ?? backgroundOpacity)
                }
            }
            .clipShape(ChamferShape(cut: AinkradRadius.panel))
            .overlay(
                ChamferShape(cut: AinkradRadius.panel)
                    .strokeBorder(theme.accentSecondary.opacity(0.4), lineWidth: 1)
            )
            .apply { showsBrackets ? AnyView($0.cornerBrackets()) : AnyView($0) }
            // Outer accent halo + contact shadow so every panel reads as
            // glowing (the radial `.glowBloom()` sat behind the opaque
            // background and was invisible). Matches the previous overlay bloom.
            .ainkradPanelGlow()
    }
}

public extension View {
    func ainkradPanel(blur: AinkradBlurLevel = .panel,
                       blending: NSVisualEffectView.BlendingMode = .withinWindow,
                       backgroundOpacity: Double = 0.94,
                       showsBrackets: Bool = false) -> some View {
        AinkradPanel(blur: blur, blending: blending, backgroundOpacity: backgroundOpacity,
                     showsBrackets: showsBrackets) { self }
    }
}
