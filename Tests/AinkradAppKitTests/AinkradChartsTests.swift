import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("Kit charts, tool card and chat bubble")
@MainActor
struct AinkradChartsTests {
    @Test("the y scale tops the largest value or threshold, with headroom, and is never 0")
    func yMax() {
        #expect(chartYMax([10, 20], threshold: nil) == 22)
        #expect(chartYMax([10], threshold: AinkradChartThreshold(value: 40)) == 44)
        #expect(chartYMax([], threshold: nil) == 1)
        #expect(chartYMax([0, -3], threshold: nil) == 1)
    }

    @Test("the x domain spans points and axis labels; a single x has none")
    func xDomain() {
        let series = [AinkradChartSeries(name: "a", points: [AinkradChartPoint(x: 2, y: 1), .init(x: 5, y: 1)])]
        #expect(chartXDomain(series, labels: []) == 2...5)
        #expect(chartXDomain(series, labels: [AinkradChartAxisLabel(x: 10, text: "end")]) == 2...10)
        #expect(chartXDomain([AinkradChartSeries(name: "a", points: [.init(x: 1, y: 1)])], labels: []) == nil)
    }

    @Test("the legend keeps one entry per name, in first-seen order")
    func legend() {
        let entries = chartLegendEntries([("Priced", .accentSecondary), ("Unpriced", .warning), ("Priced", .danger)])
        #expect(entries.map(\.name) == ["Priced", "Unpriced"])
        #expect(entries.first?.tone == .accentSecondary)
        // A one-value bar is unnamed: a chart of them has no legend, however many bars.
        let bars = (1...31).map { AinkradChartBar(label: "Oct \($0)", value: 1) }
        #expect(chartLegendEntries(bars.flatMap { $0.segments.map { ($0.name, $0.tone) } }).isEmpty)
    }

    @Test("every tone reads a skin colour, so a theme recolours it")
    func tonesFollowSkin() {
        var skin = AinkradSkin.standard
        let before = AinkradChartTone.accentSecondary.color(skin)
        skin.palette.accentSecondary = skin.palette.danger
        #expect(AinkradChartTone.accentSecondary.color(skin) != before)
        #expect(AinkradChartTone.accentSecondary.color(skin) == AinkradChartTone.danger.color(skin))
    }

    static func height(_ view: some View, width: CGFloat = 500) -> CGFloat {
        let host = NSHostingView(rootView: view.frame(width: width).ainkradSkin(.standard))
        return host.fittingSize.height
    }

    @Test("a tool card shows its detail when expanded or waiting, not at rest")
    func toolCardDetail() {
        func card(_ status: AinkradToolCardStatus, expanded: Bool) -> some View {
            AinkradToolCard(name: "Bash", argument: "ls", status: status, isInitiallyExpanded: expanded) {
                Color.clear.frame(height: 80)
            }
        }
        let rest = Self.height(card(.succeeded, expanded: false))
        #expect(Self.height(card(.succeeded, expanded: true)) > rest + 70)
        #expect(Self.height(card(.waiting, expanded: false)) > rest + 70)
    }

    @Test("a bubble's header shows only with an author or meta")
    func bubbleHeader() {
        let bare = Self.height(AinkradChatBubble(text: "Hello"))
        #expect(Self.height(AinkradChatBubble(text: "Hello", author: "You", meta: "09:40")) > bare)
        #expect(Self.height(AinkradChatBubble(text: "Hello", role: .agent, author: "Quill")) > 0)
    }
}
