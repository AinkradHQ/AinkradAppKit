import SwiftUI
import AinkradAppKitContract

/// Clamps `value` into `range`, then snaps it down onto the step grid
/// anchored at `range.lowerBound` (so `steppedClamp(9, in: 0...10, step: 5)`
/// snaps down to `5`, not `10`). Pure — `AinkradStepper`'s reducer, called
/// with `value ± step` on each tap, unit-testable without SwiftUI.
public func steppedClamp(_ value: Int, in range: ClosedRange<Int>, step: Int) -> Int {
    let clamped = min(max(value, range.lowerBound), range.upperBound)
    guard step > 1 else { return clamped }
    let offset = clamped - range.lowerBound
    let snapped = range.lowerBound + (offset / step) * step
    return min(max(snapped, range.lowerBound), range.upperBound)
}

/// Clamps both ends of `range` into `bounds`, guaranteeing the result is a
/// valid (non-inverted) `ClosedRange`. Pure — `AinkradRangeSlider`'s thumb
/// drag reducer, unit-testable without SwiftUI.
public func clampRange(_ range: ClosedRange<Double>, within bounds: ClosedRange<Double>) -> ClosedRange<Double> {
    let lower = min(max(range.lowerBound, bounds.lowerBound), bounds.upperBound)
    let upper = min(max(range.upperBound, bounds.lowerBound), bounds.upperBound)
    return lower <= upper ? lower...upper : upper...upper
}

/// Custom −/+ stepper — chamfer buttons flanking a numeric readout (never a
/// native `Stepper`).
public struct AinkradStepper: View {
    @Binding private var value: Int
    private let bounds: ClosedRange<Int>
    private let step: Int

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(value: Binding<Int>, in bounds: ClosedRange<Int>, step: Int = 1) {
        self._value = value; self.bounds = bounds; self.step = step
    }

    public var body: some View {
        HStack(spacing: AinkradSpacing.xs) {
            stepButton(systemName: "minus", enabled: value > bounds.lowerBound) {
                value = steppedClamp(value - step, in: bounds, step: step)
            }
            Text("\(value)")
                .font(AinkradFontResolver.font(.mono, weight: .medium, typography: typo))
                .foregroundStyle(theme.foreground)
                .frame(minWidth: 28)
                .monospacedDigit()
            stepButton(systemName: "plus", enabled: value < bounds.upperBound) {
                value = steppedClamp(value + step, in: bounds, step: step)
            }
        }
        .padding(.horizontal, AinkradSpacing.xs)
        .padding(.vertical, AinkradSpacing.xs / 2)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(0.3), lineWidth: 1.25))
        .animation(AinkradMotion.hover, value: value)
        // One adjustable control, not two unnamed glyph buttons either side of
        // a loose number — which is what "minus, button, 30, plus, button"
        // amounted to. `.ignore` on purpose: a stepper is conventionally a
        // single element whose value is adjusted, and separately focusing the
        // two glyphs gains a listener nothing.
        .accessibilityElement(children: .ignore)
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = steppedClamp(value + step, in: bounds, step: step)
            case .decrement: value = steppedClamp(value - step, in: bounds, step: step)
            @unknown default: break
            }
        }
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(enabled ? theme.accentSecondary : theme.foreground.opacity(0.25))
                .frame(width: 20, height: 20)
                .background(ChamferShape(cut: 4).fill(theme.surfaceElevated.opacity(0.6)))
                .overlay(ChamferShape(cut: 4).strokeBorder(theme.accentSecondary.opacity(enabled ? 0.5 : 0.15), lineWidth: 1))
                .contentShape(ChamferShape(cut: 4))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// HUD dual-thumb range slider — a chamfer track with two glowing draggable
/// thumbs (never a native `Slider`). Dragging either thumb updates `range`
/// via `clampRange`, keeping it non-inverted and within `bounds`.
public struct AinkradRangeSlider: View {
    @Binding private var range: ClosedRange<Double>
    private let bounds: ClosedRange<Double>

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var draggingLower = false
    @State private var draggingUpper = false

    public init(range: Binding<ClosedRange<Double>>, bounds: ClosedRange<Double>) {
        self._range = range; self.bounds = bounds
    }

    private var span: Double { max(bounds.upperBound - bounds.lowerBound, .leastNonzeroMagnitude) }

    private func fraction(for value: Double) -> CGFloat {
        CGFloat((value - bounds.lowerBound) / span)
    }
    private func value(forFraction fraction: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return bounds.lowerBound }
        let clampedFraction = min(max(fraction, 0), 1)
        return bounds.lowerBound + Double(clampedFraction) * span
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let lowerX = fraction(for: range.lowerBound) * width
            let upperX = fraction(for: range.upperBound) * width

            ZStack(alignment: .leading) {
                Capsule().fill(theme.surfaceElevated.opacity(0.6))
                    .frame(height: 4)

                Capsule().fill(theme.accentSecondary.opacity(0.85))
                    .frame(width: max(upperX - lowerX, 0), height: 4)
                    .offset(x: lowerX)

                thumb(isDragging: draggingLower)
                    .offset(x: lowerX - 7)
                    .gesture(dragGesture(width: width, isLower: true))

                thumb(isDragging: draggingUpper)
                    .offset(x: upperX - 7)
                    .gesture(dragGesture(width: width, isLower: false))
            }
            .frame(height: 20)
        }
        .frame(height: 20)
        .padding(.horizontal, AinkradSpacing.sm)
    }

    private func thumb(isDragging: Bool) -> some View {
        Circle()
            .fill(theme.accentSecondary)
            .frame(width: 14, height: 14)
            .shadow(color: theme.accentSecondary.opacity(isDragging ? 0.9 : 0.55), radius: isDragging ? 8 : 4)
            .scaleEffect(isDragging && !reduceMotion ? 1.15 : 1.0)
            .animation(AinkradMotion.hover, value: isDragging)
    }

    private func dragGesture(width: CGFloat, isLower: Bool) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if isLower { draggingLower = true } else { draggingUpper = true }
                let newValue = value(forFraction: drag.location.x / width, width: width)
                let proposed: ClosedRange<Double> = isLower
                    ? min(newValue, range.upperBound)...range.upperBound
                    : range.lowerBound...max(newValue, range.lowerBound)
                range = clampRange(proposed, within: bounds)
            }
            .onEnded { _ in
                draggingLower = false
                draggingUpper = false
            }
    }
}
