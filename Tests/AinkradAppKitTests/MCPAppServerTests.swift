import Foundation
import Testing

@testable import AinkradAppKitContract

@MainActor
@Suite("MCPAppServer")
struct MCPAppServerTests {
    /// Decodes a server reply into a dictionary for assertions.
    func decode(_ raw: String) throws -> [String: Any] {
        let data = try #require(raw.data(using: .utf8))
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    @Test("initialize returns the protocol version and server info")
    func initializeHandshake() async throws {
        let server = MCPAppServer(appID: "demo")
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"1","method":"initialize","params":{}}"#)
        let json = try decode(reply)
        #expect(json["id"] as? String == "1")
        let result = try #require(json["result"] as? [String: Any])
        #expect(result["protocolVersion"] as? String == "2024-11-05")
        let info = try #require(result["serverInfo"] as? [String: Any])
        #expect(info["name"] as? String == "demo")
    }

    @Test("an unknown method returns JSON-RPC error -32601")
    func unknownMethod() async throws {
        let server = MCPAppServer(appID: "demo")
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"7","method":"nope/nope","params":{}}"#)
        let json = try decode(reply)
        let error = try #require(json["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32601)
    }

    @Test("malformed input returns parse error -32700 with a null id")
    func malformedInput() async throws {
        let server = MCPAppServer(appID: "demo")
        let json = try decode(await server.handle("{not json"))
        let error = try #require(json["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32700)
        #expect(json["id"] is NSNull)
    }

    @Test("a notification (no id) produces no reply")
    func notificationProducesNoReply() async {
        let server = MCPAppServer(appID: "demo")
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}"#)
        #expect(reply.isEmpty)
    }

    func demoServer() -> MCPAppServer {
        let server = MCPAppServer(appID: "demo")
        server.addTool(
            .init(
                name: "echo",
                description: "Echo the input back.",
                schemaJSON: #"{"type":"object","properties":{"text":{"type":"string"}}}"#,
                destructive: false, readOnly: true
            ) { json in
                AgentActionResult(text: "got \(json)", isError: false)
            })
        server.addTool(
            .init(
                name: "boom", description: "Always fails.",
                schemaJSON: #"{"type":"object"}"#, destructive: true
            ) { _ in
                AgentActionResult(text: "exploded", isError: true)
            })
        return server
    }

    @Test("tools/list reports each tool with a parsed schema and annotations")
    func toolsList() async throws {
        let reply = await demoServer().handle(
            #"{"jsonrpc":"2.0","id":"2","method":"tools/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let tools = try #require(result["tools"] as? [[String: Any]])
        #expect(tools.count == 2)
        #expect(tools[0]["name"] as? String == "echo")
        // inputSchema must be a nested OBJECT, not the raw schema string —
        // and must carry the REAL parsed schema, not just a generic
        // `{"type":"object"}` fallback shape that any implementation would
        // produce even if it ignored `schemaJSON` entirely.
        let schema = try #require(tools[0]["inputSchema"] as? [String: Any])
        let properties = try #require(schema["properties"] as? [String: Any])
        #expect(properties["text"] != nil)
        let annotations = try #require(tools[1]["annotations"] as? [String: Any])
        #expect(annotations["destructiveHint"] as? Bool == true)
    }

    /// The host force-opens an app's window only for tools that say they need
    /// it, so the flag has to survive `tools/list` in BOTH states — a key that
    /// is merely absent when false reads as "unknown" on the host side.
    @Test("tools/list emits ainkrad/requiresLiveApp for both states")
    func toolsListRequiresLiveApp() async throws {
        let server = MCPAppServer(appID: "demo")
        server.addTool(
            .init(
                name: "headless", description: "",
                schemaJSON: #"{"type":"object"}"#
            ) { _ in
                AgentActionResult(text: "ok", isError: false)
            })
        var live = MCPToolSpec(
            name: "onscreen", description: "",
            schemaJSON: #"{"type":"object"}"#
        ) { _ in
            AgentActionResult(text: "ok", isError: false)
        }
        live.requiresLiveApp = true
        server.addTool(live)

        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"2","method":"tools/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let tools = try #require(result["tools"] as? [[String: Any]])
        let headless = try #require(tools[0]["annotations"] as? [String: Any])
        let onscreen = try #require(tools[1]["annotations"] as? [String: Any])
        #expect(headless["ainkrad/requiresLiveApp"] as? Bool == false)
        #expect(onscreen["ainkrad/requiresLiveApp"] as? Bool == true)
    }

    @Test("resources/list emits ainkrad/requiresLiveApp for both states")
    func resourcesListRequiresLiveApp() async throws {
        let server = MCPAppServer(appID: "demo")
        server.addResource(.init(uri: "demo://cold", title: "Cold") { "" })
        var live = MCPResourceSpec(uri: "demo://live", title: "Live") { "" }
        live.requiresLiveApp = true
        server.addResource(live)

        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"8","method":"resources/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let resources = try #require(result["resources"] as? [[String: Any]])
        let cold = try #require(resources[0]["annotations"] as? [String: Any])
        let hot = try #require(resources[1]["annotations"] as? [String: Any])
        #expect(cold["ainkrad/requiresLiveApp"] as? Bool == false)
        #expect(hot["ainkrad/requiresLiveApp"] as? Bool == true)
    }

    @Test("tools/call invokes the handler and wraps the text as MCP content")
    func toolsCallSuccess() async throws {
        let reply = await demoServer().handle(
            #"{"jsonrpc":"2.0","id":"3","method":"tools/call","params":{"name":"echo","arguments":{"text":"hi"}}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        #expect(result["isError"] as? Bool == false)
        let content = try #require(result["content"] as? [[String: Any]])
        let text = try #require(content.first?["text"] as? String)
        #expect(text.contains("\"text\""))
        #expect(text.contains("hi"))
    }

    @Test("tools/call surfaces a handler failure as isError, not an RPC error")
    func toolsCallHandlerFailure() async throws {
        let reply = await demoServer().handle(
            #"{"jsonrpc":"2.0","id":"4","method":"tools/call","params":{"name":"boom","arguments":{}}}"#)
        let json = try decode(reply)
        #expect(json["error"] == nil)
        let result = try #require(json["result"] as? [String: Any])
        #expect(result["isError"] as? Bool == true)
    }

    @Test("tools/call on an unknown tool returns JSON-RPC error -32602")
    func toolsCallUnknownTool() async throws {
        let reply = await demoServer().handle(
            #"{"jsonrpc":"2.0","id":"5","method":"tools/call","params":{"name":"ghost","arguments":{}}}"#)
        let error = try #require(try decode(reply)["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32602)
    }

    @Test("resources/list reports registered resources")
    func resourcesList() async throws {
        let server = MCPAppServer(appID: "demo")
        server.addResource(.init(uri: "demo://buffer", title: "Buffer") { "hello" })
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"8","method":"resources/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let resources = try #require(result["resources"] as? [[String: Any]])
        #expect(resources.count == 1)
        #expect(resources[0]["uri"] as? String == "demo://buffer")
        #expect(resources[0]["name"] as? String == "Buffer")
        #expect(resources[0]["mimeType"] as? String == "text/plain")
    }

    @Test("resources/read returns the provider's current text")
    func resourcesRead() async throws {
        let server = MCPAppServer(appID: "demo")
        server.addResource(.init(uri: "demo://buffer", title: "Buffer") { "live value" })
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"9","method":"resources/read","params":{"uri":"demo://buffer"}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let contents = try #require(result["contents"] as? [[String: Any]])
        #expect(contents[0]["text"] as? String == "live value")
    }

    @Test("resources/list emits purpose as MCP's description field")
    func resourcesListPurpose() async throws {
        let server = MCPAppServer(appID: "demo")
        var described = MCPResourceSpec(uri: "demo://buffer", title: "Buffer") { "" }
        described.purpose = "Read when the workspace context shows a truncated terminal."
        server.addResource(described)
        // The second one never sets `purpose`, proving the key is still present
        // (as an empty string) rather than vanishing — the host decodes one shape.
        server.addResource(.init(uri: "demo://plain", title: "Plain") { "" })

        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"11","method":"resources/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let resources = try #require(result["resources"] as? [[String: Any]])
        #expect(
            resources[0]["description"] as? String
                == "Read when the workspace context shows a truncated terminal.")
        #expect(resources[1]["description"] as? String == "")
    }

    @Test("resources/read flags a resultProvider failure without an RPC error")
    func resourcesReadFailure() async throws {
        let server = MCPAppServer(appID: "demo")
        var spec = MCPResourceSpec(uri: "demo://buffer", title: "Buffer") { "unused" }
        spec.resultProvider = { MCPResourceContent(text: "no terminal is open", isError: true) }
        server.addResource(spec)

        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"12","method":"resources/read","params":{"uri":"demo://buffer"}}"#)
        let json = try decode(reply)
        #expect(json["error"] == nil)
        let result = try #require(json["result"] as? [String: Any])
        #expect(result["ainkrad/isError"] as? Bool == true)
        let contents = try #require(result["contents"] as? [[String: Any]])
        // `resultProvider` wins outright: the legacy provider's "unused" must
        // not leak into the body.
        #expect(contents[0]["text"] as? String == "no terminal is open")
    }

    @Test("resources/read with a plain provider reports success")
    func resourcesReadPlainProviderNotAnError() async throws {
        let server = MCPAppServer(appID: "demo")
        server.addResource(.init(uri: "demo://buffer", title: "Buffer") { "live value" })
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"13","method":"resources/read","params":{"uri":"demo://buffer"}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        #expect(result["ainkrad/isError"] as? Bool == false)
    }

    @Test("resources/read on an unknown uri returns JSON-RPC error -32002")
    func resourcesReadUnknown() async throws {
        let server = MCPAppServer(appID: "demo")
        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"10","method":"resources/read","params":{"uri":"demo://ghost"}}"#)
        let error = try #require(try decode(reply)["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32002)
    }

    @Test("a message with an id but no method returns invalid request -32600")
    func missingMethod() async throws {
        let server = MCPAppServer(appID: "demo")
        let reply = await server.handle(#"{"jsonrpc":"2.0","id":"11","params":{}}"#)
        let json = try decode(reply)
        #expect(json["id"] as? String == "11")
        let error = try #require(json["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32600)
    }

    @Test("addTool returns false and registers nothing for a duplicate name")
    func addToolDuplicateName() async throws {
        let server = demoServer()
        let added = server.addTool(
            .init(
                name: "echo", description: "A second echo.",
                schemaJSON: #"{"type":"object"}"#
            ) { _ in AgentActionResult(text: "second", isError: false) })
        #expect(added == false)

        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"12","method":"tools/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let tools = try #require(result["tools"] as? [[String: Any]])
        #expect(tools.count == 2)  // still just echo + boom, not a third
    }

    @Test("addTool returns false and registers nothing for a malformed schemaJSON")
    func addToolMalformedSchema() async throws {
        let server = MCPAppServer(appID: "demo")
        let added = server.addTool(
            .init(
                name: "broken", description: "Bad schema.",
                schemaJSON: "not json"
            ) { _ in AgentActionResult(text: "n/a", isError: false) })
        #expect(added == false)

        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"13","method":"tools/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let tools = try #require(result["tools"] as? [[String: Any]])
        #expect(tools.isEmpty)
    }

    /// Pins which `handle` methods are allowed to invoke an app-supplied
    /// closure. A host repo's `AppServerActivator.methodsRequiringLiveApp =
    /// ["tools/call", "resources/read"]` depends on this staying exactly
    /// true — it decides whether the host needs to spin up the live app
    /// instance (vs. answering from cached metadata) based on the method
    /// name alone. If a future change made e.g. `tools/list` reach into a
    /// tool's handler, that list would silently go stale and the host would
    /// serve metadata without the live app it needs. Every method `handle`
    /// currently supports is driven here so the flags can only flip on the
    /// two calls that are supposed to flip them.
    @Test("only tools/call and resources/read invoke app-supplied closures")
    func onlyLiveMethodsInvokeClosures() async throws {
        final class Flags: @unchecked Sendable {
            var didCallToolHandler = false
            var didCallResourceProvider = false
        }
        let flags = Flags()

        let server = MCPAppServer(appID: "demo")
        server.addTool(
            .init(
                name: "echo", description: "Echo.",
                schemaJSON: #"{"type":"object"}"#
            ) { _ in
                flags.didCallToolHandler = true
                return AgentActionResult(text: "called", isError: false)
            })
        server.addResource(
            .init(uri: "demo://buffer", title: "Buffer") {
                flags.didCallResourceProvider = true
                return "called"
            })

        func expectFlagsUnset(_ label: String) {
            #expect(flags.didCallToolHandler == false, "\(label) must not invoke the tool handler")
            #expect(flags.didCallResourceProvider == false, "\(label) must not invoke the resource provider")
        }

        _ = await server.handle(#"{"jsonrpc":"2.0","id":"1","method":"initialize","params":{}}"#)
        expectFlagsUnset("initialize")

        _ = await server.handle(#"{"jsonrpc":"2.0","id":"2","method":"tools/list","params":{}}"#)
        expectFlagsUnset("tools/list")

        _ = await server.handle(#"{"jsonrpc":"2.0","id":"3","method":"resources/list","params":{}}"#)
        expectFlagsUnset("resources/list")

        // Notification (no id) — must not touch either closure.
        _ = await server.handle(
            #"{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}"#)
        expectFlagsUnset("notification")

        // Unknown/unsupported method.
        _ = await server.handle(#"{"jsonrpc":"2.0","id":"4","method":"nope/nope","params":{}}"#)
        expectFlagsUnset("unknown method")

        // Now the two methods that ARE allowed to reach app state.
        _ = await server.handle(
            #"{"jsonrpc":"2.0","id":"5","method":"tools/call","params":{"name":"echo","arguments":{}}}"#)
        #expect(flags.didCallToolHandler == true)
        #expect(flags.didCallResourceProvider == false)

        _ = await server.handle(
            #"{"jsonrpc":"2.0","id":"6","method":"resources/read","params":{"uri":"demo://buffer"}}"#)
        #expect(flags.didCallResourceProvider == true)
    }

    @Test("addResource returns false and registers nothing for a duplicate uri")
    func addResourceDuplicateURI() async throws {
        let server = MCPAppServer(appID: "demo")
        let first = server.addResource(.init(uri: "demo://buffer", title: "Buffer") { "one" })
        #expect(first == true)
        let second = server.addResource(.init(uri: "demo://buffer", title: "Buffer 2") { "two" })
        #expect(second == false)

        let reply = await server.handle(
            #"{"jsonrpc":"2.0","id":"14","method":"resources/list","params":{}}"#)
        let result = try #require(try decode(reply)["result"] as? [String: Any])
        let resources = try #require(result["resources"] as? [[String: Any]])
        #expect(resources.count == 1)
        #expect(resources[0]["name"] as? String == "Buffer")
    }
}
