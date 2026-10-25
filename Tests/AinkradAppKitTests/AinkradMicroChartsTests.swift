import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("Promoted Citadel charts")
@MainActor
struct AinkradMicroChartsTests {
    @Test("a trend line spans its box, inset, newest value last, and is empty below two values")
    func trendPoints() {
        let points = AinkradMicroTrend.points([0, 5, 10], in: CGSize(width: 100, height: 40), inset: 4)
        #expect(points.count == 3)
        #expect(points.first == CGPoint(x: 4, y: 36))
        #expect(points.last == CGPoint(x: 96, y: 4))
        #expect(AinkradMicroTrend.points([3], in: CGSize(width: 100, height: 40), inset: 4).isEmpty)
    }

    @Test("donut arcs tile the ring in order, less the gap, and a lone arc keeps its whole length")
    func donutArcs() {
        let segments = [
            AinkradDonutSegment(id: 0, value: 1, color: .red), AinkradDonutSegment(id: 1, value: 3, color: .blue),
        ]
        let arcs = AinkradSegmentDonut<EmptyView>.arcs(segments, circumference: 100, gap: 2)
        #expect(arcs[0].from == 0 && abs(arcs[0].length - 0.23) < 1e-9)
        #expect(abs(arcs[1].from - 0.25) < 1e-9 && abs(arcs[1].length - 0.73) < 1e-9)
        let lone = AinkradSegmentDonut<EmptyView>.arcs([segments[0]], circumference: 100, gap: 2)
        #expect(lone[0].length == 1)
    }

    @Test("every chart draws")
    func chartsDraw() {
        let view = VStack(alignment: .leading, spacing: 10) {
            AinkradHeatmap(rows: ["Mon", "Tue"], columns: ["0", "6", "12"], values: [[1, 4, 9], [0, 2]])
            AinkradLegendBar(
                segments: [
                    AinkradLegendSegment(label: "Priced", value: 3, text: "$3", color: .blue),
                    AinkradLegendSegment(label: "Unpriced", value: 1, text: "$1", color: .orange),
                ])
            AinkradMarkerGauge(
                fill: 0.6, nowLabel: "6M", ticks: [AinkradGaugeTick(fraction: 0.8, label: "warn")], marker: 0.7
            )
            .frame(width: 280)
            HStack {
                AinkradMicroTrend(values: [1, 3, 2, 5], tint: .blue)
                AinkradMicroTrend(values: [1, 3, 2, 5], tint: .teal, style: .area).frame(width: 90, height: 34)
                AinkradSegmentDonut(
                    segments: [AinkradDonutSegment(id: 0, value: 2, color: .green)], diameter: 60, lineWidth: 10)
            }
            AinkradShareBar(parts: [(2, .blue), (1, .pink)])
            AinkradFillTrack(fraction: 0.4, fill: AnyShapeStyle(Color.green))
        }
        #expect(PromotedRender.draws(view, width: 360, height: 360))
    }

    @Test("a stacked bar chart, its tip and its swatch draw")
    func stackedDraws() {
        let bars = (0..<6).map {
            AinkradStackedBar(
                id: $0,
                segments: [
                    AinkradStackedSegment(value: Double($0 + 1), fill: AnyShapeStyle(Color.blue)),
                    AinkradStackedSegment(value: 1, fill: AnyShapeStyle(Color.orange)),
                ])
        }
        let view = VStack(alignment: .leading) {
            AinkradStackedBarChart(bars: bars, threshold: 5) { _ in AinkradChartTip { Text("Tue") } }
                .frame(height: 120)
            AinkradLegendSwatch(color: .blue, label: "Priced")
        }
        #expect(PromotedRender.draws(view, width: 360, height: 200))
        #expect(bars[2].total == 4)
    }
}
