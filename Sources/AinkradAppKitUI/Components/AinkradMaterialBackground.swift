import AppKit
import SwiftUI

/// The material behind a kit surface, in the skin's `material.kind` language:
/// `blur` is `VisualEffectBlur`, `glass` is native glass on macOS 26+ (blur
/// before), `solid` draws nothing so the surface's own opaque fill shows.
/// An unknown kind renders as `blur`.
public struct AinkradMaterialBackground: View {
    private let level: AinkradBlurLevel
    private let blending: NSVisualEffectView.BlendingMode
    @Environment(\.ainkradSkin) private var skin

    public init(level: AinkradBlurLevel = .panel, blending: NSVisualEffectView.BlendingMode = .withinWindow) {
        self.level = level
        self.blending = blending
    }

    public var body: some View {
        switch skin.material.kind {
        case "solid":
            EmptyView()
        case "glass":
            if #available(macOS 26, *) {
                GlassEffect()
            } else {
                VisualEffectBlur(level: level, blendingMode: blending)
            }
        default:
            VisualEffectBlur(level: level, blendingMode: blending)
        }
    }
}

/// Native glass. It samples what sits behind it on its own, so it has no
/// blending mode; the caller's clip shape gives it its outline.
@available(macOS 26, *)
private struct GlassEffect: NSViewRepresentable {
    func makeNSView(context: Context) -> NSGlassEffectView {
        let view = NSGlassEffectView()
        view.cornerRadius = 0
        return view
    }
    func updateNSView(_ view: NSGlassEffectView, context: Context) {}
}
