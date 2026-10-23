import AinkradAppKitContract
import Charts
import SwiftUI

// The kit's chart family, on Swift Charts. Every colour, font, size and the
// draw-in come from the skin, so Neon and Glass both follow the theme; no
// y axis and no grid (the mockups have neither), an optional dashed threshold,
// a legend once there is more than one series, an empty state, and a
// VoiceOver label and value on every mark. Size a chart with `.frame`.

/// A line chart — burndown, spend over time — with an optional area fill
/// under its solid lines and a dashed threshold (a warn line).
public struct AinkradLineChart: View {
    private let title: String
    private let series: [AinkradChartSeries]
    private let threshold: AinkradChartThreshold?
    private let axisLabels: [AinkradChartAxisLabel]
    private let fillsArea: Bool
    private let emptyMessage: String
    private let format: @Sendable (Double) -> String
    /// Set by the sparkline: no legend.
    var showsLegend = true
    @Environment(\.ainkradSkin) private var skin

    /// - Parameters:
    ///   - title: what VoiceOver calls the chart.
    ///   - fillsArea: shade under each solid line in its tone.
    ///   - format: how VoiceOver reads a y value ("$18.40", "11 pts").
    public init(
        title: String, series: [AinkradChartSeries], threshold: AinkradChartThreshold? = nil,
        axisLabels: [AinkradChartAxisLabel] = [], fillsArea: Bool = false, emptyMessage: String = "No data yet",
        format: @escaping @Sendable (Double) -> String = { $0.formatted() }
    ) {
        self.title = title
        self.series = series
        self.threshold = threshold
        self.axisLabels = axisLabels
        self.fillsArea = fillsArea
        self.emptyMessage = emptyMessage
        self.format = format
    }

    public var body: some View {
        let yMax = chartYMax(series.flatMap { $0.points.map(\.y) }, threshold: threshold)
        AinkradChartFrame(
            title: title, legend: showsLegend ? chartLegendEntries(series.map { ($0.name, $0.tone) }) : [],
            isEmpty: series.allSatisfy(\.points.isEmpty), emptyMessage: emptyMessage, value: series
        ) { progress in
            Chart {
                ForEach(Array(series.enumerated()), id: \.offset) { _, line in
                    let color = line.tone.color(skin)
                    ForEach(Array(line.points.enumerated()), id: \.offset) { _, point in
                        if fillsArea && !line.isDashed {
                            AreaMark(
                                x: .value("x", point.x), y: .value("y", point.y),
                                series: .value("series", line.name)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color.opacity(skin.opacity.o22), .clear], startPoint: .top,
                                    endPoint: .bottom)
                            )
                            .accessibilityHidden(true)
                        }
                        LineMark(x: .value("x", point.x), y: .value("y", point.y), series: .value("series", line.name))
                            .foregroundStyle(color)
                            .lineStyle(
                                line.isDashed
                                    ? StrokeStyle(lineWidth: skin.size.s1_5, dash: [skin.size.s4, skin.size.s4])
                                    : StrokeStyle(lineWidth: skin.size.s2, lineCap: .round, lineJoin: .round)
                            )
                            .accessibilityLabel("\(line.name), \(point.label ?? point.x.formatted())")
                            .accessibilityValue(format(point.y))
                    }
                }
                ChartThresholdMark(threshold: threshold, format: format, skin: skin)
            }
            .chartYScale(domain: 0...yMax)
            .apply { chart in
                if let domain = chartXDomain(series, labels: axisLabels) {
                    chart.chartXScale(domain: domain, range: .plotDimension(padding: skin.size.s6))
                } else {
                    chart
                }
            }
            .chartThresholdAxis(threshold)
            .chartAxisLabels(axisLabels)
            .chartReveal(progress)
        }
    }
}

/// A tiny trend line with no axes and no legend — a tile's "spend today".
/// Sized by its frame; the threshold is the warn line.
public struct AinkradSparkline: View {
    private let chart: AinkradLineChart

    public init(
        title: String, values: [Double], tone: AinkradChartTone = .accentSecondary,
        threshold: AinkradChartThreshold? = nil, fillsArea: Bool = true,
        format: @escaping @Sendable (Double) -> String = { $0.formatted() }
    ) {
        let points = values.enumerated().map { AinkradChartPoint(x: Double($0.offset), y: $0.element) }
        var chart = AinkradLineChart(
            title: title, series: [AinkradChartSeries(name: title, points: points, tone: tone)],
            threshold: threshold, fillsArea: fillsArea, emptyMessage: "", format: format)
        chart.showsLegend = false
        self.chart = chart
    }

