import Testing
import Foundation
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@MainActor
@Suite("AgentContext")
struct AgentContextTests {
    // A minimal in-file registry double proving the protocol shape is usable.
    final class FakeRegistry: PluginContextRegistry {
        private var sources: [PluginContextToken: @MainActor () -> AgentContextSnapshot?] = [:]
        func register(_ source: @escaping @MainActor () -> AgentContextSnapshot?) -> PluginContextToken {
            let token = PluginContextToken()
            sources[token] = source
            return token
        }
        func remove(_ token: PluginContextToken) { sources[token] = nil }
        func snapshots() -> [AgentContextSnapshot] { sources.values.compactMap { $0() } }
    }

    @Test("register then read yields the snapshot")
    func registerRead() {
        let reg = FakeRegistry()
        _ = reg.register { AgentContextSnapshot(kind: "terminal", title: "T", text: "hello") }
        #expect(reg.snapshots() == [AgentContextSnapshot(kind: "terminal", title: "T", text: "hello")])
    }

    @Test("remove unregisters the source")
    func removeUnregisters() {
        let reg = FakeRegistry()
        let token = reg.register { AgentContextSnapshot(kind: "git", title: "G", text: "clean") }
        reg.remove(token)
        #expect(reg.snapshots().isEmpty)
    }

    @Test("the context API shipped in generation 8 and is still present")
    func apiVersionBumped() {
        #expect(AinkradAppKit.apiVersion >= 8)
    }
}
