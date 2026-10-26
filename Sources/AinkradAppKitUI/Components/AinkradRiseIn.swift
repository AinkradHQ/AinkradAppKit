import SwiftUI

extension View {
    /// Fades in from a little below on first appearance, after `delay` seconds: stagger a list, a row of cards or a
    /// body's sections by passing each a later delay. `distance` defaults to 8 pt. Shown at once under Reduce Motion.
    public func ainkradRiseIn(delay: Double = 0, distance: CGFloat? = nil) -> some View {
        modifier(RiseIn(delay: delay, distance: distance))
    }
}

extension View {
    /// Staggers by position: `index * stagger` seconds of delay (60 ms apart by default). `distance` defaults to 8 pt.
    /// Shown at once under Reduce Motion.
    public func ainkradRiseIn(index: Int, stagger: Double = 0.06, distance: CGFloat? = nil) -> some View {
        ainkradRiseIn(delay: ainkradStaggerDelay(index: index, stagger: stagger), distance: distance)
    }
}

func ainkradStaggerDelay(index: Int, stagger: Double) -> Double { Double(index) * stagger }

private struct RiseIn: ViewModifier {
    let delay: Double
    let distance: CGFloat?
    @State private var shown = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : distance ?? skin.size.s8)
            .onAppear {
                guard !shown, !reduceMotion else { return }
                withAnimation(skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 0.35)).delay(delay)) {
                    shown = true
                }
            }
    }
}
