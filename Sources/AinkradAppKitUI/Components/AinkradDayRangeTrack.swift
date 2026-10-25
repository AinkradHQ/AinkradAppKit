import SwiftUI

/// A 24-hour range bar with two white handles: a 34 pt track, a gradient fill between the handles, a value tooltip
/// over a handle on hover or drag, and `00 · 06 · 12 · 18 · 24` ticks under it. A drag follows the pointer 1:1 and
/// settles onto 30 minutes on release (a spring, not under Reduce Motion); only then are `start` and `end` written.
/// The handle nearest where a drag begins moves. Hours are `0...24`. By default the handles stay at least an hour
/// apart; `wraps` lets the range run past midnight (quiet hours: `start` 22, `end` 7.5), drawn as two segments.
/// `isOn: false` greys the fill. `label` replaces the centred caption (a plain range shows `08:00 – 20:00`; a wrapped
/// one shows none).
public struct AinkradDayRangeTrack: View {
    @Binding private var start: Double
    @Binding private var end: Double
    private let wraps: Bool
    private let isOn: Bool
    private let label: String?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    /// The unsnapped values while a drag is live, and which handle (0 start, 1 end) it holds.
    @State private var live: [Double]?
    @State private var holding: Int?
    @State private var hovered: Int?

    static let minimumGap = 1.0
    static let step = 0.5

    public init(
        start: Binding<Double>, end: Binding<Double>, wraps: Bool = false, isOn: Bool = true, label: String? = nil
    ) {
        self._start = start
        self._end = end
        self.wraps = wraps
        self.isOn = isOn
        self.label = label
    }

    private var shown: [Double] { live ?? [start, end] }

    public var body: some View {
        VStack(spacing: skin.size.s4) {
            GeometryReader { geo in track(width: geo.size.width) }
                .frame(height: skin.size.s34)
            ticks
        }
        .accessibilityElement(children: .contain)
    }

    private func track(width: CGFloat) -> some View {
        let values = shown
        let shape = RoundedRectangle(cornerRadius: skin.size.s11, style: .continuous)
        let spring = AinkradAnimationToken(curve: "spring", response: 0.3, damping: 0.7)
        return ZStack(alignment: .topLeading) {
            shape.fill(skin.color(.palette("background", skin.opacity.o25)))
                .overlay(shape.strokeBorder(skin.color(.palette("foreground", skin.opacity.o05)), lineWidth: 1))
            ForEach(Array(Self.segments(values[0], values[1], wraps: wraps).enumerated()), id: \.offset) { _, seg in
                RoundedRectangle(cornerRadius: skin.size.s8, style: .continuous)
                    .fill(fill)
                    .frame(width: max(0, (seg.upperBound - seg.lowerBound) / 24 * width), height: skin.size.s26)
                    .offset(x: seg.lowerBound / 24 * width, y: skin.size.s4)
            }
            if let caption = label ?? (wraps ? nil : "\(Self.clock(values[0])) – \(Self.clock(values[1]))") {
                Text(caption).kitFont("t11", weight: "semibold", mono: true)
                    .foregroundStyle(skin.color(.palette("foreground", 1)))
                    .fixedSize()
                    .position(
                        x: (wraps ? values[0] / 24 * width + skin.size.s40 : (values[0] + values[1]) / 48 * width),
                        y: (skin.size.s34 / 2)
                    )
                    .allowsHitTesting(false)
            }
            ForEach(0..<2, id: \.self) { index in
                handle(index, value: values[index], width: width)
            }
        }
        .frame(width: width, height: skin.size.s34)
        .contentShape(Rectangle())
        .gesture(drag(width: width))
        .onContinuousHover { phase in
            switch phase {
            case .active(let point):
                hovered = (0..<2).first { abs(point.x - shown[$0] / 24 * width) <= skin.size.s10 }
            case .ended: hovered = nil
            }
        }
        .animation(reduceMotion || live != nil ? nil : skin.animation(spring), value: values)
    }

    private var fill: some ShapeStyle {
        isOn
            ? AnyShapeStyle(
                LinearGradient(
                    colors: [
                        skin.color(skin.palette.accentPrimary).opacity(skin.opacity.o55),
                        skin.color(skin.palette.accentSecondary).opacity(skin.opacity.o55),
                    ], startPoint: .leading, endPoint: .trailing))
            : AnyShapeStyle(skin.color(.palette("foreground", skin.opacity.o08)))
    }

