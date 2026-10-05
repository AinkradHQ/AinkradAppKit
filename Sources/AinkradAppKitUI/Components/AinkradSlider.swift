import AinkradAppKitContract
import AppKit
import SwiftUI

/// Custom single-thumb HUD slider — chamfer-adjacent track + a glowing thumb
/// (never a native `Slider`).
public struct AinkradSlider: View {
    @Binding private var value: Double
    private let bounds: ClosedRange<Double>
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var dragging = false

    public init(value: Binding<Double>, in bounds: ClosedRange<Double>) {
        self._value = value
        self.bounds = bounds
    }

    private var span: Double { max(bounds.upperBound - bounds.lowerBound, .leastNonzeroMagnitude) }
    private func fraction(_ value: Double) -> CGFloat { CGFloat((value - bounds.lowerBound) / span) }

    private var state: AinkradControlState {
        dragging ? [.pressed] : []
    }

    public var body: some View {
        let track = skin.roles.track
        let thumb = skin.roles.thumb
        let container = skin.components.slider
        let containerShape = AinkradSkinShape(token: container.containerShape)
        GeometryReader { proxy in
            let width = proxy.size.width
            let x = fraction(value) * width

            ZStack(alignment: .leading) {
                Capsule().fill(skin.color(track.fill)).frame(height: track.height)
                Capsule().fill(skin.color(track.activeFill)).frame(width: max(x, 0), height: track.height)
                Circle()
                    .fill(skin.color(thumb.fill))
                    .frame(width: thumb.size, height: thumb.size)
                    .shadow(
                        color: skin.color(thumb.glow.color, state: state),
                        radius: thumb.glow.radius.resolve(state)
                    )
                    .scaleEffect(dragging && !reduceMotion ? thumb.dragScale : 1.0)
                    .offset(x: x - thumb.offset)
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
        .frame(height: track.rowHeight)
        .animation(AinkradMotion.hover, value: dragging)
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.xs)
        .background(containerShape.fill(skin.color(container.containerFill)))
        .overlay(
            containerShape.strokeBorder(
                skin.color(container.containerStroke.color), lineWidth: container.containerStroke.width.resolve([]))
        )
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
