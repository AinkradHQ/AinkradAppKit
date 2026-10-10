import SwiftUI

/// An arrow key the command field reports to its owner.
public enum AinkradArrow: Sendable { case up, down, left, right }

/// The summon field of a command overlay: a glowing leading mark and a
/// borderless text field. Arrows go to `onArrow` (return `true` when handled,
/// `false` to let the caret move), return to `onSubmit`, escape to `onEscape`.
public struct AinkradCommandField: View {
    private let placeholder: String
    @Binding private var text: String
    private let focus: FocusState<Bool>.Binding
    private let leading: AnyView?
    private let onArrow: (AinkradArrow) -> Bool
    private let onSubmit: () -> Void
    private let onEscape: () -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    /// Leading mark: the brand chevron with the accent glow.
    public init(
        _ placeholder: String, text: Binding<String>, focus: FocusState<Bool>.Binding,
        onArrow: @escaping (AinkradArrow) -> Bool,
        onSubmit: @escaping () -> Void, onEscape: @escaping () -> Void
    ) {
        self.placeholder = placeholder
        self._text = text
        self.focus = focus
        self.leading = nil
        self.onArrow = onArrow
        self.onSubmit = onSubmit
        self.onEscape = onEscape
    }

    /// A custom leading mark.
    public init<Leading: View>(
        _ placeholder: String, text: Binding<String>, focus: FocusState<Bool>.Binding,
        @ViewBuilder leading: () -> Leading,
        onArrow: @escaping (AinkradArrow) -> Bool,
        onSubmit: @escaping () -> Void, onEscape: @escaping () -> Void
    ) {
        self.placeholder = placeholder
        self._text = text
        self.focus = focus
        self.leading = AnyView(leading())
        self.onArrow = onArrow
        self.onSubmit = onSubmit
        self.onEscape = onEscape
    }

    public var body: some View {
        let tokens = skin.components.commandField
        HStack(spacing: tokens.gap) {
            if let leading {
                leading
            } else {
                AinkradBrandChevron()
                    .fill(skin.color(tokens.markColor))
                    .frame(width: tokens.markWidth, height: tokens.markHeight)
                    .shadow(
                        color: skin.usesNativeGlass ? .clear : skin.color(tokens.markGlow.color),
                        radius: skin.usesNativeGlass ? 0 : tokens.markGlow.radius.resolve([]))
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(skin.font(tokens.font, typography: typo))
                .foregroundStyle(skin.color(tokens.foreground))
                .tint(skin.color(tokens.tint))
                .focused(focus)
                .onKeyPress(.escape) {
                    onEscape()
                    return .handled
                }
                .onKeyPress(keys: ainkradArrowKeys) { press in
                    guard let arrow = ainkradArrow(for: press.key) else { return .ignored }
                    return onArrow(arrow) ? .handled : .ignored
                }
                .onKeyPress(.return) {
                    onSubmit()
                    return .handled
                }
        }
        .padding(.horizontal, tokens.horizontalPadding)
        .frame(height: tokens.height)
    }
}

// MARK: - File-scope helpers

/// The four keys the field routes to `onArrow`.
let ainkradArrowKeys: Set<KeyEquivalent> = [.upArrow, .downArrow, .leftArrow, .rightArrow]

/// Maps a pressed key to the arrow it stands for, `nil` for any other key.
func ainkradArrow(for key: KeyEquivalent) -> AinkradArrow? {
    switch key {
    case .upArrow: .up
    case .downArrow: .down
    case .leftArrow: .left
    case .rightArrow: .right
    default: nil
    }
}
