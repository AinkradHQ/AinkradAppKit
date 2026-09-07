import Testing
import Foundation
import AinkradSignal
@testable import AinkradAppKitContract

@MainActor
@Suite("PluginSignalEmitter")
final class PluginSignalEmitterTests {
    /// A minimal conformance, standing in for the host's real emitter. If this
    /// stops compiling, the protocol grew a requirement — which for a plugin
    /// SDK is a source break every app must absorb.
    private final class StubEmitter: PluginSignalEmitter {
        struct Call {
            let kind: String
            let severity: SignalSeverity
            let title: String
            let body: String?
            let importance: SignalImportance
            let deepLink: SignalDeepLink?
            let actions: [SignalAction]
            let dedupeKey: String?
        }
        var emitted: [Call] = []
        var ownEvents: [SignalEvent] = []
        var handlers: [String: () async -> Void] = [:]

        func emit(kind: String, severity: SignalSeverity, title: String, body: String?,
                  importance: SignalImportance, deepLink: SignalDeepLink?,
                  actions: [SignalAction], dedupeKey: String?) {
            emitted.append(Call(kind: kind, severity: severity, title: title, body: body,
                                importance: importance, deepLink: deepLink,
                                actions: actions, dedupeKey: dedupeKey))
        }
        func own(limit: Int) -> [SignalEvent] { Array(ownEvents.prefix(limit)) }
        func handleAction(_ actionID: String,
                          _ handler: @escaping @MainActor () async -> Void) -> AgentActionToken {
            handlers[actionID] = handler
            return AgentActionToken()
        }
        func removeActionHandler(_ token: AgentActionToken) {}
    }

    @Test("the convenience overload fills in every optional argument")
    func convenienceOverload() {
        let emitter = StubEmitter()
        emitter.emit(kind: "build.failed", severity: .failure, title: "Build failed")
        #expect(emitter.emitted.count == 1)
        let call = emitter.emitted[0]
        #expect(call.body == nil)
        #expect(call.importance == .normal)
        #expect(call.actions.isEmpty)
        #expect(call.dedupeKey == nil)
    }

    @Test("the emitter surface has no way to name a source")
    func noSourceParameter() {
        // A compile-time property: `StubEmitter` satisfies the protocol without
        // ever mentioning `SignalSource`. If a `source:` parameter is added,
        // this file stops compiling — which is the alarm we want, because
        // forgery must be inexpressible rather than merely rejected.
        let emitter = StubEmitter()
        emitter.emit(kind: "test.event", severity: .info, title: "t")
        #expect(emitter.emitted.count == 1)
    }

    @Test("own(limit:) respects the limit")
    func ownRespectsLimit() {
        let emitter = StubEmitter()
        emitter.ownEvents = (0..<10).map {
            SignalEvent(source: .app(appID: "x"), kind: "test.event",
                        severity: .info, title: "e\($0)")
        }
        #expect(emitter.own(limit: 3).count == 3)
    }

    @Test("an action handler is retrievable by its id")
    func actionHandlers() {
        let emitter = StubEmitter()
        let token = emitter.handleAction("retry") {}
        #expect(emitter.handlers["retry"] != nil)
        #expect(token.id != AgentActionToken().id, "tokens are distinct handles")
    }
}
