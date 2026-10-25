import SwiftUI

extension View {
    /// A loading placeholder's shimmer: a soft highlight band sweeping left to right every 1.3 s. Static under Reduce
    /// Motion. Apply to the skeleton shape (it masks itself to the view's alpha).
    public func ainkradShimmer() -> some View { modifier(ShimmerModifier()) }

    /// Hover feedback for a tappable card: lifts `lift` points and brightens its border. Pair with a
    /// `.contentShape`. No lift under Reduce Motion.
    public func ainkradHoverLift(_ lift: CGFloat? = nil, cornerRadius: CGFloat? = nil) -> some View {
        modifier(HoverLiftModifier(lift: lift, cornerRadius: cornerRadius))
    }

    /// Shows `card` in a popover after the pointer rests on this view (420 ms; 160 ms grace on leaving, kept open
    /// while the pointer is over the card itself). The Citadel agent hover card.
    public func ainkradHoverCard<Card: View>(
        isEnabled: Bool = true, edge: Edge = .bottom, @ViewBuilder card: @escaping () -> Card
    ) -> some View {
        modifier(HoverCardModifier(isEnabled: isEnabled, edge: edge, card: card))
    }
}

private struct ShimmerModifier: ViewModifier {
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content.overlay {
            if !reduceMotion {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, skin.color(.palette("foreground", skin.opacity.o10)), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width)
                    .offset(x: phase * geo.size.width * 1.5)
                }
                .mask(content)
                .allowsHitTesting(false)
                .onAppear {
                    withAnimation(
                        skin.animation(AinkradAnimationToken(curve: "linear", duration: 1.3)).repeatForever(
                            autoreverses: false)
                    ) { phase = 1 }
                }
            }
        }
    }
}

private struct HoverLiftModifier: ViewModifier {
    let lift: CGFloat?
    let cornerRadius: CGFloat?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius ?? skin.size.s18, style: .continuous)
                    .strokeBorder(skin.color(.palette("foreground", skin.opacity.o07)), lineWidth: 1)
                    .opacity(hovering ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .offset(y: hovering && !reduceMotion ? -(lift ?? skin.size.s2) : 0)
            .animation(
                skin.animation(AinkradAnimationToken(curve: "spring", response: 0.3, damping: 0.75)), value: hovering
            )
            .onHover { hovering = $0 }
    }
}

private struct HoverCardModifier<Card: View>: ViewModifier {
    let isEnabled: Bool
    let edge: Edge
    let card: () -> Card
    @State private var shown = false
    @State private var overAnchor = false
    @State private var overCard = false
    @State private var pending: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onHover { inside in
                overAnchor = inside
                schedule()
            }
            .popover(isPresented: $shown, arrowEdge: edge) {
                card()
                    .onHover { inside in
                        overCard = inside
                        schedule()
                    }
            }
    }

    private func schedule() {
        pending?.cancel()
        guard isEnabled else { return }
        let wanted = overAnchor || overCard
        guard wanted != shown else { return }
        let delay = wanted ? 420 : 160
        pending = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(delay))
            guard !Task.isCancelled else { return }
            shown = overAnchor || overCard
        }
    }
}
