import SwiftUI

/// A rounded tile holding an SF Symbol, or a text glyph, in a tint: a kind badge, a type icon, a status tile.
/// The symbol form steps its glyph size with the tile and can be `filled` solid (with a glow) or ringed; the text
/// form is the 30 pt kind tile with a tinted rim.
public struct AinkradIconTile: View {
    private enum Face {
        case symbol(String)
        case glyph(String)
    }

    private let face: Face
    private let tint: Color
    private let size: CGFloat?
    private let radius: CGFloat?
    private let filled: Bool
    private let ring: Bool
    @Environment(\.ainkradSkin) private var skin

    public init(
        systemName: String, tint: Color, size: CGFloat? = nil, radius: CGFloat? = nil, filled: Bool = false,
        ring: Bool = false
    ) {
        self.face = .symbol(systemName)
        self.tint = tint
        self.size = size
        self.radius = radius
        self.filled = filled
        self.ring = ring
    }

    public init(glyph: String, tint: Color, size: CGFloat? = nil) {
        self.face = .glyph(glyph)
        self.tint = tint
        self.size = size
        self.radius = nil
        self.filled = false
        self.ring = false
    }

    public var body: some View {
        switch face {
        case .symbol(let name): symbol(name)
        case .glyph(let text): glyph(text)
        }
    }

    private func symbol(_ name: String) -> some View {
        let side = size ?? skin.size.s32
        let shape = RoundedRectangle(cornerRadius: radius ?? side * 0.3, style: .continuous)
        return Image(systemName: name)
            .kitFont(
                side >= skin.size.s40 ? "t17" : side >= skin.size.s32 ? "t14" : side >= skin.size.s26 ? "t12" : "t10",
                weight: "semibold"
            )
            .foregroundStyle(filled ? skin.color(.palette("foreground", 1)) : tint)
            .frame(width: side, height: side)
            .background(shape.fill(filled ? tint : tint.opacity(skin.opacity.o15)))
            .overlay {
                if ring { shape.strokeBorder(tint.opacity(skin.opacity.o28), lineWidth: 1) }
            }
            .shadow(color: filled ? tint.opacity(skin.opacity.o45) : .clear, radius: skin.size.s6, y: skin.size.s4)
    }

    private func glyph(_ text: String) -> some View {
        let side = size ?? skin.size.s30
        let shape = RoundedRectangle(cornerRadius: side * 0.3, style: .continuous)
        return Text(text).kitFont("t12", weight: "semibold").foregroundStyle(tint)
            .frame(width: side, height: side)
            .background(tint.opacity(skin.opacity.o16), in: shape)
            .overlay(shape.strokeBorder(tint.opacity(skin.opacity.o20), lineWidth: 1))
    }
}
