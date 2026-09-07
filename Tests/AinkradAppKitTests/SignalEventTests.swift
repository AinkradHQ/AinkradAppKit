import Testing
import Foundation
@testable import AinkradSignal

@Suite("SignalEvent envelope")
struct SignalEventTests {
    @Test("round-trips through JSON unchanged")
    func roundTrip() throws {
        let event = SignalEvent(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: 1_756_700_000),
            source: .app(appID: "com.ainkrad.raven"),
            kind: "build.failed",
            severity: .failure,
            title: "Build failed",
            body: "3 errors in SignalStore.swift",
            proposedImportance: .urgent,
            deepLink: SignalDeepLink(appID: "com.ainkrad.raven", payload: Data([0x01])),
            actions: [SignalAction(id: "retry", label: "Retry", isDestructive: false)],
            dedupeKey: "build:main")

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(SignalEvent.self, from: data)
        #expect(decoded == event)
    }

    @Test("source encodes app id distinguishably from host")
    func sourceCases() throws {
        #expect(SignalSource.host != SignalSource.sage)
        #expect(SignalSource.app(appID: "a") != SignalSource.app(appID: "b"))
        let data = try JSONEncoder().encode(SignalSource.app(appID: "raven"))
        #expect(try JSONDecoder().decode(SignalSource.self, from: data) == .app(appID: "raven"))
    }
}
