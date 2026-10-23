import SwiftUI

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// The Citadel round: the chart family, the transcript tool card and the chat
/// bubble, with the data of the Citadel and Quest server mockups (cost 09,
/// home 02, run 05, chat 07, reports 05).
@MainActor
enum SkinParityFixturesCitadel {
    static let perDay: [AinkradChartBar] = [
        (14, 1, 8), (18, 0, 9), (22, 1, 8), (17, 0, 11), (9, 0, 5), (3, 0, 2),
        (24, 2, 10), (28, 0, 12), (26, 1, 10), (30, 0, 14), (27, 1, 10), (6, 0, 4),
    ].enumerated().map { day, spend in
        AinkradChartBar(
            label: "Oct \(day + 1)",
            segments: [
                AinkradBarSegment(name: "Priced", value: spend.0, tone: .accentSecondary),
                AinkradBarSegment(name: "Unpriced", value: spend.1, tone: .warning),
                AinkradBarSegment(name: "Subscription", value: spend.2, tone: .accentTertiary),
            ])
    }

    static let velocity: [AinkradChartBar] = [("S0", 24, 26), ("S1", 30, 33), ("S2", 34, 34), ("S3", 31, 33)].map {
        AinkradChartBar(
            label: $0.0,
            segments: [
                AinkradBarSegment(name: "Completed", value: $0.1, tone: .accentSecondary),
                AinkradBarSegment(name: "Committed", value: $0.2 - $0.1, tone: .muted),
            ])
    }

    static func line(_ name: String, _ ys: [Double], tone: AinkradChartTone = .accentSecondary, dashed: Bool = false)
        -> AinkradChartSeries
    {
        AinkradChartSeries(
            name: name, points: ys.enumerated().map { AinkradChartPoint(x: Double($0.offset), y: $0.element) },
            tone: tone, isDashed: dashed)
    }

    static let burndown: [AinkradChartSeries] = [
        line("Ideal", [34, 30.6, 27.2, 23.8, 20.4, 17, 13.6, 10.2, 6.8, 3.4, 0], tone: .muted, dashed: true),
        line("Actual", [34, 34, 37, 33, 29, 24, 19]),
    ]

    static let spendToday = [2.0, 3, 4, 5.5, 6, 9, 10.5, 12, 14, 15, 16.5, 18.4]

    static let cycleLead: [AinkradChartSeries] = [
        line("Cycle", [1.2, 1.8, 0.9, 2.2, 1.6, 2.6, 1.9, 1.1, 2.4, 1.0, 2.8, 1.7]),
        line("Lead", [2.5, 3.6, 1.2, 4.6, 3.9, 5.6, 3.2, 2.3, 4.1, 2.4, 6.1, 3.0], tone: .accentTertiary),
    ]

    static var fixtures: [SkinParityFixture] {
        [
            SkinParityFixture(
                name: "chart-bar-stacked",
                view: AnyView(
                    AinkradBarChart(
                        title: "Per day", bars: perDay,
                        threshold: AinkradChartThreshold(value: 48, label: "daily warn $48"),
                        format: { "$\($0)" }
                    ).frame(height: 150))),
            SkinParityFixture(
                name: "chart-bar-velocity",
                view: AnyView(
                    AinkradBarChart(
                        title: "Velocity", bars: velocity,
                        threshold: AinkradChartThreshold(value: 29, label: "avg 29", tone: .muted)
                    ).frame(height: 150))),
            SkinParityFixture(
                name: "chart-line-burndown",
                view: AnyView(
                    AinkradLineChart(
                        title: "Burndown", series: burndown,
                        axisLabels: [
                            AinkradChartAxisLabel(x: 0, text: "Oct 13"), AinkradChartAxisLabel(x: 6, text: "today"),
                            AinkradChartAxisLabel(x: 10, text: "Oct 24"),
                        ]
                    ).frame(height: 150))),
            SkinParityFixture(
                name: "chart-line-spend",
                view: AnyView(
                    AinkradLineChart(
                        title: "Spend today", series: [line("Spend", spendToday)],
                        threshold: AinkradChartThreshold(value: 24, label: "warn $24"), fillsArea: true
                    ).frame(height: 120))),
            SkinParityFixture(
                name: "chart-sparkline",
                view: AnyView(
                    AinkradSparkline(
                        title: "Spend today", values: spendToday,
                        threshold: AinkradChartThreshold(value: 24, label: "warn")
                    ).frame(width: 160, height: 40))),
            SkinParityFixture(
                name: "chart-scatter",
                view: AnyView(
                    AinkradScatterChart(
                        title: "Cycle and lead time", series: cycleLead,
                        threshold: AinkradChartThreshold(value: 3.6, label: "p85 3.6d")
                    ).frame(height: 150))),
            SkinParityFixture(
                name: "chart-empty",
                view: AnyView(AinkradLineChart(title: "Burndown", series: []).frame(height: 120))),
            SkinParityFixture(
                name: "toolCard-read",
                view: AnyView(
                    AinkradToolCard(
                        name: "Read", argument: "citadel/crates/citadel-server/src/stream.rs", status: .succeeded,
                        result: .summary("412 lines")))),
            SkinParityFixture(
                name: "toolCard-edit",
                view: AnyView(
                    AinkradToolCard(
                        name: "Edit", argument: "citadel/crates/citadel-server/src/stream.rs", status: .succeeded,
                        result: .counts(added: 38, removed: 6), isInitiallyExpanded: true
                    ) {
                        AinkradCodeBlock(".filter(|e| e.seq >= last_seen.next())", language: "rust")
                    })),
            SkinParityFixture(
                name: "toolCard-waiting",
                view: AnyView(
                    AinkradToolCard(
                        name: "Bash", argument: "cargo add tokio-tungstenite@0.26 --features rustls",
                        status: .waiting,
                        footnote: "Network access to crates.io is outside this project's sandbox policy."))),
            SkinParityFixture(
                name: "toolCard-failed",
                view: AnyView(
                    AinkradToolCard(
                        name: "Bash", argument: "cargo test -p citadel-server", status: .failed,
                        result: .summary("exit 101"), note: "Rewritten by a hook from: cargo test"))),
            SkinParityFixture(
                name: "toolCard-running",
                view: AnyView(
                    AinkradToolCard(name: "Grep", argument: "replay_from", status: .running) {
                        EmptyView()
                    } accessory: { state in
                        Text(state.isWide ? "↗ Open in Forge" : "↗ Forge")
                    })),
            SkinParityFixture(
                name: "chatBubble-user",
                view: AnyView(
                    AinkradChatBubble(
                        text: "Draft the launch post for Ainkrad 1.0. Lead with the **OS, not web app** idea.",
                        author: "You", meta: "09:40"))),
            SkinParityFixture(
                name: "chatBubble-userAttachments",
                view: AnyView(
                    AinkradChatBubble(text: "Match this layout", attachments: ["mockup.png", "notes.png"]))),
            SkinParityFixture(
                name: "chatBubble-agent",
                view: AnyView(
                    AinkradChatBubble(
                        text: "First draft is up — 860 words. I left two marked placeholders in `draft.md`.",
                        role: .agent, author: "Quill", meta: "Writer · 10:02"
                    ) {
                        Circle().stroke(.orange, lineWidth: 1.5).frame(width: 22, height: 22)
                    })),
        ]
    }
}
