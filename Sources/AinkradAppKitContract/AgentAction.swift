import Foundation

/// The text/isError result a gated plugin action returns to the host agent.
/// Mirrors the host's `ToolResult` so a tool can forward it verbatim.
public struct AgentActionResult: Equatable, Sendable {
    /// Human/agent-facing result text (command output, git result, …).
    public let text: String
    /// True when the action failed; the host surfaces it as an error tool_result.
    public let isError: Bool

    public init(text: String, isError: Bool) {
        self.text = text
        self.isError = isError
    }
}

/// Opaque handle returned by `AgentActionProvider.register`.
public struct AgentActionToken: Hashable, Sendable {
    public let id: UUID
    public init(id: UUID = UUID()) { self.id = id }
}

/// Lets a plugin publish gated **actions** the host's agent may invoke. The
/// write-side counterpart to `PluginContextRegistry`. Parameters arrive as a
/// JSON string (the SDK has no JSON value type); the plugin decodes them. The
/// host holds the handler weakly via a register-once-per-host bridge and never
/// tears it down — the closure returns an error/no-op result once its source is
/// gone. A plugin exposes only its own actions; it cannot read the registry or
/// other apps.
@MainActor public protocol AgentActionProvider {
    func register(
        actionID: String,
        handler: @escaping @MainActor (String) async -> AgentActionResult
    ) -> AgentActionToken
    func remove(_ token: AgentActionToken)
}
