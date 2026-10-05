import SwiftUI

/// The contract a plugin bundle implements. Mirrors the host's internal
/// Built-in App shape but depends only on `HostServices`, never the host binary.
@MainActor public protocol AinkradApp {
    static var id: String { get }
    static var displayName: String { get }
    /// SF Symbol name. Tint from `host.theme`, never a hardcoded color.
    static var icon: String { get }
    static func makeRootView(host: HostServices) -> AnyView
    static func makeSettingsView(host: HostServices) -> AnyView
    /// The window's own background fill (color + opacity). Default `nil`.
    static func chromeFill(host: HostServices) -> Color?
    /// Publish this app's settings as descriptors so the host can index,
    /// deep-link, and lay them out with every other setting. Return `nil`
    /// (the default) to keep rendering `makeSettingsView(host:)` unchanged —
    /// the app is then searchable by name only.
    ///
    /// Migration is incremental: declare the fields you can, and leave the
    /// rest as a single `.custom` field wrapping your existing view.
    static func settingsCatalog(host: HostServices) -> SettingsPage?
}

extension AinkradApp {
    public static func chromeFill(host: HostServices) -> Color? { nil }
    public static func settingsCatalog(host: HostServices) -> SettingsPage? { nil }
}

/// A bundle's `NSPrincipalClass` conforms to this; the host casts the loaded
/// principal class to it to obtain the app type.
@MainActor public protocol AinkradPluginEntryPoint: AnyObject {
    static func app() -> any AinkradApp.Type
}
