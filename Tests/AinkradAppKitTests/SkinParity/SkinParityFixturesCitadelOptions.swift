import SwiftUI

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// The third Citadel round: options on existing components, with the data of
/// the Citadel mockups (home 02, org 03, run 05, cost 09).
@MainActor
enum SkinParityFixturesCitadelOptions {
    static var fixtures: [SkinParityFixture] {
        [
            // Org 03: a department card holding team cards. Under Glass the inner cards draw no fill of
            // their own, so the layers do not stack lighter.
            SkinParityFixture(
                name: "card-nested",
                view: AnyView(
                    AinkradCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Engineering").font(.headline)
                            HStack(spacing: 10) {
                                AinkradCard { Text("Citadel Core").frame(maxWidth: .infinity, alignment: .leading) }
                                AinkradCard { Text("Mac Client").frame(maxWidth: .infinity, alignment: .leading) }
                            }
                        }
                    }.frame(width: 340)),
                sweepSize: CGSize(width: 400, height: 200)),
            // Home 02 / org 03: amber waiting, red stalled, violet CEO; selected still wins.
            SkinParityFixture(
                name: "card-rimTint",
                view: AnyView(
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            AinkradCard { Text("Quill · waiting") }.rimTint(.warning)
                            AinkradCard { Text("Rook · stalled") }.rimTint(.danger)
                        }
                        HStack(spacing: 10) {
                            AinkradCard { Text("Aldric · CEO") }.rimTint(.accentViolet)
                            AinkradCard(isSelected: true) { Text("Selected") }.rimTint(.danger)
                        }
                    })),
            // Home 02 spend split and run 05 stage timings: tones in the caller's order.
            SkinParityFixture(
                name: "stackedStatusBar-tones",
                view: AnyView(
                    VStack(spacing: 14) {
                        AinkradStackedStatusBar(toneRuns: [
                            AinkradToneRun(value: 62, tone: .accentSecondary),
                            AinkradToneRun(value: 8, tone: .warning),
                            AinkradToneRun(value: 30, tone: .accentViolet),
                        ])
                        AinkradStackedStatusBar(toneRuns: [
                            AinkradToneRun(value: 0.4, tone: .accentViolet),
                            AinkradToneRun(value: 1.1, tone: .accentPrimary),
                            AinkradToneRun(value: 5.9, tone: .accentSecondary),
                            AinkradToneRun(value: 2.2, tone: .accentTertiary),
                        ])
                        AinkradStackedStatusBar(toneRuns: [
                            AinkradToneRun(value: 1_000, tone: .accentSecondary),
                            AinkradToneRun(value: 0, tone: .warning),
                            AinkradToneRun(value: 1, tone: .danger),
                        ])
                    }.frame(width: 300))),
            // Home 02 sidebar: faint counts, amber and red badges.
            SkinParityFixture(
                name: "navList-counts",
                view: AnyView(
                    AinkradNavList(
                        items: navItems.map(\.0), selection: .constant("Home"), icon: { _ in "circle" }, label: { $0 }
                    )
                    .counts { item in navItems.first { $0.0 == item }?.1 }
                    .frame(width: 260)),
                sweepSize: CGSize(width: 400, height: 300)),
            // Run 05 rail: sentence-case labels; the default row beneath for comparison.
            SkinParityFixture(
                name: "statRow-sentenceCase",
                view: AnyView(
                    VStack(spacing: 2) {
                        AinkradStatRow(label: "Input", value: "61.0k · 44k cached").sentenceCaseLabel()
                        AinkradStatRow(label: "Cap at this rate", value: "~6 min", status: .warning)
                            .sentenceCaseLabel()
                        AinkradStatRow(label: "Runner tags", value: "linux")
                    }.frame(width: 260))),
            // Home 02 account warning with its "Accounts →" action.
            SkinParityFixture(
                name: "banner-action",
                view: AnyView(
                    VStack(spacing: 10) {
                        AinkradBanner(
                            message: "claude-work is at its 5 h limit until 13:05", status: .warning,
                            actionTitle: "Accounts →", action: {})
                        AinkradBanner(
                            message: "Runner hetzner-2 lost", status: .danger, actionTitle: "Retry", action: {},
                            onDismiss: {})
                    }.frame(width: 370))),
        ]
    }

    static let navItems: [(String, AinkradNavCount?)] = [
        ("Home", nil), ("Requirements", AinkradNavCount("5")), ("Approvals", AinkradNavCount("5", tone: .warning)),
        ("Why stuck", AinkradNavCount("3", tone: .danger)), ("Artifacts", AinkradNavCount("31")),
        ("Runners", AinkradNavCount("3/4")),
    ]
}
