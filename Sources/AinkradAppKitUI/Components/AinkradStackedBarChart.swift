import SwiftUI

/// One segment of an `AinkradStackedBar`, bottom first.
public struct AinkradStackedSegment {
    public var value: Double
    public var fill: AnyShapeStyle

    public init(value: Double, fill: AnyShapeStyle) {
        self.value = value
        self.fill = fill
    }
}

/// One bar of an `AinkradStackedBarChart`: its segments bottom to top.
public struct AinkradStackedBar: Identifiable {
    public let id: Int
    public var segments: [AinkradStackedSegment]
    public var total: Double { segments.map(\.value).reduce(0, +) }

    public init(id: Int, segments: [AinkradStackedSegment]) {
        self.id = id
        self.segments = segments
    }
}

/// A stacked bar chart of gradient or flat segments: bars grow in 22 ms apart, a hovered bar brightens and shows
/// `tooltip(id)` beside it, and an optional dashed `threshold` line marks a limit in the bars' unit. (The kit's
/// `AinkradBarChart` takes chart tones only and has no hover card.)
public struct AinkradStackedBarChart<Tip: View>: View {
    private let bars: [AinkradStackedBar]
    private let threshold: Double?
    private let thresholdColor: Color?
    private let tooltip: (Int) -> Tip
    @State private var hovered: Int?
    @Environment(\.ainkradSkin) private var skin

    public init(
        bars: [AinkradStackedBar], threshold: Double? = nil, thresholdColor: Color? = nil,
        @ViewBuilder tooltip: @escaping (Int) -> Tip
    ) {
        self.bars = bars
        self.threshold = threshold
        self.thresholdColor = thresholdColor
        self.tooltip = tooltip
    }

    public var body: some View {
        GeometryReader { geo in
            let count = max(bars.count, 1)
            let step = geo.size.width / CGFloat(count)
            let width = min(skin.size.s26, step * 0.62)
            let top = max(threshold ?? 0, bars.map(\.total).max() ?? 0, 0.000_1) * 1.1
            let usable = geo.size.height - skin.size.s8
            ZStack(alignment: .topLeading) {
                if let threshold, threshold > 0 {
                    let y = geo.size.height - usable * CGFloat(threshold / top)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(
                        (thresholdColor ?? skin.color(skin.palette.warning)).opacity(skin.opacity.o70),
                        style: StrokeStyle(lineWidth: 1, dash: [skin.size.s4, skin.size.s5]))
                }
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(bars) { bar in
                        BarColumn(
                            bar: bar, width: width, scale: usable / CGFloat(top), isHovered: hovered == bar.id,
                            delay: Double(bar.id) * 0.022
                        )
                        .frame(width: step, height: geo.size.height, alignment: .bottom)
                        .contentShape(Rectangle())
                        .onHover { inside in
                            if inside {
                                hovered = bar.id
                            } else if hovered == bar.id {
                                hovered = nil
                            }
                        }
                    }
                }
                if let hovered, let index = bars.firstIndex(where: { $0.id == hovered }) {
                    tooltip(hovered)
                        .fixedSize()
                        .offset(
                            x: min(step * CGFloat(index) + step, geo.size.width - skin.size.s190),
                            y: skin.size.s4
                        )
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
        }
        .animation(skin.animation(skin.motion.hover), value: hovered)
    }
}

private struct BarColumn: View {
    let bar: AinkradStackedBar
    let width: CGFloat
    let scale: CGFloat
    let isHovered: Bool
    let delay: Double
    @State private var grown = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: skin.size.s1_5) {
            ForEach(Array(bar.segments.enumerated().reversed()), id: \.offset) { _, segment in
                if segment.value > 0 {
                    RoundedRectangle(cornerRadius: skin.size.s3, style: .continuous)
                        .fill(segment.fill)
                        .frame(width: width, height: max(skin.size.s1, CGFloat(segment.value) * scale - skin.size.s1_5))
                }
            }
        }
        .brightness(isHovered ? 0.18 : 0)
        .scaleEffect(y: grown ? 1 : 0, anchor: .bottom)
        .onAppear {
            guard !reduceMotion else {
                grown = true
                return
            }
            withAnimation(skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 0.55)).delay(delay)) {
                grown = true
            }
        }
        .animation(reduceMotion ? nil : skin.animation(.arrive), value: bar.segments.map(\.value))
        .onChange(of: bar.segments.count) { old, new in
            guard !reduceMotion, ainkradShouldRegrow(from: [old], to: [new]) else { return }
            ainkradRegrow(
                reset: { grown = false },
                grow: {
                    let curve = skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 0.55))
                    withAnimation(curve.delay(delay)) { grown = true }
                })
        }
    }
}

/// The chart's floating tooltip card: a small glass card of `content`.
public struct AinkradChartTip<Content: View>: View {
    private let content: Content
    @Environment(\.ainkradSkin) private var skin

    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s12, style: .continuous)
        VStack(alignment: .leading, spacing: skin.size.s3) { content }
            .kitFont("t11")
            .padding(.horizontal, skin.size.s11)
            .padding(.vertical, skin.size.s9)
            .frame(minWidth: skin.size.s168, alignment: .leading)
            .background(shape.fill(skin.color(.palette("background", skin.opacity.o95))))
            .overlay(shape.strokeBorder(skin.color(.palette("foreground", skin.opacity.o08)), lineWidth: 1))
            .shadow(color: skin.color(.palette("black", skin.opacity.o50)), radius: skin.size.s12, y: skin.size.s10)
    }
}
