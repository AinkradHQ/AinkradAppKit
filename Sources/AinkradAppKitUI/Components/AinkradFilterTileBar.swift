import SwiftUI

/// One tile of an `AinkradFilterTileBar`: an icon, a label and a count, in its own colour.
public struct AinkradFilterTile: Identifiable {
    public let id: String
    public let label: String
    public let icon: String
    public let count: Int
    public let tint: Color

    public init(id: String, label: String, icon: String, count: Int, tint: Color) {
        self.id = id
        self.label = label
        self.icon = icon
        self.count = count
        self.tint = tint
    }
}

/// An n-up filter bar of tiles (an icon tile and a mono count over a label) on one glass track. The selected tile
/// washes in its colour with a solid, glowing icon; an empty tile dims; a hovered icon tilts. `select` gets the
/// tapped tile's id.
public struct AinkradFilterTileBar: View {
    private let tiles: [AinkradFilterTile]
    private let selection: String
    private let select: (String) -> Void
    @Environment(\.ainkradSkin) private var skin

    public init(tiles: [AinkradFilterTile], selection: String, select: @escaping (String) -> Void) {
        self.tiles = tiles
        self.selection = selection
        self.select = select
    }

    public var body: some View {
        let track = RoundedRectangle(cornerRadius: skin.size.s16, style: .continuous)
        HStack(spacing: skin.size.s4) {
            ForEach(tiles) { tile in
                TileView(tile: tile, isOn: tile.id == selection) { select(tile.id) }
            }
        }
        .padding(skin.size.s5)
        .background(track.fill(skin.color(.palette("background", skin.opacity.o72))))
        .overlay(track.strokeBorder(skin.color(.palette("foreground", skin.opacity.o07)), lineWidth: 1))
    }
}

private struct TileView: View {
    let tile: AinkradFilterTile
    let isOn: Bool
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s12, style: .continuous)
        AinkradTapArea(action: action) {
            HStack(spacing: skin.size.s8) {
                AinkradIconTile(
                    systemName: tile.icon, tint: tile.tint, size: skin.size.s28, radius: skin.size.s8, filled: isOn
                )
                .scaleEffect(hovering && !reduceMotion ? 1.08 : 1)
                .rotationEffect(.degrees(hovering && !reduceMotion ? -4 : 0))
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(tile.count)").kitFont("t13", weight: "semibold", mono: true)
                        .foregroundStyle(skin.color(skin.text.primary))
                    Text(tile.label).kitFont("t10_5").foregroundStyle(skin.color(skin.text.faint)).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, skin.size.s8)
            .frame(maxWidth: .infinity)
            .frame(height: skin.size.s40)
            .background {
                if isOn {
                    shape.fill(tile.tint.opacity(skin.opacity.o16))
                        .overlay(shape.strokeBorder(tile.tint.opacity(skin.opacity.o40), lineWidth: 1))
                } else if hovering {
                    shape.fill(skin.color(.palette("foreground", skin.opacity.o05)))
                }
            }
            .contentShape(shape)
        }
        .opacity(tile.count == 0 && !isOn ? skin.opacity.o45 : 1)
        .onHover { hovering = $0 }
        .animation(skin.animation(AinkradAnimationToken(curve: "spring", response: 0.3, damping: 0.6)), value: hovering)
        .animation(skin.animation(skin.motion.hover), value: isOn)
    }
}
