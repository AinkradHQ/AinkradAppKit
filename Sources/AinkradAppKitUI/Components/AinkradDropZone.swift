import SwiftUI

extension View {
    /// Makes this view a drop zone for dragged ids (`.draggable(String)`): a rounded column or section that washes
    /// accent with an accent rim while one hovers over it. `drop` gets the first id and says whether it took it.
    /// `radius` and `rest` (the resting wash opacity) default to the section card's.
    public func ainkradDropZone(radius: CGFloat? = nil, rest: Double? = nil, drop: @escaping (String) -> Bool)
        -> some View
    {
        modifier(DropZoneModifier(radius: radius, rest: rest, drop: drop))
    }
}

private struct DropZoneModifier: ViewModifier {
    let radius: CGFloat?
    let rest: Double?
    let drop: (String) -> Bool
    @State private var over = false
    @Environment(\.ainkradSkin) private var skin

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius ?? skin.size.s16, style: .continuous)
        let accent = skin.color(skin.palette.accentPrimary)
        content
            .background(
                shape.fill(
                    over
                        ? accent.opacity(skin.opacity.o08)
                        : skin.color(.palette("foreground", rest ?? skin.opacity.o03))
                )
            )
            .overlay(
                shape.strokeBorder(
                    over ? accent.opacity(skin.opacity.o45) : skin.color(.palette("foreground", skin.opacity.o07)))
            )
            .dropDestination(for: String.self) { ids, _ in
                ids.first.map(drop) ?? false
            } isTargeted: {
                over = $0
            }
            .animation(skin.animation(skin.motion.hover), value: over)
    }
}
