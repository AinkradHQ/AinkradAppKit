import Testing
import Foundation
@testable import AinkradAppKitUI
@testable import AinkradSignal

@Suite("Signal keyboard navigation")
struct SignalKeyboardNavTests {
    private func event(_ title: String, at seconds: TimeInterval) -> SignalEvent {
        SignalEvent(timestamp: Date(timeIntervalSince1970: seconds), source: .host,
                    kind: "k", severity: .info, title: title)
    }
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    @Test("the arrow keys walk the list exactly as it is drawn")
    func orderMatchesRendering() {
        // Two days, deliberately: the list groups by day, so a traversal built
        // from the raw array would jump across a header the eye does not.
        let events = [event("newest", at: 200_000), event("older", at: 190_000),
                      event("yesterday", at: 100_000)]
        let order = SignalFeedList.keyboardOrder(events, calendar: calendar)
        let drawn = SignalPresentation.dayGroups(events, calendar: calendar)
            .flatMap(\.events).map(\.id)
        #expect(order == drawn)
    }

    @Test("the first move selects the first row rather than doing nothing")
    func firstMoveSelects() {
        let ids = [UUID(), UUID(), UUID()]
        #expect(SignalFeedList.nextFocus(in: ids, from: nil, by: 1) == ids[0])
        #expect(SignalFeedList.nextFocus(in: ids, from: nil, by: -1) == ids[0])
    }

    @Test("moving stops at the ends instead of wrapping")
    func clampsAtBothEnds() {
        let ids = [UUID(), UUID(), UUID()]
        // Wrapping would jump the user from the newest event to the oldest,
        // which reads as the list having scrolled somewhere unexpected rather
        // than as a selection moving.
        #expect(SignalFeedList.nextFocus(in: ids, from: ids[0], by: -1) == ids[0])
        #expect(SignalFeedList.nextFocus(in: ids, from: ids[2], by: 1) == ids[2])
    }

    @Test("moving steps one row at a time in both directions")
    func stepsOneAtATime() {
        let ids = [UUID(), UUID(), UUID()]
        #expect(SignalFeedList.nextFocus(in: ids, from: ids[0], by: 1) == ids[1])
        #expect(SignalFeedList.nextFocus(in: ids, from: ids[1], by: 1) == ids[2])
        #expect(SignalFeedList.nextFocus(in: ids, from: ids[2], by: -1) == ids[1])
    }

    @Test("an empty list has nowhere to go and says so")
    func emptyList() {
        #expect(SignalFeedList.nextFocus(in: [], from: nil, by: 1) == nil)
        #expect(SignalFeedList.nextFocus(in: [], from: UUID(), by: 1) == nil)
    }

    @Test("a selection that has been filtered away falls back to the first row")
    func staleSelectionRecovers() {
        let ids = [UUID(), UUID()]
        // The user filters, and the row they were on is gone. Returning nil
        // would leave the arrow keys inert with no way to recover.
        #expect(SignalFeedList.nextFocus(in: ids, from: UUID(), by: 1) == ids[0])
    }
}
