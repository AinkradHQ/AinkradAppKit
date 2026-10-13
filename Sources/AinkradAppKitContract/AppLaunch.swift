import Foundation

/// Lets an app request opening ANOTHER app and hand it an opaque payload, and
/// lets the opened app retrieve the payload aimed at it. The payload is an
/// opaque string; apps agree on their own encoding (e.g. JSON). Deliberately
/// narrow — open-by-id + opaque payload only, still no registry/window access.
@MainActor public protocol PluginAppLauncher {
    /// Request that the host open `appID` in a new pane, delivering `payload`
    /// to it. A nil payload clears any pending payload for that target.
    func open(appID: String, payload: String?)
    /// Pull (and clear) the payload most recently aimed at THIS app, if any.
    /// Called by the opened app as it starts. Nil when there is none.
    func takePendingLaunch() -> String?
}

/// Opt-in: the host can say whether another app is installed and enabled, so
/// a plugin can label a link by what it will open ("↗ Forge" vs "↗ Open").
///
/// A separate protocol found by dynamic cast — NOT a new `PluginAppLauncher`
/// requirement — for the same reason as `PluginAppLauncherResult`: an added
/// requirement has no witness in an already-built conformer and fails to load.
/// The host's launcher adopts it; plugins call
/// `PluginAppLauncher.appAvailability(appID:)` below rather than casting.
@MainActor public protocol PluginAppAvailability {
    /// True when `appID` is registered and not disabled by the user.
    func isAppAvailable(appID: String) -> Bool
}

extension PluginAppLauncher {
    /// Whether `appID` is installed and enabled: nil when this host does not
    /// say (it predates `PluginAppAvailability`), so a plugin keeps its old
    /// behaviour there instead of guessing.
    public func appAvailability(appID: String) -> Bool? {
        (self as? PluginAppAvailability)?.isAppAvailable(appID: appID)
    }
}
