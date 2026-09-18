import Testing
import SwiftUI
@testable import AinkradAppKit

/// Generation 11's Basic Mode contract.
///
/// The load-bearing property is that it is ADDITIVE: a generation-10 bundle,
/// which cannot carry `AinkradMode` and does not conform to `AinkradAppModes`,
/// must parse, validate and behave exactly as it did before.
@Suite("Plugin mode contract")
struct PluginModeTests {

    // MARK: - Opt-in, never required

    @Test("Modes are discovered by cast, not required of every app")
    @MainActor
    func modesAreOptIn() {
        // An app with no basic mode does not conform — and that must be fine,
        // because that is how Scry (a HUD canvas) opts out with no special case.
        #expect((ModelessApp.self as Any) as? AinkradAppModes.Type == nil,
                "a basic mode must not be a requirement of AinkradApp")
        #expect((ModalApp.self as Any) as? AinkradAppModes.Type != nil)
    }

    @Test("A conforming app is reached through the cast the host performs")
    @MainActor
    func castReachesTheModeAwareOverload() {
        let modal = (ModalApp.self as Any) as? AinkradAppModes.Type
        #expect(modal != nil)
        _ = modal?.makeRootView(host: ModeStubHost(), mode: .basic)
        #expect(ModalApp.lastMode == .basic)
        _ = modal?.makeRootView(host: ModeStubHost(), mode: .advanced)
        #expect(ModalApp.lastMode == .advanced)
    }

    // MARK: - Manifest parsing

    @Test("A bundle declaring a mode carries it through parse")
    func declaredModeIsParsed() {
        let parsed = PluginBundleMetadata.parse(infoDictionary: info(["AinkradMode": "basic"]))
        #expect(try! parsed.get().mode == .basic)
    }

    @Test("A generation-10 bundle, which cannot carry the key, parses as advanced")
    func absentModeDefaultsToAdvanced() {
        let parsed = PluginBundleMetadata.parse(infoDictionary: info([:]))
        #expect(try! parsed.get().mode == .advanced)
    }

    @Test("An unrecognized mode falls back instead of failing the parse")
    func unrecognizedModeDefaultsToAdvanced() {
        // The failure this guards: a typo'd or future value making the bundle
        // unparseable would uninstall the app rather than degrade it.
        let parsed = PluginBundleMetadata.parse(infoDictionary: info(["AinkradMode": "turbo"]))
        #expect(try! parsed.get().mode == .advanced)
    }

    @Test("Mode and presentation are independent")
    func modeAndPresentationDoNotInterfere() {
        let d = info(["AinkradMode": "basic", "AinkradPresentation": "overlay"])
        let parsed = try! PluginBundleMetadata.parse(infoDictionary: d).get()
        #expect(parsed.mode == .basic)
        #expect(parsed.presentation == .overlay)
    }

    // MARK: - Environment defaults

    @Test("A pane mode absent from the environment reads as advanced")
    @MainActor
    func paneModeDefaultsToAdvanced() {
        // Rendered outside a host pane — previews, tests, an older host — an
        // app must show everything rather than appear stripped.
        #expect(EnvironmentValues().ainkradPaneMode == .advanced)
    }

    @Test("The pane-mode setter is a no-op outside a host pane")
    @MainActor
    func setPaneModeIsSafeOutsideAPane() {
        EnvironmentValues().ainkradSetPaneMode(.basic)
    }

    // MARK: - Fixtures

    private func info(_ extra: [String: Any]) -> [String: Any] {
        var d: [String: Any] = [
            "AinkradAppID": "fixture",
            "AinkradDisplayName": "Fixture",
            "AinkradIconSymbol": "circle",
            "AinkradAPIVersion": 11,
            "NSPrincipalClass": "FixtureEntryPoint",
            "CFBundleExecutable": "Fixture",
        ]
        for (k, v) in extra { d[k] = v }
        return d
    }
}

private enum ModelessApp: AinkradApp {
    static let id = "modeless"
    static let displayName = "Modeless"
    static let icon = "circle"
    static func makeRootView(host: HostServices) -> AnyView { AnyView(EmptyView()) }
    static func makeSettingsView(host: HostServices) -> AnyView { AnyView(EmptyView()) }
}

private enum ModalApp: AinkradApp, AinkradAppModes {
    static let id = "modal"
    static let displayName = "Modal"
    static let icon = "square"
    nonisolated(unsafe) static var lastMode: PluginMode?
    static func makeRootView(host: HostServices) -> AnyView { AnyView(EmptyView()) }
    static func makeSettingsView(host: HostServices) -> AnyView { AnyView(EmptyView()) }
    static func makeRootView(host: HostServices, mode: PluginMode) -> AnyView {
        lastMode = mode
        return AnyView(EmptyView())
    }
}

@MainActor private struct ModeStubHost: HostServices {
    var documents: PluginDocumentStore { ModeStubDocs() }
    var secrets: PluginSecretStore { ModeStubSecrets() }
    var theme: HostTheme {
        HostTheme(.init(themeID: "t", background: .black, surface: .black,
                        surfaceElevated: .black, accentPrimary: .white,
                        accentSecondary: .white, accentTertiary: .white, foreground: .white))
    }
    var log: PluginLogger { ModeStubLog() }
    var context: PluginContextRegistry { ModeStubContext() }
    var actions: AgentActionProvider { ModeStubActions() }
    var apps: PluginAppLauncher { ModeStubLauncher() }
    var presentation: PluginPresentationControl { ModeStubPresentation() }
    var mode: PluginModeControl { ModeStubMode() }
    var signals: PluginSignalEmitter { NoopSignalEmitter() }
}

private struct ModeStubDocs: PluginDocumentStore {
    func data(forKey key: String) -> Data? { nil }
    func setData(_ data: Data?, forKey key: String) {}
}
private struct ModeStubSecrets: PluginSecretStore {
    func secret(forKey key: String) -> String? { nil }
    func setSecret(_ value: String?, forKey key: String) {}
}
private struct ModeStubLog: PluginLogger {
    func info(_ message: String) {}
    func error(_ message: String) {}
}
@MainActor private struct ModeStubContext: PluginContextRegistry {
    func register(_ source: @escaping @MainActor () -> AgentContextSnapshot?) -> PluginContextToken {
        PluginContextToken()
    }
    func remove(_ token: PluginContextToken) {}
}
@MainActor private struct ModeStubActions: AgentActionProvider {
    func register(actionID: String,
                  handler: @escaping @MainActor (String) async -> AgentActionResult) -> AgentActionToken {
        AgentActionToken()
    }
    func remove(_ token: AgentActionToken) {}
}
@MainActor private struct ModeStubLauncher: PluginAppLauncher {
    func open(appID: String, payload: String?) {}
    func takePendingLaunch() -> String? { nil }
}
@MainActor private struct ModeStubPresentation: PluginPresentationControl {
    var current: PluginPresentation { .pane }
    func set(_ presentation: PluginPresentation) {}
    func reset() {}
}
@MainActor private struct ModeStubMode: PluginModeControl {
    var current: PluginMode { .advanced }
    func set(_ mode: PluginMode) {}
    func reset() {}
}
