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
    @Environment(\.ainkradNestedSurface) private var isNested
    @State private var hovering = false

    public init(
        isSelected: Bool = false, onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.onTap = onTap
        self.content = content()
    }
    /// Set by `rimTint(_:)`.
    var rimTone: AinkradChartTone?

    /// Draws the card's rim in `tone` — amber for a run waiting on you, red
    /// for a stalled one, violet for the CEO and CTO (Citadel 02, 03). The
    /// selected outline still wins.
    public func rimTint(_ tone: AinkradChartTone) -> Self {
        var copy = self
        copy.rimTone = tone
        return copy
    }

    /// The tinted rim, at the mockups' 60 %.
    private var rimColor: Color? { rimTone.map { $0.color(skin).opacity(skin.opacity.o60) } }

    /// Whether the card routes taps (drives accessibility + hit testing).
    public var isInteractive: Bool { onTap != nil }

    @ViewBuilder public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: content, not chrome — a faint foreground
            // wash with a hairline rim (the mockups' `--fill` / `--stroke`,
            // not the system's grey quaternary fill), the accent outline while
            // selected, a lift on hover. A card inside a card draws
            // no fill of its own, so nested surfaces do not stack lighter.
            // No glass on glass, no brackets, no scale.
            let shape = AinkradSkinShape(token: skin.components.card.shape)
            let foreground = skin.color(skin.palette.foreground)
            let fill =
                isNested
                ? (hovering ? skin.opacity.o03 : 0) : (hovering ? skin.opacity.o08 : skin.opacity.o05)
            content
                .environment(\.ainkradNestedSurface, true)
                .padding(skin.components.card.padding)
                .background(foreground.opacity(fill), in: shape)
                .overlay {
                    if isSelected {
                        shape.strokeBorder(skin.color(skin.palette.accentPrimary), lineWidth: 2)
                    } else {
                        shape.strokeBorder(
                            rimColor ?? foreground.opacity(skin.opacity.o12), lineWidth: skin.size.s1)
                    }
                }
                .animation(AinkradMotion.hover, value: hovering)
                .contentShape(Rectangle())
                .onHover { hovering = $0 }
                .apply { if let onTap { $0.onTapGesture(perform: onTap) } else { $0 } }
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let card = skin.components.card
        let shape = AinkradSkinShape(token: card.shape)
        return
            content
            .padding(card.padding)
            .background(shape.fill(skin.color(card.fill)))
            .overlay(
                shape.strokeBorder(
                    isSelected
                        ? skin.color(card.stroke.color, state: state)
                        : rimColor ?? skin.color(card.stroke.color, state: state),
                    lineWidth: card.stroke.width.resolve(state))
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

extension EnvironmentValues {
    /// Set inside a card's content: a card drawn there is
    /// nested, and under Glass draws no fill of its own so the layers do not
    /// compound.
    @Entry var ainkradNestedSurface = false
}

// Small helper so the conditional tap gesture stays readable.
extension View { @ViewBuilder func apply<V: View>(@ViewBuilder _ t: (Self) -> V) -> some View { t(self) } }
