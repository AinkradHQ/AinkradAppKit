import SwiftUI

/// One step of an `AinkradStepTrail`: a label, a state dot, and an optional mono detail after the label.
public struct AinkradTrailStep: Equatable {
    public enum State: Sendable { case ok, warn, bad }

    public var label: String
    public var state: State
    public var detail: String?

    public init(label: String, state: State = .ok, detail: String? = nil) {
        self.label = label
        self.state = state
        self.detail = detail
    }
}

/// An evidence trail: step chips with an ok, warn or bad dot, joined by short links a highlight flows along (still
/// under Reduce Motion). The steps rise in one after another, starting `delay` seconds in.
public struct AinkradStepTrail: View {
    private let steps: [AinkradTrailStep]
    private let delay: Double
    @Environment(\.ainkradSkin) private var skin

    public init(steps: [AinkradTrailStep], delay: Double = 0) {
        self.steps = steps
        self.delay = delay
    }

    public var body: some View {
        AinkradFlowLayout(spacing: 0, lineSpacing: skin.size.s6) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 0) {
                    if index > 0 { TrailLink() }
                    chip(step).ainkradRiseIn(delay: delay + Double(index) * 0.09)
                }
            }
        }
    }

    private func chip(_ step: AinkradTrailStep) -> some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s9, style: .continuous)
        let (fg, dot, rim, fill): (Color, Color, Color, Color) =
            switch step.state {
            case .ok:
                (
                    skin.color(skin.text.muted), skin.color(skin.palette.success),
                    skin.color(.palette("foreground", skin.opacity.o07)),
                    skin.color(.palette("foreground", skin.opacity.o05))
                )
            case .warn:
                (
                    skin.color(skin.palette.warning), skin.color(skin.palette.warning),
                    skin.color(skin.palette.warning).opacity(skin.opacity.o30),
                    skin.color(.palette("foreground", skin.opacity.o05))
                )
            case .bad:
                (
                    skin.color(skin.palette.danger), skin.color(skin.palette.danger),
                    skin.color(skin.palette.danger).opacity(skin.opacity.o35),
                    skin.color(skin.palette.danger).opacity(skin.opacity.o08)
                )
            }
        return HStack(spacing: skin.size.s6) {
            Circle().fill(dot).frame(width: skin.size.s7, height: skin.size.s7)
                .shadow(color: step.state == .bad ? dot : .clear, radius: skin.size.s4)
            Text(step.label).kitFont("t11")
            if let detail = step.detail {
                Text(detail).kitFont("t10_5", mono: true).opacity(skin.opacity.o80)
            }
        }
        .foregroundStyle(fg)
        .padding(.horizontal, skin.size.s10)
        .frame(height: skin.size.s28)
        .background(fill, in: shape)
        .overlay(shape.strokeBorder(rim, lineWidth: 1))
    }
}

/// The short link between two steps, a highlight flowing along it.
private struct TrailLink: View {
    @State private var phase: CGFloat = 0
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        let width = skin.size.s22
        LinearGradient(
            colors: [
                skin.color(.palette("foreground", skin.opacity.o08)),
                skin.color(.palette("foreground", skin.opacity.o22)),
            ], startPoint: .leading, endPoint: .trailing
        )
        .frame(width: width, height: skin.size.s2)
        .overlay(alignment: .leading) {
            if !reduceMotion {
                Rectangle().fill(skin.color(.palette("foreground", skin.opacity.o60)))
                    .frame(width: skin.size.s8)
                    .offset(x: -skin.size.s8 + phase * (width + skin.size.s8))
            }
        }
        .clipped()
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                skin.animation(AinkradAnimationToken(curve: "linear", duration: 1.8)).repeatForever(autoreverses: false)
            ) { phase = 1 }
        }
    }
}
