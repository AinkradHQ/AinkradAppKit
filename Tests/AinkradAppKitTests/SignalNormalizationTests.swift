import Testing
import Foundation
@testable import AinkradSignal

@Suite("Signal normalization")
struct SignalNormalizationTests {
    private func event(kind: String = "run.finished",
                       title: String = "t",
                       body: String? = nil,
                       actions: [SignalAction] = [],
                       source: SignalSource = .host) -> SignalEvent {
        SignalEvent(source: source, kind: kind, severity: .info,
                    title: title, body: body, actions: actions)
    }

    @Test("accepts lowercase dotted kinds, rejects everything else")
    func kindValidation() {
        #expect(SignalKind.isValid("run.finished"))
        #expect(SignalKind.isValid("index.completed.v2"))
        #expect(SignalKind.isValid("a"))
        #expect(!SignalKind.isValid("Run.Finished"))   // uppercase
        #expect(!SignalKind.isValid("run finished"))   // space
        #expect(SignalKind.isValid("session.needs-input"))
        #expect(SignalKind.isValid("session.needs_input"))
        #expect(!SignalKind.isValid("session.needsInput"), "camelCase is still out")
        #expect(!SignalKind.isValid("run/finished"))   // slash
        #expect(!SignalKind.isValid(""))
        #expect(!SignalKind.isValid(String(repeating: "a", count: 65)))
    }

    @Test("truncates title, body and actions to their limits")
    func truncation() {
        let long = String(repeating: "x", count: 5000)
        let many = (0..<9).map { SignalAction(id: "\($0)", label: "l\($0)") }
        let normalized = event(title: long, body: long, actions: many).normalized(source: .host)
        #expect(normalized.title.count == SignalLimits.maxTitle)
        #expect(normalized.body?.count == SignalLimits.maxBody)
        #expect(normalized.actions.count == SignalLimits.maxActions)
        #expect(normalized.actions.first?.id == "0")   // keeps the FIRST three
    }

    @Test("overwrites the source with the stamped identity")
    func sourceIsStamped() {
        let forged = event(source: .app(appID: "quest"))
        let normalized = forged.normalized(source: .app(appID: "raven"))
        #expect(normalized.source == .app(appID: "raven"))
    }

    @Test("leaves short fields untouched")
    func shortFieldsUnchanged() {
        let e = event(title: "Build failed", body: "3 errors")
        let normalized = e.normalized(source: .host)
        #expect(normalized.title == "Build failed")
        #expect(normalized.body == "3 errors")
        #expect(normalized.id == e.id)
    }
}
