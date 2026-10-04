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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
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
    private var color: Color { kind.color(theme: theme, statusColors: statusColors) }
    private var lineWidth: CGFloat { max(3, size * 0.07) }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(theme.foreground.opacity(0.1), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animatedFraction)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .shadow(color: color.opacity(0.55), radius: 4)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(Int((fraction * 100).rounded()))%")
                    .font(AinkradFontResolver.font(.headline, weight: .semibold, typography: typo))
                    .foregroundStyle(theme.foreground)
                if let label {
                    Text(label.uppercased())
                        .font(AinkradFontResolver.font(.caption, typography: typo))
                        .tracking(0.6)
                        .foregroundStyle(theme.foreground.opacity(0.55))
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
        withAnimation(AinkradMotion.materialize) { animatedFraction = newValue }
    }
}
