import AinkradAppKitContract
import SwiftUI

/// `value / total`, clamped into `0...1`. A non-positive `total` returns `0`
/// rather than dividing by zero. Pure — `AinkradMeter`'s arc-fill math,
/// unit-testable without SwiftUI.
public func meterFraction(value: Double, total: Double) -> Double {
    guard total > 0 else { return 0 }
    return max(0, min(value / total, 1))
}

/// Radial/arc gauge — the Cardinal HUD "reactor ring" stand-in for a linear
/// progress bar. Reads theme/status colors from the environment; under
/// `ainkradReduceMotion` the arc is set directly to its target fraction
/// instead of sweeping in.
public struct AinkradMeter: View {
    private let value: Double
    private let total: Double
    private let label: String?
    private let kind: AinkradStatusBarKind
    private let size: CGFloat

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var animatedFraction: Double = 0

    public init(
        value: Double, total: Double = 1, label: String? = nil, kind: AinkradStatusBarKind = .accent, size: CGFloat = 88
    ) {
        self.value = value
        self.total = total
        self.label = label
        self.kind = kind
        self.size = size
    }

    private var fraction: Double { meterFraction(value: value, total: total) }
    private var color: Color { kind.color(skin: skin) }
    private var lineWidth: CGFloat { max(meter.lineMinWidth, size * meter.lineWidthRatio) }

    private var meter: MeterTokens { skin.components.meter }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(skin.color(meter.trackColor), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedFraction)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .shadow(color: skin.color(meter.arcGlow.color, tint: color), radius: meter.arcGlow.radius.resolve([]))
                .rotationEffect(.degrees(-90))
            VStack(spacing: meter.gap) {
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(skin.font(meter.valueFont, typography: typo))
                    .foregroundStyle(skin.color(skin.text.primary))
                if let label {
                    Text(skin.labelCased(label))
                        .font(skin.font(meter.labelFont, typography: typo))
                        .tracking(meter.labelFont.tracking ?? 0)
                        .foregroundStyle(skin.color(meter.labelColor))
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { setFraction(fraction, animated: !reduceMotion) }
        .onChange(of: fraction) { _, newValue in setFraction(newValue, animated: !reduceMotion) }
    }

    private func setFraction(_ newValue: Double, animated: Bool) {
        guard animated else {
            animatedFraction = newValue
            return
        }
        withAnimation(skin.animation(skin.motion.materializeAnimation)) { animatedFraction = newValue }
    }
}
