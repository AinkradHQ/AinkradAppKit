import Foundation

/// Opt-in capability: an app type conforming to this exposes an MCP server to
/// the host's assistant. Detected by the loader with `as?`, exactly as
/// `AinkradAppTeardown` is — a bundle compiled against an older SDK simply
/// fails the cast and is left alone. This is deliberately a SEPARATE protocol
/// rather than a new requirement on `HostServices`: added protocol
/// requirements have no witness in an already-compiled bundle and stop it
/// loading entirely.
@MainActor public protocol AinkradAppMCP {
    /// Called once per host and cached by the host. Return a server that shares
    /// the app's live state (see `PluginInstanceStorage`) so tools can drive the
    /// on-screen instance rather than a detached copy.
    static func makeMCPServer(host: HostServices) -> MCPAppServer
}

/// One tool an app publishes to the assistant.
public struct MCPToolSpec: Sendable {
    public let name: String
    public let description: String
    /// The tool's JSON Schema, as a JSON **string** — the SDK has no JSON value
    /// type, the same constraint `AgentActionProvider` documents for its params.
    public let schemaJSON: String
    /// Surfaced as MCP `destructiveHint`; the host uses it to gate irreversible ops.
    public let destructive: Bool
    /// Surfaced as MCP `readOnlyHint`.
    public let readOnly: Bool
    /// True only when the tool genuinely needs the app's WINDOW on screen (it
    /// drives live view state rather than a store/client the app owns headlessly).
    /// The host force-opens the app before dispatching such a call; everything
    /// else runs in the background, which is what a tool call should do.
    ///
    /// Deliberately a settable `var` with a default rather than a new parameter
    /// on `init`: adding a parameter changes the initializer's mangled name and
    /// every already-compiled plugin bundle binds to the old one. Authors opt in
    /// with `var spec = MCPToolSpec(…); spec.requiresLiveApp = true`.
    public var requiresLiveApp: Bool = false
    /// Receives the call's `arguments` object as a JSON string.
    public let handler: @MainActor @Sendable (String) async -> AgentActionResult

    public init(
        name: String, description: String, schemaJSON: String,
        destructive: Bool = false, readOnly: Bool = false,
        handler: @escaping @MainActor @Sendable (String) async -> AgentActionResult
    ) {
        self.name = name
        self.description = description
        self.schemaJSON = schemaJSON
        self.destructive = destructive
        self.readOnly = readOnly
        self.handler = handler
    }
}

/// The outcome of one resource read: the body plus whether producing it FAILED.
///
/// A bare `String` cannot distinguish "here is the terminal buffer" from "no
/// terminal is currently open" — the model has to interpret prose to tell them
/// apart. This is the resource-side twin of `AgentActionResult`, kept as its own
/// type rather than reusing that one because an action result is documented as
/// the outcome of an *action*, and a read is not one.
public struct MCPResourceContent: Equatable, Sendable {
    /// The resource body, or the failure explanation when `isError` is true.
    public let text: String
    /// True when the resource could not be produced; the host surfaces the read
    /// as an error tool result rather than passing `text` off as content.
    public let isError: Bool

    public init(text: String, isError: Bool = false) {
        self.text = text
        self.isError = isError
    }
}

/// One resource an app publishes for on-demand reads.
public struct MCPResourceSpec: Sendable {
    public let uri: String
    public let title: String
    public let mimeType: String
    /// WHEN the model should read this resource, e.g. "read this when the
    /// workspace context shows a truncated terminal". `title` names the thing;
    /// this says why you would reach for it, and it is the only part the model
    /// can act on when choosing between several resources.
    ///
    /// Named `purpose` rather than `description`: a stored property literally
    /// called `description` reads at every call site as the
    /// `CustomStringConvertible` member, and would shadow it outright if the
    /// type ever adopted that protocol. It still goes on the wire as MCP's
    /// standard `description` field.
    ///
    /// Settable `var` with a default for the same ABI reason as
    /// `requiresLiveApp` — see below.
    public var purpose: String = ""
    /// See `MCPToolSpec.requiresLiveApp` — same meaning, same ABI reasoning for
    /// why it is a settable `var` and not an `init` parameter.
    public var requiresLiveApp: Bool = false
    public let provider: @MainActor @Sendable () async -> String
    /// Optional richer provider that can report failure. When set it WINS over
    /// `provider`, which then goes uncalled; when nil the plain `provider` runs
    /// and its text is treated as a success. Additive on purpose: changing
    /// `provider`'s type, or adding an `init` parameter, remangles a symbol
    /// every already-compiled plugin bundle links against.
    public var resultProvider: (@MainActor @Sendable () async -> MCPResourceContent)?

