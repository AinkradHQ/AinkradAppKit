import SwiftUI

/// `fieldHeight(_:)`: exactly `height` tall, the content centred; without
/// one, the field's own vertical `padding`.
struct FieldHeight: ViewModifier {
    let height: CGFloat?
    let padding: CGFloat

    func body(content: Content) -> some View {
        if let height { content.frame(height: height) } else { content.padding(.vertical, padding) }
    }
}

/// The kit field's fill, rim and focus glow — or, under `chamfered()`, the
/// mockups' `.sfield.cut`: an 8 pt chamfer (rounded under a Glass skin),
/// the strong elevated fill and a 1 pt cyan rim at rest.
struct FieldChrome: ViewModifier {
    let skin: AinkradSkin
    let chamfered: Bool
    let state: AinkradControlState

    func body(content: Content) -> some View {
        let field = skin.roles.field
        let shape = chamfered ? skin.shape(cut: skin.size.s8) : AinkradSkinShape(token: field.shape)
        let atRest = chamfered && !state.contains(.focused)
        return
            content
            .background(
                shape.fill(
                    chamfered
                        ? skin.color(skin.palette.surfaceElevated).opacity(skin.opacity.o95)
                        : skin.color(field.fill))
            )
            .overlay(
                shape.strokeBorder(
                    atRest
                        ? skin.color(skin.palette.accentSecondary).opacity(skin.opacity.o45)
                        : skin.color(field.stroke.color, state: state),
                    lineWidth: atRest ? 1 : field.stroke.width.resolve(state))
            )
            .shadow(color: skin.color(field.glow.color, state: state), radius: field.glow.radius.resolve(state))
    }
}
