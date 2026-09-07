import SwiftUI
import Observation

/// Lets an app read and override how the host presents it — tiled `.pane` or
/// floating `.overlay`. An override takes effect the next time the app is
/// opened; it never morphs an already-open window. Added v5.
@MainActor public protocol PluginPresentationControl {
    /// The effective presentation: the user override if one is set, otherwise
    /// the bundle's `AinkradPresentation` default.
    var current: PluginPresentation { get }
    /// Persist a user override. Takes effect on the app's next open.
    func set(_ presentation: PluginPresentation)
    /// Clear the override, reverting to the bundle's declared default.
    func reset()
}

/// The complete set of host capabilities a loaded app may touch. Deliberately
/// narrow: no access to the registry, other apps, or window management. Apps MAY
/// publish their own read-only context via `context` and their own gated actions
/// via `actions`, but still cannot read the registry or other apps.
@MainActor public protocol HostServices {
    /// Namespaced key→data storage scoped to this app.
    var documents: PluginDocumentStore { get }
    /// Namespaced secret storage scoped to this app (Keychain-backed in the host).
    var secrets: PluginSecretStore { get }
    /// The host's resolved theme, observable so apps recolor live on a theme change.
    var theme: HostTheme { get }
    /// Structured logging under this app's subsystem.
    var log: PluginLogger { get }
    /// Lets this app publish read-only context the host's agent may consult.
    var context: PluginContextRegistry { get }
    /// Lets this app publish gated actions the host's agent may invoke.
    var actions: AgentActionProvider { get }
    /// Lets this app open another app with an opaque payload, and retrieve a
    /// payload aimed at it. Added v4.
    var apps: PluginAppLauncher { get }
    /// Lets this app read/override its own presentation (pane vs overlay).
    /// The change applies on next open. Added v5.
    var presentation: PluginPresentationControl { get }
    /// Lets this app record events in the host's Signal feed. Write-only with
    /// respect to other apps: the emitter is bound to this app's id, so an app
    /// cannot attribute an event to another. Reading the aggregated feed is not
    /// part of this generation. Added v9.
    var signals: PluginSignalEmitter { get }
}

/// Observable wrapper over `HostThemeTokens`. The host mutates it on a theme
/// change; SwiftUI views that read `tokens` in their `body` re-render.
@MainActor
@Observable
public final class HostTheme {
    public private(set) var tokens: HostThemeTokens

    /// Semantic status colors for the active theme.
    ///
    /// Carried here rather than as fields on `HostThemeTokens`, which is
    /// ABI-frozen for plugins (`ContractFreezeTests` asserts it gains no stored
    /// fields). `HostTheme` is a non-frozen class, so a new stored property is
    /// ABI-safe, and `init(_:)` is left untouched so nothing already compiled
    /// against generation 7 changes.
    ///
    /// Until generation 8, plugins had no way to express status through the
    /// theme at all — `HostThemeTokens` carries only background, surface,
    /// accents and foreground — which is exactly why they hardcoded system
    /// colors.
    public private(set) var statusColors: HostStatusColors

    public init(_ tokens: HostThemeTokens) {
        self.tokens = tokens
        self.statusColors = HostStatusColors(derivedFrom: tokens)
    }

    public func update(_ tokens: HostThemeTokens) {
        self.tokens = tokens
        self.statusColors = HostStatusColors(derivedFrom: tokens)
    }

    /// Publishes the host's real status palette, replacing the derived default.
    public func updateStatusColors(_ colors: HostStatusColors) {
        self.statusColors = colors
    }
}

/// Semantic status colors, delivered separately from `HostThemeTokens` so that
/// frozen type never has to grow.
public struct HostStatusColors: Equatable, Sendable {
    public let success: Color
    public let warning: Color
    public let danger: Color

    public init(success: Color, warning: Color, danger: Color) {
        self.success = success
        self.warning = warning
        self.danger = danger
    }

    /// Fallback when the host publishes nothing: the theme's own accents, which
    /// are already chosen for contrast against its background. Less precise
    /// than the host's real palette, but theme-following — the property that
    /// matters, and the one a hardcoded `.green` lacked.
    public init(derivedFrom tokens: HostThemeTokens) {
        self.success = tokens.accentSecondary
        self.warning = tokens.accentTertiary
        self.danger = tokens.accentTertiary
    }
}

/// Small key→data store. Apps encode their own `Codable` state into `Data`.
public protocol PluginDocumentStore {
    func data(forKey key: String) -> Data?
    func setData(_ data: Data?, forKey key: String)
}

/// Small key→string secret store. Values never touch disk in plaintext.
public protocol PluginSecretStore {
    func secret(forKey key: String) -> String?
    func setSecret(_ value: String?, forKey key: String)
}

public protocol PluginLogger {
    func info(_ message: String)
    func error(_ message: String)
}

/// A plain snapshot of the host's resolved theme colors, so apps render
/// theme-correctly without importing host types.
public struct HostThemeTokens: Equatable, Sendable {
    /// Stable identity of the active theme (the host's theme id). Lets an app
    /// key its own per-theme assets without importing host theme types.
    public let themeID: String
    public let background: Color
    public let surface: Color
    public let surfaceElevated: Color
    public let accentPrimary: Color
    public let accentSecondary: Color
    public let accentTertiary: Color
    public let foreground: Color

    public init(themeID: String, background: Color, surface: Color, surfaceElevated: Color,
                accentPrimary: Color, accentSecondary: Color, accentTertiary: Color,
                foreground: Color) {
        self.themeID = themeID
        self.background = background
        self.surface = surface
        self.surfaceElevated = surfaceElevated
        self.accentPrimary = accentPrimary
        self.accentSecondary = accentSecondary
        self.accentTertiary = accentTertiary
        self.foreground = foreground
    }
}