    public init(
        uri: String, title: String, mimeType: String = "text/plain",
        provider: @escaping @MainActor @Sendable () async -> String
    ) {
        self.uri = uri
        self.title = title
        self.mimeType = mimeType
        self.provider = provider
    }
}

/// A minimal, dependency-free MCP server an app hosts in-process. Speaks
/// JSON-RPC 2.0 as strings so it can ride any transport — the host currently
/// uses an in-process one, but nothing here assumes that.
@MainActor public final class MCPAppServer {
    public let appID: String
    private var tools: [MCPToolSpec] = []
    private var resources: [MCPResourceSpec] = []

    public init(appID: String) { self.appID = appID }

    /// Registering the same name twice keeps the first — matching the host's
    /// `AgentToolRegistry`, where the earlier registration wins. Reports failure
    /// (rather than silently no-oping) so a plugin author gets a signal that a
    /// tool was dropped — either because its name collided or because its
    /// `schemaJSON` didn't parse as a JSON object — instead of discovering it
    /// only when the assistant never sees the tool.
    @discardableResult
    public func addTool(_ spec: MCPToolSpec) -> Bool {
        guard !tools.contains(where: { $0.name == spec.name }),
            Self.parseSchema(spec.schemaJSON) != nil
        else { return false }
        tools.append(spec)
        return true
    }

    /// Reports failure (rather than silently no-oping) so a plugin author gets
    /// a signal that a resource was dropped because its `uri` collided with an
    /// already-registered one.
    @discardableResult
    public func addResource(_ spec: MCPResourceSpec) -> Bool {
        guard !resources.contains(where: { $0.uri == spec.uri }) else { return false }
        resources.append(spec)
        return true
    }

