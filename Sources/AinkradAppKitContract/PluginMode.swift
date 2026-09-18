import SwiftUI

/// How much of an app is built when it opens.
///
/// `.basic` is a DIFFERENT root view over a NARROWER load — not the advanced
/// view with things hidden. That distinction is the whole point: hiding a
/// subview still constructs it, still runs its `.task`, and still pays for
/// whatever it loads, so a "basic" mode built that way is slower to open than
/// the advanced one it was meant to replace.
///
/// Defaults to `.advanced` everywhere it is absent, so nothing changes for an
/// app that never opts in.
public enum PluginMode: String, Codable, Sendable, CaseIterable {
    case basic
    case advanced
}

/// Opt-in: an app that supports a basic mode declares it by conforming, and the
/// host finds it by CAST — exactly as it finds `AinkradAppMCP`,
/// `AinkradAppTeardown`, `AinkradAppSignalObserving` and `PluginAppLauncherResult`.
///
/// ## Why this is not a requirement on `AinkradApp`
///
/// An added protocol requirement is the one ABI break library evolution does
/// not cover: an already-installed bundle has no witness for it, so it fails at
/// `Bundle.load()` with no diagnostic and the app simply does not appear. The
/// host has been adding optional capability this way since generation 8 for
/// that reason, and `ContractFreezeTests` asserts it.
///
/// It also means an app with no sensible basic mode — Scry, a HUD canvas the
/// assistant drives — opts out by doing nothing, with no special case anywhere.
@MainActor public protocol AinkradAppModes {
    /// Build the root view for `mode`. The `.basic` branch must not construct
    /// the advanced view models or start the advanced load.
    static func makeRootView(host: HostServices, mode: PluginMode) -> AnyView
}

/// Reads and overrides the app's DEFAULT mode — the one it opens in. Per app,
/// persisted, edited in that app's settings. Mirrors `PluginPresentationControl`.
///
/// This is deliberately NOT the pane's current mode. See `\.ainkradPaneMode`.
@MainActor public protocol PluginModeControl {
    /// The effective default: the user override if one is set, otherwise the
    /// bundle's `AinkradMode`.
    var current: PluginMode { get }
    /// Persist a user override. Applies to panes opened after it.
    func set(_ mode: PluginMode)
    /// Clear the override, reverting to the bundle's declared default.
    func reset()
}

/// This pane's live mode, and the way to change it.
///
/// ## Why the mode is split in two
///
/// `PluginModeControl` answers "what does this app OPEN in" — one value per
/// app, persisted. These answer "what is THIS PANE showing right now" — one
/// value per pane, not persisted.
///
/// The split is the same one `\.ainkradPaneIsFocused` documents, for the same
/// reason: one app can have several panes, and `HostServices` is scoped to the
/// app, so it is structurally the wrong place for per-pane state. Switching one
/// Git Mage pane to advanced must not move the other one.
///
/// Not persisting the switch is a product decision, not an oversight. The
/// setting says which mode you want on open; if reaching for advanced once
/// rewrote that setting, the next open would silently be advanced too, and the
/// setting would erode to whichever mode was used last.
public extension EnvironmentValues {
    /// The mode this pane is showing. Defaults to `.advanced` so a plugin
    /// rendered outside a host pane — previews, tests, an older host that never
    /// sets it — shows everything rather than appearing stripped.
    @Entry var ainkradPaneMode: PluginMode = .advanced

    /// Ask the host to switch THIS pane's mode. No-op outside a host pane.
    @Entry var ainkradSetPaneMode: @MainActor (PluginMode) -> Void = { _ in }
}