    public var body: some View { chart }
}

/// A bar chart — velocity, per-day spend. A bar of several segments stacks
/// them bottom-up (priced / unpriced / subscription); a muted top segment reads
/// as "committed but not done". Bars grow from the baseline on draw-in.
public struct AinkradBarChart: View {
    private let title: String
    private let bars: [AinkradChartBar]
    private let threshold: AinkradChartThreshold?
    private let emptyMessage: String
    private let format: @Sendable (Double) -> String
    @Environment(\.ainkradSkin) private var skin

    public init(
        title: String, bars: [AinkradChartBar], threshold: AinkradChartThreshold? = nil,
        emptyMessage: String = "No data yet", format: @escaping @Sendable (Double) -> String = { $0.formatted() }
    ) {
        self.title = title
        self.bars = bars
        self.threshold = threshold
        self.emptyMessage = emptyMessage
        self.format = format
    }

    public var body: some View {
        let totals = bars.map { $0.segments.reduce(0) { $0 + max($1.value, 0) } }
        let yMax = chartYMax(totals, threshold: threshold)
        AinkradChartFrame(
            title: title, legend: chartLegendEntries(bars.flatMap { $0.segments.map { ($0.name, $0.tone) } }),
            isEmpty: bars.isEmpty, emptyMessage: emptyMessage, value: bars
        ) { progress in
            Chart {
                ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                    ForEach(Array(bar.segments.enumerated()), id: \.offset) { _, segment in
                        // Keyed by position, not label: two bars sharing a label ("T" for
                        // Tuesday and Thursday) stacked into one bar taller than the y scale,
                        // which drew up over the legend.
                        BarMark(
                            x: .value("bar", chartBarKey(index)), y: .value("value", max(segment.value, 0) * progress),
                            width: .ratio(0.6)
                        )
                        .foregroundStyle(segment.tone.color(skin))
                        .cornerRadius(skin.usesNativeGlass ? skin.size.s2 : 0)
                        .accessibilityLabel(segment.name.isEmpty ? bar.label : "\(bar.label), \(segment.name)")
                        .accessibilityValue(format(segment.value))
                    }
                }
                ChartThresholdMark(threshold: threshold, format: format, skin: skin)
            }
            .chartYScale(domain: 0...yMax)
            .chartThresholdAxis(threshold)
            .chartXAxis {
                AxisMarks { value in
                    // Greedy: a label that would touch its neighbour is dropped, so dense bars never read "Oct 10Oct 11".
                    AxisValueLabel(collisionResolution: .greedy(minimumSpacing: skin.size.s6)) {
                        Text(chartBarLabel(value.as(String.self), bars: bars))
                    }
                    .font(skin.font(AinkradFontToken(sizeKey: "t10", mono: "family")))
                    .foregroundStyle(skin.color(skin.text.faint))
                }
            }
        }
    }
}

/// A bar's x category: its position, so bars that share a label stay apart.
func chartBarKey(_ index: Int) -> String { "\(index)" }

/// The axis text for a bar's category key.
func chartBarLabel(_ key: String?, bars: [AinkradChartBar]) -> String {
    guard let key, let index = Int(key), bars.indices.contains(index) else { return "" }
    return bars[index].label
}

/// A scatter chart — cycle vs lead time, one dot colour per series, with a
/// dashed threshold (the p85 line). Dots are revealed left to right on draw-in.
public struct AinkradScatterChart: View {
    private let title: String
    private let series: [AinkradChartSeries]
    private let threshold: AinkradChartThreshold?
    private let axisLabels: [AinkradChartAxisLabel]
    private let emptyMessage: String
    private let format: @Sendable (Double) -> String
    @Environment(\.ainkradSkin) private var skin

    public init(
        title: String, series: [AinkradChartSeries], threshold: AinkradChartThreshold? = nil,
        axisLabels: [AinkradChartAxisLabel] = [], emptyMessage: String = "No data yet",
        format: @escaping @Sendable (Double) -> String = { $0.formatted() }
    ) {
        self.title = title
        self.series = series
        self.threshold = threshold
        self.axisLabels = axisLabels
        self.emptyMessage = emptyMessage
        self.format = format
    }

