import AinkradAppKitContract
import SwiftUI

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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(value: Binding<Int>, in bounds: ClosedRange<Int>, step: Int = 1) {
        self._value = value
        self.bounds = bounds
        self.step = step
    }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple's stepper; the callbacks keep the
            // kit's snap-to-step clamp.
            Stepper {
                Text("\(value)").monospacedDigit()
            } onIncrement: {
                value = steppedClamp(value + step, in: bounds, step: step)
            } onDecrement: {
                value = steppedClamp(value - step, in: bounds, step: step)
            }
            .accessibilityValue("\(value)")
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let stepper = skin.components.stepper
        let shape = AinkradSkinShape(token: stepper.shape)
        return HStack(spacing: AinkradSpacing.xs) {
            stepButton(systemName: "minus", enabled: value > bounds.lowerBound) {
                value = steppedClamp(value - step, in: bounds, step: step)
            }
            Text("\(value)")
                .font(skin.font(stepper.valueFont, typography: typo))
                .foregroundStyle(skin.color(skin.text.primary))
                .frame(minWidth: stepper.valueMinWidth)
                .monospacedDigit()
            stepButton(systemName: "plus", enabled: value < bounds.upperBound) {
                value = steppedClamp(value + step, in: bounds, step: step)
            }
        }
        .padding(.horizontal, AinkradSpacing.xs)
        .padding(.vertical, AinkradSpacing.xs / 2)
        .background(shape.fill(skin.color(stepper.fill)))
        .overlay(
            shape.strokeBorder(
                skin.color(stepper.stroke.color), lineWidth: stepper.stroke.width.resolve([]))
        )
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
        let stepper = skin.components.stepper
        let buttonShape = AinkradSkinShape(token: stepper.buttonShape)
        let buttonState: AinkradControlState = enabled ? [] : [.disabled]
        return Button(action: action) {
            Image(systemName: systemName)
                .font(skin.font(stepper.buttonGlyphFont, typography: typo))
                .foregroundStyle(skin.color(stepper.buttonGlyphColor, state: buttonState))
                .frame(width: stepper.buttonSize, height: stepper.buttonSize)
                .background(buttonShape.fill(skin.color(stepper.buttonFill)))
                .overlay(
                    buttonShape.strokeBorder(
                        skin.color(stepper.buttonStroke.color, state: buttonState),
                        lineWidth: stepper.buttonStroke.width.resolve(buttonState))
                )
                .contentShape(buttonShape)
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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var draggingLower = false
    @State private var draggingUpper = false

    public init(range: Binding<ClosedRange<Double>>, bounds: ClosedRange<Double>) {
        self._range = range
        self.bounds = bounds
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
        let track = skin.roles.track
        GeometryReader { proxy in
            let width = proxy.size.width
            let lowerX = fraction(for: range.lowerBound) * width
            let upperX = fraction(for: range.upperBound) * width

            ZStack(alignment: .leading) {
                let systemTrack = Color(nsColor: .tertiarySystemFill)  // design-lint: allow raw-color Glass
                Capsule().fill(skin.usesNativeGlass ? systemTrack : skin.color(track.fill))
                    .frame(height: track.height)

                Capsule().fill(
                    skin.usesNativeGlass ? skin.color(skin.palette.accentPrimary) : skin.color(track.activeFill)
                )
                .frame(width: max(upperX - lowerX, 0), height: track.height)
                .offset(x: lowerX)

                thumb(isDragging: draggingLower)
                    .offset(x: lowerX - skin.roles.thumb.offset)
                    .gesture(dragGesture(width: width, isLower: true))

                thumb(isDragging: draggingUpper)
                    .offset(x: upperX - skin.roles.thumb.offset)
                    .gesture(dragGesture(width: width, isLower: false))
            }
            .frame(height: track.rowHeight)
        }
        .frame(height: skin.roles.track.rowHeight)
        .padding(.horizontal, AinkradSpacing.sm)
    }

    private func thumb(isDragging: Bool) -> some View {
        let thumb = skin.roles.thumb
        let thumbState: AinkradControlState = isDragging ? [.pressed] : []
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple has no dual-thumb slider, so the kit
            // control keeps its geometry with Liquid Glass thumbs.
            return AnyView(
                Circle().fill(.white)  // design-lint: allow raw-color system slider thumb under Glass Native
                    .frame(width: thumb.size, height: thumb.size)
                    .glassEffect(.regular.interactive(), in: .circle))
        }
        return AnyView(
            Circle()
                .fill(skin.color(thumb.fill))
                .frame(width: thumb.size, height: thumb.size)
                .shadow(
                    color: skin.color(thumb.glow.color, state: thumbState),
                    radius: thumb.glow.radius.resolve(thumbState)
                )
                .scaleEffect(isDragging && !reduceMotion ? thumb.dragScale : 1.0)
                .animation(AinkradMotion.hover, value: isDragging))
    }

    private func dragGesture(width: CGFloat, isLower: Bool) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { drag in
                if isLower { draggingLower = true } else { draggingUpper = true }
                let newValue = value(forFraction: drag.location.x / width, width: width)
                let proposed: ClosedRange<Double> =
                    isLower
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