    /// Handles one JSON-RPC message. Returns the encoded response, or an EMPTY
    /// string for a notification (no `id`) — the transport must not surface an
    /// empty reply as a message.
    public func handle(_ message: String) async -> String {
        guard let data = message.data(using: .utf8),
            let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else {
            return Self.encode([
                "jsonrpc": "2.0", "id": NSNull(),
                "error": ["code": -32700, "message": "parse error"],
            ])
        }
        guard let id = root["id"] else { return "" }  // notification
        guard let method = root["method"] as? String else {
            // Has an id but no method at all — a malformed request, not a
            // lookup against a method that simply doesn't exist.
            return Self.error(id, code: -32600, message: "invalid request: missing method")
        }
        let params = root["params"] as? [String: Any] ?? [:]

        switch method {
        case "initialize":
            return Self.result(
                id,
                [
                    "protocolVersion": "2024-11-05",
                    "serverInfo": ["name": appID, "version": "1.0"],
                    "capabilities": ["tools": [String: Any](), "resources": [String: Any]()],
                ])

        case "tools/list":
            return Self.result(
                id,
                [
                    "tools": tools.map { spec in
                        [
                            "name": spec.name,
                            "description": spec.description,
                            // Fallback is unreachable: `addTool` already rejects specs
                            // whose `schemaJSON` doesn't parse, so every stored spec's
                            // schema parses here too.
                            "inputSchema": Self.parseSchema(spec.schemaJSON) ?? ["type": "object"],
                            // `ainkrad/requiresLiveApp` is namespaced because it is NOT
                            // a standard MCP annotation, unlike its two neighbours — a
                            // generic MCP client must be able to tell ours apart from
                            // the spec'd ones. Always emitted, including `false`, so
                            // the host reads one shape rather than inferring a default
                            // from absence.
                            "annotations": [
                                "destructiveHint": spec.destructive,
                                "readOnlyHint": spec.readOnly,
                                "ainkrad/requiresLiveApp": spec.requiresLiveApp,
                            ],
                        ]
                    }
                ])

        case "tools/call":
            guard let name = params["name"] as? String,
                let spec = tools.first(where: { $0.name == name })
            else {
                return Self.error(
                    id, code: -32602,
                    message: "unknown tool '\(params["name"] as? String ?? "")'")
            }
            let arguments = params["arguments"] as? [String: Any] ?? [:]
            let argumentJSON = Self.encodeAny(arguments)
            let outcome = await spec.handler(argumentJSON)
            // A handler FAILURE is a successful RPC carrying isError:true — an
            // MCP `error` means the call could not be made at all. `MCPClient`
            // relies on this split: it throws on `error`, and surfaces
            // `isError` as a visible tool result.
            return Self.result(
                id,
                [
                    "content": [["type": "text", "text": outcome.text]],
                    "isError": outcome.isError,
                ])

        case "resources/list":
            return Self.result(
                id,
                [
                    "resources": resources.map { spec in
                        // Resources have no standard MCP annotations block, but the host
                        // reads the flag the same way it does for tools, so carry it in
                        // the same namespaced key under an `annotations` object.
                        // `description` is standard MCP and always emitted, empty when
                        // the app didn't set `purpose` — one shape for the host to
                        // decode rather than a key that comes and goes.
                        [
                            "uri": spec.uri, "name": spec.title, "mimeType": spec.mimeType,
                            "description": spec.purpose,
                            "annotations": ["ainkrad/requiresLiveApp": spec.requiresLiveApp],
                        ]
                    }
                ])

        case "resources/read":
            guard let uri = params["uri"] as? String,
                let spec = resources.first(where: { $0.uri == uri })
            else {
                return Self.error(
                    id, code: -32002,
                    message: "unknown resource '\(params["uri"] as? String ?? "")'")
            }
            // `resultProvider` wins when set; otherwise the legacy `provider`
            // runs and its text is a success by definition.
            let outcome: MCPResourceContent
            if let richProvider = spec.resultProvider {
                outcome = await richProvider()
            } else {
                outcome = MCPResourceContent(text: await spec.provider())
            }
            // A failed READ is still a successful RPC — same split as
            // `tools/call`, where an MCP `error` means the call could not be
            // made at all. But `resources/read`'s result has no spec'd place to
            // say "this failed": `isError` belongs to CallToolResult only, and
            // the contents entry is just uri/mimeType/text. So the flag rides
            // alongside `contents` under the same `ainkrad/` namespace used for
            // `annotations["ainkrad/requiresLiveApp"]`, and is always emitted so
            // the host reads one shape. A generic MCP client ignores it and
            // still sees the text.
            return Self.result(
                id,
                [
                    "contents": [
                        ["uri": spec.uri, "mimeType": spec.mimeType, "text": outcome.text]
                    ],
                    "ainkrad/isError": outcome.isError,
                ])

        default:
            return Self.error(id, code: -32601, message: "unknown method '\(method)'")
        }
    }

    // MARK: - encoding helpers

    static func result(_ id: Any, _ result: [String: Any]) -> String {
        encode(["jsonrpc": "2.0", "id": id, "result": result], id: id)
    }

    static func error(_ id: Any, code: Int, message: String) -> String {
        encode(["jsonrpc": "2.0", "id": id, "error": ["code": code, "message": message]], id: id)
    }

    /// `id` is passed separately from `object` so the encode-failure fallback
    /// can echo the real request id — a transport correlating replies by id
    /// would otherwise leave that continuation dangling until timeout. `nil`
    /// only for the `-32700` parse-error path, where no id could be recovered
    /// because the message itself failed to parse.
    static func encode(_ object: [String: Any], id: Any? = nil) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
            let string = String(data: data, encoding: .utf8)
        else {
            let fallbackID = id ?? NSNull()
            guard
                let fallbackData = try? JSONSerialization.data(
                    withJSONObject: [
                        "jsonrpc": "2.0", "id": fallbackID,
                        "error": ["code": -32603, "message": "encode failed"],
                    ] as [String: Any]),
                let fallbackString = String(data: fallbackData, encoding: .utf8)
            else {
                return #"{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"encode failed"}}"#
            }
            return fallbackString
        }
        return string
    }

    /// Parses a tool's schema string into a nested object. Returns `nil` when
    /// the string doesn't parse as a JSON object, so `addTool` can reject a
    /// malformed schema at registration rather than silently degrading it to
    /// a permissive object schema at `tools/list` time.
    static func parseSchema(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8),
            let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else {
            return nil
        }
        return object
    }

    static func encodeAny(_ object: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: object),
            let string = String(data: data, encoding: .utf8)
        else { return "{}" }
        return string
    }
}
