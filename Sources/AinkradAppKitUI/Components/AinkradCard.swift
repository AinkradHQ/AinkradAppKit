import AinkradAppKitContract
import SwiftUI

/// Surface-elevated rounded container with hover + selected states.
/// Consolidates AppStoreCard / ToolCallCard / connection rows.
public struct AinkradCard<Content: View>: View {
    private let isSelected: Bool
    private let onTap: (() -> Void)?
    private let content: Content
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(
        isSelected: Bool = false, onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.onTap = onTap
        self.content = content()
    }
    /// Whether the card routes taps (drives accessibility + hit testing).
    public var isInteractive: Bool { onTap != nil }

    public var body: some View {
        let card = skin.components.card
        let shape = AinkradSkinShape(token: card.shape)
        content
            .padding(card.padding)
            .background(shape.fill(skin.color(card.fill)))
            .overlay(
                shape.strokeBorder(
                    skin.color(card.stroke.color, state: state), lineWidth: card.stroke.width.resolve(state))
            )
            .apply {
                hovering && !reduceMotion
                    ? AnyView($0.cornerBrackets(length: card.hoverBracketLength, inset: card.hoverBracketInset))
                    : AnyView($0)
            }
            .scaleEffect(hovering && !reduceMotion ? card.hoverScale : 1.0)
            .animation(AinkradMotion.hover, value: hovering)
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .apply { if let onTap { $0.onTapGesture(perform: onTap) } else { $0 } }
    }
    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if isSelected { state.insert(.selected) }
        if hovering { state.insert(.hover) }
        return state
    }
}

// Small helper so the conditional tap gesture stays readable.
extension View { @ViewBuilder func apply<V: View>(@ViewBuilder _ t: (Self) -> V) -> some View { t(self) } }