    private func handle(_ index: Int, value: Double, width: CGFloat) -> some View {
        let active = holding == index || (holding == nil && hovered == index)
        let accent = skin.color(skin.palette.accentPrimary)
        return RoundedRectangle(cornerRadius: skin.size.s4, style: .continuous)
            .fill(skin.color(.palette("foreground", 1)))
            .frame(width: skin.size.s6, height: skin.size.s22)
            .background(
                RoundedRectangle(cornerRadius: skin.size.s6, style: .continuous)
                    .fill(accent.opacity(active ? skin.opacity.o45 : skin.opacity.o35))
                    .padding(active ? -skin.size.s5 : -skin.size.s3)
            )
            .shadow(color: skin.color(.palette("black", skin.opacity.o40)), radius: skin.size.s3, y: skin.size.s2)
            .scaleEffect(y: active ? 1.15 : 1)
            .overlay(alignment: .top) {
                Text(Self.clock(value)).kitFont("t10_5", weight: "semibold", mono: true)
                    .foregroundStyle(skin.color(.palette("foreground", 1)))
                    .padding(.horizontal, skin.size.s7)
                    .padding(.vertical, skin.size.s3)
                    .background(
                        skin.color(.palette("background", skin.opacity.o96)),
                        in: RoundedRectangle(cornerRadius: skin.size.s7, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: skin.size.s7, style: .continuous)
                            .strokeBorder(skin.color(.palette("foreground", skin.opacity.o10)), lineWidth: 1)
                    )
                    .fixedSize()
                    .offset(y: -skin.size.s34)
                    .opacity(active ? 1 : 0)
                    .offset(y: active || reduceMotion ? 0 : skin.size.s4)
                    .allowsHitTesting(false)
            }
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: active)
            .position(x: value / 24 * width, y: (skin.size.s34 / 2))
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(index == 0 ? "Start" : "End")
            .accessibilityValue(Self.clock(value))
            .accessibilityAdjustableAction { direction in
                guard direction == .increment || direction == .decrement else { return }
                nudge(index, by: direction == .increment ? Self.step : -Self.step)
            }
    }

    private var ticks: some View {
        HStack {
            ForEach([0, 6, 12, 18, 24], id: \.self) { hour in
                Text(String(format: "%02d", hour))
                if hour != 24 { Spacer(minLength: 0) }
            }
        }
        .kitFont("t9_5", mono: true)
        .foregroundStyle(skin.color(skin.text.faint))
    }

    private func drag(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                let width = max(width, 1)
                if holding == nil {
                    let grab = gesture.startLocation.x / width * 24
                    holding = abs(grab - start) <= abs(grab - end) ? 0 : 1
                    live = [start, end]
                }
                guard let holding, var raw = live else { return }
                let hour = min(24, max(0, gesture.location.x / width * 24))
                raw[holding] = Self.constrain(hour, handle: holding, other: raw[1 - holding], wraps: wraps)
                live = raw
            }
            .onEnded { _ in
                guard let holding, let raw = live else { return }
                let settle = AinkradAnimationToken(curve: "spring", response: 0.3, damping: 0.7)
                withAnimation(reduceMotion ? nil : skin.animation(settle)) {
                    commit(holding, to: raw[holding])
                    live = nil
                }
                self.holding = nil
            }
    }

    private func nudge(_ index: Int, by delta: Double) {
        let current = index == 0 ? start : end
        let other = index == 0 ? end : start
        commit(index, to: Self.constrain(current + delta, handle: index, other: other, wraps: wraps))
    }

    /// Writes `raw` snapped to a half hour, kept an hour from the handle that did not move.
    private func commit(_ index: Int, to raw: Double) {
        let other = index == 0 ? end : start
        let value = Self.constrain(Self.snap(raw, wraps: wraps), handle: index, other: other, wraps: wraps)
        if index == 0 { start = value } else { end = value }
    }

    /// `hour` limited to the track and, for a plain range, to an hour from `other`.
    static func constrain(_ hour: Double, handle: Int, other: Double, wraps: Bool) -> Double {
        let hour = min(24, max(0, hour))
        if wraps { return hour }
        return handle == 0 ? min(hour, other - minimumGap) : max(hour, other + minimumGap)
    }

    /// `hour` to the nearest half hour; a wrapped range reads 24 as midnight.
    static func snap(_ hour: Double, wraps: Bool) -> Double {
        let snapped = (hour / step).rounded() * step
        return wraps && snapped >= 24 ? 0 : snapped
    }

    /// The hour spans drawn for a range: one, or two (to 24, then from 0) when it wraps past midnight.
    static func segments(_ start: Double, _ end: Double, wraps: Bool) -> [ClosedRange<Double>] {
        wraps && start > end ? [start...24, 0...end] : [min(start, end)...max(start, end)]
    }

    /// `09:30` for 9.5, `00:00` for 24.
    public static func clock(_ hour: Double) -> String {
        let halves = Int((hour * 2).rounded())
        return String(format: "%02d:%02d", (halves / 2) % 24, halves % 2 * 30)
    }
}
