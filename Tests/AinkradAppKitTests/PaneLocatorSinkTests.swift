import Testing
import SwiftUI
@testable import AinkradAppKitUI

@MainActor
@Suite("Pane locator sink")
struct PaneLocatorSinkTests {
    @Test("a sink equals itself and differs from a separately constructed one")
    func identityEquality() {
        // The host memoizes one sink per pane precisely so SwiftUI sees it as
        // unchanged between renders. If two separately built sinks compared
        // equal, that memoization would be untested and could be dropped
        // without anything failing.
        let sink = SignalPaneLocatorSink { _ in }
        #expect(sink == sink)
        #expect(sink != SignalPaneLocatorSink { _ in })
    }

    @Test("calling the sink forwards the locator")
    func forwards() {
        final class Recorder { var values: [String?] = [] }
        let recorder = Recorder()
        let sink = SignalPaneLocatorSink { value in
            MainActor.assumeIsolated { recorder.values.append(value) }
        }
        sink("session-a")
        sink(nil)
        #expect(recorder.values == ["session-a", nil])
    }

    @Test("the default environment sink discards without crashing")
    func defaultSinkIsSafe() {
        // An app reading this in a preview, its own tests, or the Dev Host
        // must not have to special-case the host's absence.
        let sink = EnvironmentValues().ainkradPaneLocator
        sink("anything")
    }
}
