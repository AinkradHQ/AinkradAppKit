import AppKit
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

/// `onReturn(_:)`: Return, with its modifiers, goes to `action`; without
/// one the field is left as it was.
struct ReturnKey: ViewModifier {
    let action: ((EventModifiers) -> Void)?

    func body(content: Content) -> some View {
        if let action {
            content.onKeyPress(.return, phases: .down) { press in
                action(press.modifiers)
                return .handled
            }
        } else {
            content
        }
    }
}

/// `selectsNameWithoutExtension()`: once the field gains focus — and the field
/// editor has selected everything, a turn later — narrows the selection to the
/// base name. The field editor is found through the key window, or any window
/// whose first responder is editing this text.
struct BaseNameSelection: ViewModifier {
    let enabled: Bool
    let isFocused: Bool
    let text: String

    func body(content: Content) -> some View {
        if enabled {
            content.onChange(of: isFocused) { _, focused in
                guard focused else { return }
                let text = text
                DispatchQueue.main.async { Self.select(ainkradBaseNameRange(text), in: text) }
            }
        } else {
            content
        }
    }

    @MainActor static func select(_ range: NSRange, in text: String) {
        let windows = [NSApp.keyWindow].compactMap { $0 } + NSApp.windows
        for window in windows {
            if let editor = window.firstResponder as? NSTextView, editor.isFieldEditor, editor.string == text {
                editor.setSelectedRange(range)
                return
            }
        }
    }
}
