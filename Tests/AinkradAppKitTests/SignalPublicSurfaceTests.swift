import Testing
import SwiftUI
import Foundation
import AinkradSignal
// NOT @testable, deliberately. This file is the plugin's vantage point: a plain
// import sees only the public surface, so anything a plugin needs and cannot
// reach fails to COMPILE here.
//
// This exists because the move into the kit shipped twice-broken API that every
// other test was blind to. The types were `public` but their implicit
// memberwise initialisers were internal, and `SignalToastModel.present(_:)` and
// `.dismiss(id:)` were internal too — so the components were importable and
// unusable. The in-module tests could not see it; only an outside caller can.
import AinkradAppKitUI
import AinkradAppKitContract

@MainActor
@Suite("Signal public surface")
struct SignalPublicSurfaceTests {
    private func event(_ title: String, _ severity: SignalSeverity = .info) -> SignalEvent {
        SignalEvent(source: .app(appID: "probe"), kind: "test.event",
                    severity: severity, title: title)
    }

    @Test("a plugin can construct every feed component")
    func componentsAreConstructible() {
        let events = [event("one"), event("two", .failure)]
        _ = SignalFeedRow(event: events[0])
        _ = SignalFeedRow(event: events[0], repeatCount: 3, isUnread: false,
                          now: Date(), onActivate: { _ in }, onAction: { _, _ in })
        _ = SignalFeedList(events: events)
        _ = SignalFeedList(events: events, repeatCounts: [events[0].id: 2],
                           readIDs: [events[1].id], now: Date(), calendar: .current,
                           onActivate: { _ in }, onAction: { _, _ in })
        _ = SignalToastStack(model: SignalToastModel())
    }

    @Test("a plugin can drive the toast model")
    func toastModelIsUsable() {
        let model = SignalToastModel()
        model.present(event("hello"))
        #expect(model.visible.count == 1)
        #expect(model.overflowCount == 0)
        model.dismiss(id: model.visible[0].id)
        #expect(model.visible.isEmpty)
        #expect(SignalToastModel.autoDismissDelay(for: .failure) == nil)
        #expect(SignalToastModel.maxVisible == 3)
    }

    @Test("a plugin can use the presentation helpers")
    func presentationHelpersAreUsable() {
        let now = Date()
        #expect(SignalPresentation.relativeTime(now, now: now) == "now")
        #expect(!SignalPresentation.iconSymbol(for: .failure).isEmpty)
        #expect(SignalPresentation.status(for: .failure) == .danger)
        #expect(!SignalPresentation.sourceLabel(.host).isEmpty)
        #expect(SignalPresentation.dayGroups([event("x")], calendar: .current).count == 1)
    }

    @Test("a plugin can embed its own feed through the emitter")
    func ownFeedViewIsUsable() {
        let emitter = NoopSignalEmitter()
        _ = SignalFeedView(scope: .own, emitter: emitter)
        let model = SignalFeedViewModel(emitter: emitter)
        model.reload()
        #expect(model.events.isEmpty)
    }
}
