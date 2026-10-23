import AinkradAppKitContract
import SwiftUI

/// The colour of a chart mark, named after the skin palette role it reads —
/// a chart never carries a colour of its own, so a theme recolours every chart.
/// `muted` is the skin's faint text colour (a committed-but-not-done bar, a
/// series that should recede).
public enum AinkradChartTone: String, CaseIterable, Sendable {
    case accentPrimary, accentSecondary, accentTertiary, success, warning, danger, muted

    func color(_ skin: AinkradSkin) -> Color {
        switch self {
        case .accentPrimary: skin.color(skin.palette.accentPrimary)
        case .accentSecondary: skin.color(skin.palette.accentSecondary)
        case .accentTertiary: skin.color(skin.palette.accentTertiary)
        case .success: skin.color(skin.palette.success)
        case .warning: skin.color(skin.palette.warning)
        case .danger: skin.color(skin.palette.danger)
        case .muted: skin.color(skin.text.faint)
        }
    }
}

/// One value on a line or scatter chart. `label` is what VoiceOver reads for
/// the x position ("Oct 3", "CIT-42"); without one it reads `x`.
public struct AinkradChartPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var label: String?

    public init(x: Double, y: Double, label: String? = nil) {
        self.x = x
        self.y = y
        self.label = label
    }
}

/// A named run of points: one line of a line chart, one colour of dots on a
/// scatter. `isDashed` draws a line dashed — a burndown's ideal line.
public struct AinkradChartSeries: Equatable, Sendable {
    public var name: String
    public var points: [AinkradChartPoint]
    public var tone: AinkradChartTone
    public var isDashed: Bool

    public init(
        name: String, points: [AinkradChartPoint], tone: AinkradChartTone = .accentSecondary, isDashed: Bool = false
    ) {
        self.name = name
        self.points = points
        self.tone = tone
        self.isDashed = isDashed
    }
}

/// A dashed horizontal line across the plot — a warn line, an average, a p85.
public struct AinkradChartThreshold: Equatable, Sendable {
    public var value: Double
    public var label: String?
    public var tone: AinkradChartTone

    public init(value: Double, label: String? = nil, tone: AinkradChartTone = .warning) {
        self.value = value
        self.label = label
        self.tone = tone
    }
}

/// A label under the x axis of a line or scatter chart, at `x`. A chart with
/// none shows no x axis.
public struct AinkradChartAxisLabel: Equatable, Sendable {
    public var x: Double
    public var text: String

    public init(x: Double, text: String) {
        self.x = x
        self.text = text
    }
}

/// One part of a bar: a stacked bar has several, stacked bottom-up in order.
/// `name` keys the legend and is what VoiceOver reads.
public struct AinkradBarSegment: Equatable, Sendable {
    public var name: String
    public var value: Double
    public var tone: AinkradChartTone

    public init(name: String, value: Double, tone: AinkradChartTone = .accentSecondary) {
        self.name = name
        self.value = value
        self.tone = tone
    }
}

/// One bar of a bar chart. `label` is its category on the x axis, so labels
/// must be unique within a chart.
public struct AinkradChartBar: Equatable, Sendable {
    public var label: String
    public var segments: [AinkradBarSegment]

    public init(label: String, segments: [AinkradBarSegment]) {
        self.label = label
        self.segments = segments
    }

    /// A bar of one value. Its segment is unnamed, so it adds no legend entry.
    public init(label: String, value: Double, tone: AinkradChartTone = .accentSecondary) {
        self.init(label: label, segments: [AinkradBarSegment(name: "", value: value, tone: tone)])
    }
}

// MARK: - Shared chart chrome

/// The upper end of a chart's y scale: the largest value or threshold, with
/// headroom so a threshold label or the tallest mark is not clipped. Never 0.
func chartYMax(_ values: [Double], threshold: AinkradChartThreshold?) -> Double {
    let top = (values + [threshold?.value ?? 0]).max() ?? 0
    return top > 0 ? top * 1.1 : 1
}

/// The x domain covering every point and axis label; `nil` when it would be a
/// single value, which Swift Charts cannot scale to.
func chartXDomain(_ series: [AinkradChartSeries], labels: [AinkradChartAxisLabel]) -> ClosedRange<Double>? {
    let xs = series.flatMap { $0.points.map(\.x) } + labels.map(\.x)
    guard let low = xs.min(), let high = xs.max(), low < high else { return nil }
    return low...high
}

/// One legend entry per distinct non-empty name, in first-seen order.
typealias ChartLegendEntry = (name: String, tone: AinkradChartTone)

func chartLegendEntries(_ entries: [ChartLegendEntry]) -> [ChartLegendEntry] {
    var seen = Set<String>()
    return entries.filter { !$0.name.isEmpty && seen.insert($0.name).inserted }
}

/// What every kit chart shares: the legend row, the empty state, the
/// accessibility summary, and the draw-in. `content` gets the draw-in progress
/// (0 → 1): bars grow from the baseline with it, lines and dots are revealed
/// left to right. The draw-in runs once on appear and data changes morph, both
/// only while the motion budget animates and Reduce Motion is off — otherwise
/// the chart is drawn complete.
struct AinkradChartFrame<Content: View, Value: Equatable>: View {
    let title: String
    let legend: [ChartLegendEntry]
    let isEmpty: Bool
    let emptyMessage: String
    let value: Value
    @ViewBuilder let content: (Double) -> Content
    @State private var hasAppeared = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @Environment(\.ainkradMotionBudget) private var budget

    private var animates: Bool { !reduceMotion && budget.isAnimating }
    private var drawIn: AinkradAnimationToken { AinkradAnimationToken(curve: "easeOut", durationKey: "slow") }

    var body: some View {
        VStack(alignment: .leading, spacing: skin.size.s6) {
            if legend.count > 1 {
                HStack(spacing: skin.size.s12) {
                    Spacer(minLength: 0)
                    ForEach(Array(legend.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: skin.size.s4) {
                            skin.shape(cut: skin.size.s2).fill(entry.tone.color(skin))
                                .frame(width: skin.size.s8, height: skin.size.s8)
                            Text(entry.name)
                        }
                    }
                }
                .font(skin.font(AinkradFontToken(sizeKey: "t11")))
                .foregroundStyle(skin.color(skin.text.muted))
                .accessibilityHidden(true)
            }
            if isEmpty {
                Text(emptyMessage)
                    .font(skin.font(AinkradFontToken(sizeKey: "t11")))
                    .foregroundStyle(skin.color(skin.text.faint))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content(animates && !hasAppeared ? 0 : 1)
                    .animation(animates ? skin.animation(drawIn) : nil, value: value)
            }
        }
        .accessibilityElement(children: isEmpty ? .combine : .contain)
        .accessibilityLabel(title)
        .onAppear {
            guard animates, !hasAppeared else { return }
            withAnimation(skin.animation(drawIn)) { hasAppeared = true }
        }
    }
}

extension View {
    /// Reveals a line or scatter plot left to right as `progress` goes 0 → 1.
    func chartReveal(_ progress: Double) -> some View {
        mask(alignment: .leading) {
            GeometryReader { proxy in
                Rectangle().frame(width: proxy.size.width * progress)
            }
        }
    }
}
