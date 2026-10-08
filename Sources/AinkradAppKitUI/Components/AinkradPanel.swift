import AinkradAppKitContract
import AppKit
import SwiftUI

/// The shared HUD panel finish: blur backing + translucent theme background +
/// skin-shaped clip (`shape.style`) + luminous accent stroke + optional corner brackets +
/// elevation glow. Generalizes the host's `hudPanelChrome`. Reads the theme
/// from `@Environment(\.ainkradTheme)`.
public struct AinkradPanel<Content: View>: View {
    private let blur: AinkradBlurLevel
    private let blending: NSVisualEffectView.BlendingMode
    /// Nil: the skin's `material.panelOpacity`.
    private let backgroundOpacity: Double?
    private let showsBrackets: Bool
    private let content: Content
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradSkin) private var skin
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
    /// - Parameter backgroundOpacity: overrides the skin's `material.panelOpacity`.
    public init(
        blur: AinkradBlurLevel = .panel,
        blending: NSVisualEffectView.BlendingMode = .withinWindow,
        backgroundOpacity: Double = 0.94,
        showsBrackets: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.init(blur, blending, backgroundOpacity, showsBrackets, content)
    }

    /// The fill follows the skin's `material.panelOpacity`. An overload, not a
    /// change to the init above: that symbol is linked by installed plugins,
    /// and its 0.94 default cannot be told apart from an explicit 0.94.
    public init(
        blur: AinkradBlurLevel = .panel,
        blending: NSVisualEffectView.BlendingMode = .withinWindow,
        showsBrackets: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.init(blur, blending, nil, showsBrackets, content)
    }

    private init(
        _ blur: AinkradBlurLevel, _ blending: NSVisualEffectView.BlendingMode, _ backgroundOpacity: Double?,
        _ showsBrackets: Bool, _ content: () -> Content
    ) {
        self.blur = blur
        self.blending = blending
        self.backgroundOpacity = backgroundOpacity
        self.showsBrackets = showsBrackets
        self.content = content()
    }
    public var body: some View {
        let p = skin.components.panel
        content
            .background {
                ZStack {
                    // Skipped rather than made transparent: an inactive
                    // NSVisualEffectView still costs a backdrop sample, and a
                    // user who turned blur off is usually asking for the cost
                    // back as much as for the look.
                    if surfaceBlur { AinkradMaterialBackground(level: blur, blending: blending) }
                    theme.background.opacity(surfaceOpacity ?? backgroundOpacity ?? skin.material.panelOpacity)
                }
            }
            .clipShape(skin.shape(cut: AinkradRadius.panel))
            .overlay(
                skin.shape(cut: AinkradRadius.panel)
                    .strokeBorder(skin.color(p.stroke.color), lineWidth: p.stroke.width.resolve([]))
            )
            .apply { showsBrackets ? AnyView($0.cornerBrackets()) : AnyView($0) }
            // Outer accent halo + contact shadow so every panel reads as
            // glowing (the radial `.glowBloom()` sat behind the opaque
            // background and was invisible). Matches the previous overlay bloom.
            .ainkradPanelGlow()
    }
}

extension View {
    public func ainkradPanel(
        blur: AinkradBlurLevel = .panel,
        blending: NSVisualEffectView.BlendingMode = .withinWindow,
        backgroundOpacity: Double = 0.94,
        showsBrackets: Bool = false
    ) -> some View {
        AinkradPanel(
            blur: blur, blending: blending, backgroundOpacity: backgroundOpacity,
            showsBrackets: showsBrackets
        ) { self }
    }

    /// The fill follows the skin's `material.panelOpacity` (see `AinkradPanel`).
    public func ainkradPanel(
        blur: AinkradBlurLevel = .panel,
        blending: NSVisualEffectView.BlendingMode = .withinWindow,
        showsBrackets: Bool = false
    ) -> some View {
        AinkradPanel(blur: blur, blending: blending, showsBrackets: showsBrackets) { self }
    }
}
