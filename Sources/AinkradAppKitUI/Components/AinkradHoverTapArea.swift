import SwiftUI

/// A button around a bespoke label that answers the pointer and the keyboard: a faint fill under the pointer, and a
/// ring in the skin's focus colour while it holds keyboard focus (Return and Space fire `action`). Same action and
/// help as `AinkradTapArea`, which stays chrome-free.
public struct AinkradHoverTapArea<Label: View>: View {
    private let help: String?
    private let action: () -> Void
    private let label: Label

    public init(help: String? = nil, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.help = help
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) { label }
            .buttonStyle(.plain)
            .help(help ?? "")
            .ainkradHoverFocus()
            .onKeyPress(keys: [.return, .space]) { _ in
                action()
                return .handled
            }
    }
}

extension View {
    /// Hover fill and keyboard-focus ring for a label that is not inside a `Button` (a row built on `onTapGesture`).
    /// `cornerRadius` defaults to 8 pt. The fill is instant under Reduce Motion.
    public func ainkradHoverFocus(cornerRadius: CGFloat? = nil) -> some View {
        modifier(HoverFocus(cornerRadius: cornerRadius))
    }
}

private struct HoverFocus: ViewModifier {
    let cornerRadius: CGFloat?
    @State private var hovering = false
    @FocusState private var focused: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius ?? skin.size.s8, style: .continuous)
        content
            .background(shape.fill(skin.color(.palette("foreground", hovering ? skin.opacity.o08 : 0))))
            .overlay(shape.strokeBorder(skin.color(.palette("accentPrimary", focused ? 0.9 : 0)), lineWidth: 1.5))
            .contentShape(shape)
            .onHover { hovering = $0 }
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: focused)
            .focusable()
            .focused($focused)
            .focusEffectDisabled()
    }
}
