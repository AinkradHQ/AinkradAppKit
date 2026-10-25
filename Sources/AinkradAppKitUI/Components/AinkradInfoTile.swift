import SwiftUI

/// A context tile: an icon square tinted `tint`, a faint label over a value.
public struct AinkradInfoTile: View {
    private let systemImage: String
    private let tint: Color
    private let label: String
    private let value: String
    @Environment(\.ainkradSkin) private var skin

    public init(systemImage: String, tint: Color, label: String, value: String) {
        self.systemImage = systemImage
        self.tint = tint
        self.label = label
        self.value = value
    }

    public var body: some View {
        HStack(spacing: skin.size.s10) {
            Image(systemName: systemImage)
                .kitFont("t14", weight: "medium")
                .foregroundStyle(tint)
                .frame(width: skin.size.s32, height: skin.size.s32)
                .background(tint.opacity(skin.opacity.o15), in: RoundedRectangle(cornerRadius: skin.size.s10))
            VStack(alignment: .leading, spacing: skin.size.s1) {
                Text(label).kitFont("t10_5").foregroundStyle(skin.color(skin.text.faint))
                Text(value).kitFont("t12_5", weight: "medium").foregroundStyle(skin.color(skin.text.primary))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, skin.size.s12)
        .padding(.vertical, skin.size.s10)
        .background(
            skin.color(.palette("foreground", skin.opacity.o03)), in: RoundedRectangle(cornerRadius: skin.size.s14))
    }
}

/// Info tiles two to a row.
public struct AinkradInfoTileGrid: View {
    private let tiles: [AinkradInfoTile]
    @Environment(\.ainkradSkin) private var skin

    public init(tiles: [AinkradInfoTile]) { self.tiles = tiles }

    public var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: skin.size.s8), GridItem(.flexible(), spacing: skin.size.s8)],
            spacing: skin.size.s8
        ) {
            ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in tile }
        }
    }
}
