import AinkradAppKitContract
import SwiftUI

/// Chamfer app icon tile with hover/selected glow — the kit's portable
/// version of the host's NeonAppTile, for use by plugins that need an
/// app-launcher-style icon grid.
public struct AinkradAppTile: View {
    private let symbol: String
    private let title: String?
    private let size: CGFloat
    private let isSelected: Bool

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(symbol: String, title: String? = nil, size: CGFloat = 44, isSelected: Bool = false) {
        self.symbol = symbol
        self.title = title
        self.size = size
        self.isSelected = isSelected
    }

    private var glyphSize: CGFloat { size * skin.components.appTile.glyphRatio }

    public var body: some View {
        let tile = skin.components.appTile
        let shape = AinkradSkinShape(token: tile.shape)
        VStack(spacing: skin.spacing.xs) {
            Image(systemName: symbol)
                .font(
                    .system(size: glyphSize, weight: .medium)  // design-lint: allow font-size caller-sized glyph
                )
                .foregroundStyle(skin.color(skin.text.primary))
                .frame(width: size, height: size)
                .background(shape.fill(skin.color(tile.fill)))
                .overlay(
                    shape.strokeBorder(
                        skin.color(tile.stroke.color, state: state), lineWidth: tile.stroke.width.resolve(state))
                )
                .shadow(color: skin.color(tile.glow.color, state: state), radius: tile.glow.radius.resolve(state))
                .scaleEffect(hovering && !reduceMotion ? tile.hoverScale : 1.0)
            if let title {
                Text(title)
                    .font(skin.font(tile.titleFont, typography: typo))
                    .foregroundStyle(skin.color(tile.titleColor))
                    .lineLimit(1)
            }
        }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
        .onHover { hovering = $0 }
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if isSelected { state.insert(.selected) }
        if hovering { state.insert(.hover) }
        return state
    }
}
