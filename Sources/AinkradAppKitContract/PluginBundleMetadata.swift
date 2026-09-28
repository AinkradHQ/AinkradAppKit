import Foundation

/// Info.plist keys a plugin bundle declares. Read WITHOUT loading code so the
/// host can validate a bundle before executing any of it.
public enum PluginInfoKey {
    public static let appID = "AinkradAppID"
    public static let displayName = "AinkradDisplayName"
    public static let iconSymbol = "AinkradIconSymbol"
    public static let apiVersion = "AinkradAPIVersion"
    public static let principalClass = "NSPrincipalClass"
    public static let presentation = "AinkradPresentation"
    /// Which mode the app opens in (generation 11). Absent or unrecognized
    /// means `.advanced`, so every pre-generation-11 bundle keeps its
    /// behaviour exactly — see `PluginMode`.
    public static let mode = "AinkradMode"
    /// Store-listing completeness fields (sub-project D). Read directly from
    /// the Info.plist by `StorePolicy` callers rather than folded into the
    /// strict `PluginBundleMetadata.parse` (which stays ABI-frozen): a bundle
    /// missing these still parses/loads, but fails `StorePolicy` review.
    public static let author = "AinkradAuthor"
    public static let description = "description"

    /// Declared cross-app subscriptions (generation 10): an array of
    /// `<source>/<kindPattern>` strings — see `SignalSubscription`.
    ///
    /// Read directly from the Info.plist for the same reason `author` and
    /// `description` are, and it matters more here: folding it into the frozen
    /// `PluginBundleMetadata.parse` would make every generation-9 bundle —
    /// which cannot possibly carry this key — fail to parse, and a
    /// notification feature would have uninstalled the user's apps.
    public static let signalSubscriptions = "AinkradSignalSubscriptions"
}

/// How a plugin's window should be presented by the host. Defaults to `.pane`
/// when the bundle omits `AinkradPresentation` or declares an unrecognized value.
public enum PluginPresentation: String, Sendable {
    case pane
    case overlay
}

public struct PluginBundleMetadata: Equatable {
    public let appID: String
    public let displayName: String
    public let iconSymbol: String
    public let apiVersion: Int
    public let principalClassName: String
    public let presentation: PluginPresentation
    /// The mode the app opens in. Defaulted in `init`, so every existing call
    /// site keeps compiling and keeps meaning `.advanced`.
    public let mode: PluginMode

    /// The pre-generation-11 initializer, kept EXACTLY as it was.
    ///
    /// Adding `mode:` to it — even defaulted — changes the mangled symbol and
    /// removes this one, which `make abi-check` correctly reports as a removal.
    /// A defaulted parameter is source-compatible, not ABI-compatible. So the
    /// old spelling stays and delegates; generation 11's callers use the
    /// overload below.
    public init(appID: String, displayName: String, iconSymbol: String,
                apiVersion: Int, principalClassName: String,
                presentation: PluginPresentation = .pane) {
        self.init(appID: appID, displayName: displayName, iconSymbol: iconSymbol,
                  apiVersion: apiVersion, principalClassName: principalClassName,
                  presentation: presentation, mode: .advanced)
    }

    /// Generation 11. No defaults, so it can never be ambiguous with the
    /// initializer above.
    public init(appID: String, displayName: String, iconSymbol: String,
                apiVersion: Int, principalClassName: String,
                presentation: PluginPresentation,
                mode: PluginMode) {
        self.appID = appID
        self.displayName = displayName
        self.iconSymbol = iconSymbol
        self.apiVersion = apiVersion
        self.principalClassName = principalClassName
        self.presentation = presentation
        self.mode = mode
    }
}

public enum PluginMetadataError: Error, Equatable {
    case missingKey(String)
    case invalidAPIVersion
}

public extension PluginBundleMetadata {
    /// Parses and validates plugin metadata from an Info.plist dictionary.
    static func parse(infoDictionary dict: [String: Any]) -> Result<PluginBundleMetadata, PluginMetadataError> {
        func string(_ key: String) -> String? { dict[key] as? String }
        guard let appID = string(PluginInfoKey.appID) else { return .failure(.missingKey(PluginInfoKey.appID)) }
        guard let displayName = string(PluginInfoKey.displayName) else { return .failure(.missingKey(PluginInfoKey.displayName)) }
        guard let icon = string(PluginInfoKey.iconSymbol) else { return .failure(.missingKey(PluginInfoKey.iconSymbol)) }
        guard let principal = string(PluginInfoKey.principalClass) else { return .failure(.missingKey(PluginInfoKey.principalClass)) }
        guard let api = dict[PluginInfoKey.apiVersion] as? Int else { return .failure(.invalidAPIVersion) }
        let presentation = PluginPresentation(rawValue: (dict[PluginInfoKey.presentation] as? String) ?? "") ?? .pane
        // Same shape as `presentation`: a missing or unrecognized value falls
        // back rather than failing the parse, so a generation-10 bundle — which
        // cannot carry this key — still loads.
        let mode = PluginMode(rawValue: (dict[PluginInfoKey.mode] as? String) ?? "") ?? .advanced
        return .success(PluginBundleMetadata(appID: appID, displayName: displayName,
                                             iconSymbol: icon, apiVersion: api,
                                             principalClassName: principal,
                                             presentation: presentation,
                                             mode: mode))
    }
}
