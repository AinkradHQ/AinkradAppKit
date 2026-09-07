import Testing
import Foundation
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@MainActor
@Suite("AgentAction")
struct AgentActionTests {
    /// A minimal in-file provider double proving the protocol shape is usable
    /// and the async handler round-trips a JSON-string parameter.
    final class FakeActionProvider: AgentActionProvider {
        private var handlers: [AgentActionToken: (String) async -> AgentActionResult] = [:]
        private var ids: [AgentActionToken: String] = [:]
        func register(actionID: String,
                      handler: @escaping @MainActor (String) async -> AgentActionResult) -> AgentActionToken {
            let token = AgentActionToken()
            handlers[token] = handler
            ids[token] = actionID
            return token
        }
        func remove(_ token: AgentActionToken) { handlers[token] = nil; ids[token] = nil }
        func invoke(actionID: String, input: String) async -> AgentActionResult? {
            guard let token = ids.first(where: { $0.value == actionID })?.key,
                  let handler = handlers[token] else { return nil }
            return await handler(input)
        }
    }

    @Test("register then invoke runs the handler and returns its result")
    func registerInvoke() async {
        let provider = FakeActionProvider()
        _ = provider.register(actionID: "echo") { json in
            AgentActionResult(text: "got:\(json)", isError: false)
        }
        let result = await provider.invoke(actionID: "echo", input: "{\"x\":1}")
        #expect(result == AgentActionResult(text: "got:{\"x\":1}", isError: false))
    }

    @Test("remove unregisters the handler")
    func removeUnregisters() async {
        let provider = FakeActionProvider()
        let token = provider.register(actionID: "echo") { _ in AgentActionResult(text: "", isError: false) }
        provider.remove(token)
        let result = await provider.invoke(actionID: "echo", input: "{}")
        #expect(result == nil)
    }

    @Test("the action API shipped in generation 8 and is still present")
    func apiVersionBumped() {
        #expect(AinkradAppKit.apiVersion >= 8)
    }
}
