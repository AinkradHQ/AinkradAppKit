import SwiftUI

/// A small trend line through `values` (oldest first). `.pointer` is a 90 by 34 line scaled between its own low and
/// high with a dot on the newest value; `.area` is a 2 pt line over a soft area fill scaled to its own maximum and
/// sized by its frame.
public struct AinkradMicroTrend: View {
    public enum Style: Sendable { case pointer, area }

    private let values: [Double]
    private let tint: Color
    private let style: Style
    @Environment(\.ainkradSkin) private var skin

    public init(values: [Double], tint: Color, style: Style = .pointer) {
        self.values = values
        self.tint = tint
        self.style = style
    }

    public var body: some View {
        switch style {
        case .pointer: pointer
        case .area:
            ZStack {
                AreaShape(values: values, closed: true).fill(tint.opacity(skin.opacity.o12))
                AreaShape(values: values, closed: false)
                    .stroke(tint, style: StrokeStyle(lineWidth: skin.size.s2, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private var pointer: some View {
        GeometryReader { geo in
            let points = Self.points(values, in: geo.size, inset: skin.size.s4)
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
            }
            .stroke(tint, style: StrokeStyle(lineWidth: skin.size.s2_5, lineCap: .round, lineJoin: .round))
            if let last = points.last {
                Circle().fill(tint).frame(width: skin.size.s6, height: skin.size.s6)
                    .position(last)
            }
        }
        .frame(width: skin.size.s90, height: skin.size.s34)
    }

    /// The line's points in `size`, `inset` from every edge; empty for fewer than two values.
    static func points(_ values: [Double], in size: CGSize, inset: CGFloat) -> [CGPoint] {
        guard values.count > 1, let low = values.min(), let high = values.max() else { return [] }
        let span = max(high - low, 1)
        let step = (size.width - inset * 2) / CGFloat(values.count - 1)
        return values.enumerated().map { index, value in
            CGPoint(
                x: inset + CGFloat(index) * step,
                y: inset + (size.height - inset * 2) * CGFloat(1 - (value - low) / span))
        }
    }
}

private struct AreaShape: Shape {
    let values: [Double]
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard !values.isEmpty else { return path }
        let top = max(values.max() ?? 1, 1)
        let count = max(1, values.count - 1)
        let points = values.enumerated().map { index, value in
            CGPoint(
                x: rect.minX + rect.width * CGFloat(index) / CGFloat(count),
                y: rect.minY + rect.height * (1 - 0.06 - 0.8 * CGFloat(value / top)))
        }
        if closed {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            points.forEach { path.addLine(to: $0) }
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        } else {
            path.move(to: points[0])
            points.dropFirst().forEach { path.addLine(to: $0) }
        }
        return path
    }
}

/// One arc of an `AinkradSegmentDonut`.
public struct AinkradDonutSegment: Identifiable {
    public let id: Int
    public var value: Double
    public var color: Color

    public init(id: Int, value: Double, color: Color) {
        self.id = id
        self.value = value
        self.color = color
    }
}

/// A segmented ring (a cost breakdown, an accounts health donut): arcs of any colour grow in over a second, 120 ms
/// apart (drawn at once under Reduce Motion), with `gap` points between them and `center` in the middle.
public struct AinkradSegmentDonut<Center: View>: View {
    private let segments: [AinkradDonutSegment]
    private let diameter: CGFloat
    private let lineWidth: CGFloat
    private let gap: CGFloat
    private let center: Center
    @Environment(\.ainkradSkin) private var skin

    public init(
        segments: [AinkradDonutSegment], diameter: CGFloat, lineWidth: CGFloat, gap: CGFloat = 2,
        @ViewBuilder center: () -> Center
    ) {
        self.segments = segments
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.gap = gap
        self.center = center()
    }

    public var body: some View {
        let arcs = Self.arcs(segments, circumference: .pi * (diameter - lineWidth), gap: gap)
        ZStack {
            Circle().stroke(skin.color(.palette("foreground", skin.opacity.o05)), lineWidth: lineWidth)
            ForEach(Array(arcs.enumerated()), id: \.element.segment.id) { index, arc in
                DonutArc(
                    color: arc.segment.color, from: arc.from, length: arc.length, lineWidth: lineWidth,
                    delay: Double(index) * 0.12)
            }
            center
        }
        .frame(width: diameter, height: diameter)
        .padding(lineWidth / 2)
    }

    /// Where each arc starts and how long it is, as fractions of the ring, less a `gap` along the ring between arcs.
    static func arcs(_ segments: [AinkradDonutSegment], circumference: CGFloat, gap: CGFloat)
        -> [(segment: AinkradDonutSegment, from: Double, length: Double)]
    {
        let total = max(segments.map(\.value).reduce(0, +), 0.000_1)
        let gapFraction = segments.count > 1 ? Double(gap / circumference) : 0
        var start = 0.0
        return segments.map { segment in
            let length = segment.value / total
            defer { start += length }
            return (segment, start, max(0, length - gapFraction))
        }
    }
}

private struct DonutArc: View {
    let color: Color
    let from: Double
    let length: Double
    let lineWidth: CGFloat
    let delay: Double
    @State private var shown = 0.0
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .trim(from: from, to: from + length * shown)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            .rotationEffect(.degrees(-90))
            .onAppear {
                guard !reduceMotion else {
                    shown = 1
                    return
                }
                withAnimation(skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 1)).delay(delay)) {
                    shown = 1
                }
            }
            .onChange(of: [from, length]) { _, _ in
                guard !reduceMotion else { return }
                ainkradRegrow(
                    reset: { shown = 0 },
                    grow: {
                        let curve = skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 1))
                        withAnimation(curve.delay(delay)) { shown = 1 }
                    })
            }
    }
}

