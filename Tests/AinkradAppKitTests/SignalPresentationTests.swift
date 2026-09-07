import Testing
import Foundation
import AinkradSignal
@testable import AinkradAppKitUI

@Suite("Signal feed formatting")
struct SignalFeedFormattingTests {
    private func event(_ title: String, at seconds: TimeInterval,
                       severity: SignalSeverity = .info) -> SignalEvent {
        SignalEvent(timestamp: Date(timeIntervalSince1970: seconds), source: .host,
                    kind: "test.event", severity: severity, title: title)
    }

    @Test("relative time is terse and never says '0 seconds ago'")
    func relativeTime() {
        let now = Date(timeIntervalSince1970: 100_000)
        #expect(SignalPresentation.relativeTime(now, now: now) == "now")
        #expect(SignalPresentation.relativeTime(now.addingTimeInterval(-30), now: now) == "now")
        #expect(SignalPresentation.relativeTime(now.addingTimeInterval(-90), now: now) == "1m")
        #expect(SignalPresentation.relativeTime(now.addingTimeInterval(-7200), now: now) == "2h")
        #expect(SignalPresentation.relativeTime(now.addingTimeInterval(-3 * 86400), now: now) == "3d")
    }

    @Test("events group into days, newest day first, newest event first within a day")
    func dayGrouping() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let day0: TimeInterval = 1_756_684_800   // 2026-09-01 00:00 UTC
        let events = [
            event("today-early", at: day0 + 3600),
            event("today-late", at: day0 + 7200),
            event("yesterday", at: day0 - 3600),
        ]
        let groups = SignalPresentation.dayGroups(events, calendar: calendar)
        #expect(groups.count == 2)
        #expect(groups[0].events.map(\.title) == ["today-late", "today-early"])
        #expect(groups[1].events.map(\.title) == ["yesterday"])
    }

    @Test("each severity has a distinct symbol")
    func symbols() {
        let symbols = SignalSeverity.allCases.map(SignalPresentation.iconSymbol(for:))
        #expect(Set(symbols).count == SignalSeverity.allCases.count)
        #expect(SignalPresentation.iconSymbol(for: .failure) == "xmark.octagon")
    }

    @Test("a row built with the original initialiser has no menu")
    func defaultRowHasNoMenu() {
        let row = SignalFeedRow(event: SignalEvent(source: .host, kind: "k",
                                                   severity: .info, title: "t"))
        // The old initialiser must keep working unchanged: it is public API in
        // a library-evolution module, and anything already linked against it
        // resolves the mangled symbol at load time, not at compile time.
        #expect(row.menuItems(row.event).isEmpty)
    }

    @Test("a row built with the menu initialiser carries its items")
    func menuRowCarriesItems() {
        let row = SignalFeedRow(
            event: SignalEvent(source: .app(appID: "raven"), kind: "build.failed",
                               severity: .failure, title: "t"),
            repeatCount: 1, isUnread: true, now: Date(),
            onActivate: { _ in }, onAction: { _, _ in },
            menuItems: { event in
                [AinkradMenuItem(title: "Mute \(event.kind)", action: {})]
            })
        #expect(row.menuItems(row.event).map(\.title) == ["Mute build.failed"])
    }

    @Test("a row built the original way neither pins nor expands")
    func originalRowUnchanged() {
        let row = SignalFeedRow(event: SignalEvent(source: .host, kind: "k",
                                                   severity: .info, title: "t"))
        // The old initialisers are public API in a library-evolution module:
        // anything already linked resolves their mangled symbols at load time.
        #expect(row.isPinned == false)
        #expect(row.isExpanded == false)
        #expect(row.onToggleExpanded == nil)
    }

    // `@MainActor`: the closure captures a local, and SignalFeedRow's stored
    // closure crosses an isolation boundary without it.
    @MainActor
    @Test("a row can be built pinned and expanded")
    func expandedRowCarriesState() {
        var toggled = false
        let row = SignalFeedRow(
            event: SignalEvent(source: .host, kind: "k", severity: .info, title: "t"),
            repeatCount: 1, isUnread: true, now: Date(),
            onActivate: { _ in }, onAction: { _, _ in }, menuItems: { _ in [] },
            isPinned: true, isExpanded: true, onToggleExpanded: { toggled = true })
        #expect(row.isPinned)
        #expect(row.isExpanded)
        row.onToggleExpanded?()
        #expect(toggled)
    }
}