    public var body: some View {
        let yMax = chartYMax(series.flatMap { $0.points.map(\.y) }, threshold: threshold)
        AinkradChartFrame(
            title: title, legend: chartLegendEntries(series.map { ($0.name, $0.tone) }),
            isEmpty: series.allSatisfy(\.points.isEmpty), emptyMessage: emptyMessage, value: series
        ) { progress in
            Chart {
                ForEach(Array(series.enumerated()), id: \.offset) { _, dots in
                    ForEach(Array(dots.points.enumerated()), id: \.offset) { _, point in
                        PointMark(x: .value("x", point.x), y: .value("y", point.y))
                            .foregroundStyle(dots.tone.color(skin))
                            .symbolSize(skin.size.s50)
                            .accessibilityLabel("\(dots.name), \(point.label ?? point.x.formatted())")
                            .accessibilityValue(format(point.y))
                    }
                }
                ChartThresholdMark(threshold: threshold, format: format, skin: skin)
            }
            .chartYScale(domain: 0...yMax)
            .apply { chart in
                if let domain = chartXDomain(series, labels: axisLabels) {
                    chart.chartXScale(domain: domain, range: .plotDimension(padding: skin.size.s6))
                } else {
                    chart
                }
            }
            .chartThresholdAxis(threshold)
            .chartAxisLabels(axisLabels)
            .chartReveal(progress)
        }
    }
}

/// The dashed threshold rule, drawn above every mark. Its label is not
/// annotated in the plot, where a mark can cover it: `chartThresholdAxis`
/// puts it in the trailing gutter, level with the line.
private struct ChartThresholdMark: ChartContent {
    let threshold: AinkradChartThreshold?
    let format: @Sendable (Double) -> String
    let skin: AinkradSkin

    var body: some ChartContent {
        if let threshold {
            RuleMark(y: .value("threshold", threshold.value))
                .foregroundStyle(threshold.tone.color(skin))
                .lineStyle(StrokeStyle(lineWidth: skin.size.s1, dash: [skin.size.s4, skin.size.s4]))
                .zIndex(1)
                .accessibilityLabel(threshold.label ?? "Threshold")
                .accessibilityValue(format(threshold.value))
        }
    }
}

extension View {
    /// No y axis — except the threshold's label, as the one mark of a trailing
    /// axis: Swift Charts reserves its gutter, so the label never sits on a mark.
    @ViewBuilder fileprivate func chartThresholdAxis(_ threshold: AinkradChartThreshold?) -> some View {
        if let threshold, let label = threshold.label {
            modifier(ChartThresholdAxis(value: threshold.value, label: label))
        } else {
            chartYAxis(.hidden)
        }
    }

    /// The x axis of a line or scatter chart: just `labels`, mono and faint;
    /// hidden when there are none.
    @ViewBuilder fileprivate func chartAxisLabels(_ labels: [AinkradChartAxisLabel]) -> some View {
        if labels.isEmpty {
            chartXAxis(.hidden)
        } else {
            modifier(ChartAxisLabels(labels: labels))
        }
    }
}

private struct ChartThresholdAxis: ViewModifier {
    let value: Double
    let label: String
    @Environment(\.ainkradSkin) private var skin

    func body(content: Content) -> some View {
        content.chartYAxis {
            AxisMarks(position: .trailing, values: [value]) { _ in
                AxisValueLabel(horizontalSpacing: skin.size.s6) {
                    Text(label)
                        .font(skin.font(AinkradFontToken(sizeKey: "t10", mono: "family")))
                        .foregroundStyle(skin.color(skin.text.faint))
                }
            }
        }
    }
}

private struct ChartAxisLabels: ViewModifier {
    let labels: [AinkradChartAxisLabel]
    @Environment(\.ainkradSkin) private var skin

    func body(content: Content) -> some View {
        content.chartXAxis {
            AxisMarks(values: labels.map(\.x)) { value in
                let x = value.as(Double.self)
                // The end labels hug the plot's edges, as the mockups' "Oct 13 … Oct 24".
                let anchor: UnitPoint =
                    x == labels.map(\.x).min() ? .topLeading : x == labels.map(\.x).max() ? .topTrailing : .top
                AxisValueLabel(anchor: anchor, collisionResolution: .greedy(minimumSpacing: skin.size.s6)) {
                    Text(labels.first { $0.x == x }?.text ?? "")
                        .font(skin.font(AinkradFontToken(sizeKey: "t10", mono: "family")))
                        .foregroundStyle(skin.color(skin.text.faint))
                }
            }
        }
    }
}