/// Re-runs a grow-in when a chart's data changes: `reset` collapses it without animating, then `grow` plays one
/// frame later so the collapse is drawn first.
@MainActor
func ainkradRegrow(reset: () -> Void, grow: @escaping @MainActor () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, reset)
    Task {
        try? await Task.sleep(for: .milliseconds(16))
        grow()
    }
}

extension AinkradSegmentDonut where Center == EmptyView {
    public init(segments: [AinkradDonutSegment], diameter: CGFloat, lineWidth: CGFloat, gap: CGFloat = 2) {
        self.init(segments: segments, diameter: diameter, lineWidth: lineWidth, gap: gap) { EmptyView() }
    }
}

/// A stacked share bar: one coloured part per value with a small gap, growing in from the left.
public struct AinkradShareBar: View {
    private let parts: [(value: Double, color: Color)]
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var shown = false

    public init(parts: [(value: Double, color: Color)]) { self.parts = parts }

    public var body: some View {
        GeometryReader { geo in
            let total = max(parts.map(\.value).reduce(0, +), 0.000_1)
            let gaps = skin.size.s2 * CGFloat(max(0, parts.count - 1))
            HStack(spacing: skin.size.s2) {
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    Rectangle().fill(part.color)
                        .frame(width: max(0, (geo.size.width - gaps) * CGFloat(part.value / total)))
                }
            }
            .scaleEffect(x: shown ? 1 : 0, anchor: .leading)
        }
        .frame(height: skin.size.s6)
        .background(skin.color(.palette("foreground", skin.opacity.o05)))
        .clipShape(RoundedRectangle(cornerRadius: skin.size.s4))
        .onAppear { grow(&shown, skin: skin, reduceMotion: reduceMotion) }
    }
}

/// A plain progress track: a rounded fill of `fraction` in a faint track, growing in.
public struct AinkradFillTrack: View {
    private let fraction: Double
    private let fill: AnyShapeStyle
    private let height: CGFloat?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var shown = false

    public init(fraction: Double, fill: AnyShapeStyle, height: CGFloat? = nil) {
        self.fraction = fraction
        self.fill = fill
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            Capsule().fill(fill)
                .frame(width: geo.size.width * CGFloat(min(max(fraction, 0), 1)) * (shown ? 1 : 0))
        }
        .frame(height: height ?? skin.size.s6)
        .background(Capsule().fill(skin.color(.palette("foreground", skin.opacity.o06))))
        .onAppear { grow(&shown, skin: skin, reduceMotion: reduceMotion) }
    }
}

/// Grows a bar in over 0.7 s, or at once under Reduce Motion.
@MainActor
private func grow(_ shown: inout Bool, skin: AinkradSkin, reduceMotion: Bool) {
    if reduceMotion {
        shown = true
    } else {
        withAnimation(skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 0.7))) { shown = true }
    }
}
