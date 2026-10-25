import SwiftUI

/// A ring that fills clockwise from 12 o'clock with a label in its middle: the Citadel KPI ring and requirement
/// donut. The stroke sweeps in from empty on first appearance (skipped under Reduce Motion), and later value changes
/// animate. `value` is clamped to 0…1; `nil` draws only the track (a "not started" donut).
public struct AinkradRingGauge<Label: View>: View {
    private let value: Double?
    private let tint: Color
    private let diameter: CGFloat
    private let lineWidth: CGFloat
    private let label: Label

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var shown: Double = 0

    public init(
        value: Double?, tint: Color, diameter: CGFloat, lineWidth: CGFloat, @ViewBuilder label: () -> Label
    ) {
        self.value = value.map { min(max($0, 0), 1) }
        self.tint = tint
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.label = label()
    }

    public var body: some View {
        ZStack {
            Circle().stroke(skin.color(.palette("foreground", skin.opacity.o08)), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: shown)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            label
        }
        .frame(width: diameter, height: diameter)
        .onAppear { sweep(to: value ?? 0, first: true) }
        .onChange(of: value) { _, new in sweep(to: new ?? 0, first: false) }
    }

    private func sweep(to target: Double, first: Bool) {
        guard !reduceMotion else {
            shown = target
            return
        }
        // 1.1 s sweep on arrival (the prototype's `ak-ring`), the hover curve for live updates.
        let curve = AinkradAnimationToken(curve: "easeOut", duration: first ? 1.1 : skin.motion.base)
        withAnimation(skin.animation(curve)) { shown = target }
    }
}

extension AinkradRingGauge where Label == EmptyView {
    public init(value: Double?, tint: Color, diameter: CGFloat, lineWidth: CGFloat) {
        self.init(value: value, tint: tint, diameter: diameter, lineWidth: lineWidth) { EmptyView() }
    }
}
