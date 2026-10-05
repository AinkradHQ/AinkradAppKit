import AinkradAppKitContract
import AppKit
import SwiftUI

/// Custom single-thumb HUD slider — chamfer-adjacent track + a glowing thumb
/// (never a native `Slider`).
public struct AinkradSlider: View {
    @Binding private var value: Double
    private let bounds: ClosedRange<Double>
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var dragging = false

    public init(value: Binding<Double>, in bounds: ClosedRange<Double>) {
        self._value = value
        self.bounds = bounds
    }

    private var span: Double { max(bounds.upperBound - bounds.lowerBound, .leastNonzeroMagnitude) }
    private func fraction(_ value: Double) -> CGFloat { CGFloat((value - bounds.lowerBound) / span) }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let x = fraction(value) * width

            ZStack(alignment: .leading) {
                Capsule().fill(theme.surfaceElevated.opacity(0.6)).frame(height: 4)
                Capsule().fill(theme.accentSecondary.opacity(0.85)).frame(width: max(x, 0), height: 4)
                Circle()
                    .fill(theme.accentSecondary)
                    .frame(width: 14, height: 14)
                    .shadow(color: theme.accentSecondary.opacity(dragging ? 0.9 : 0.55), radius: dragging ? 8 : 4)
                    .scaleEffect(dragging && !reduceMotion ? 1.15 : 1.0)
                    .offset(x: x - 7)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        dragging = true
                        let clampedFraction = min(max(drag.location.x / max(width, 1), 0), 1)
                        value = bounds.lowerBound + Double(clampedFraction) * span
                    }
                    .onEnded { _ in dragging = false }
            )
        }
        .frame(height: 20)
        .animation(AinkradMotion.hover, value: dragging)
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.xs)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.3)))
        .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(0.2), lineWidth: 1))
        // The control was a bare `DragGesture` with no accessibility of any
        // kind: no value, no action, and a drag is a pointer gesture. It was
        // therefore not merely unlabelled but INOPERABLE without a mouse —
        // the notification volume could not be changed at all.
        .accessibilityElement()
        .accessibilityValue(Self.spokenValue(value, in: bounds))
        .accessibilityAdjustableAction { direction in
            // Twentieths, so a full sweep is twenty presses rather than a
            // hundred, and each press moves audibly.
            let stepSize = span / 20
            switch direction {
            case .increment: value = min(value + stepSize, bounds.upperBound)
            case .decrement: value = max(value - stepSize, bounds.lowerBound)
            @unknown default: break
            }
        }
    }

    /// Spoken as a percentage of the range. Pure, so the wording is testable
    /// without rendering — a slider that announces "0.62" tells the listener
    /// nothing about how far along it is.
    static func spokenValue(_ value: Double, in bounds: ClosedRange<Double>) -> String {
        let span = max(bounds.upperBound - bounds.lowerBound, .leastNonzeroMagnitude)
        let fraction = (value - bounds.lowerBound) / span
        return "\(Int((min(max(fraction, 0), 1) * 100).rounded()))%"
    }
}
