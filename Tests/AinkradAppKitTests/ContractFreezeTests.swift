import Testing
import Foundation
import SwiftUI
@testable import AinkradAppKit
@testable import AinkradAppKitContract

/// Generation 8 freezes the plugin contract. These tests are the enforcement —
/// the audit's point was that the ABI rule existed only as prose, and prose
/// does not fail a build.
///
/// **The rule.** `AinkradApp`, `AinkradPluginEntryPoint` and `HostServices` are
/// closed. New capability arrives as a *new* protocol found by dynamic cast, or
/// as a defaulted protocol extension — never as a new requirement.
///
/// **Why specifically requirements.** Library evolution makes additive changes
/// safe for almost everything: new types, new methods, new stored properties on
/// non-frozen structs. It does **not** cover an added protocol requirement. An
/// already-compiled bundle's witness table has no entry for it, so the plugin
/// fails to load — and `swift-api-digester`'s report does not phrase that with
/// the words the old `grep "has been"` guardrail looked for. It is the one ABI
/// cliff that was both real and invisible.
@Suite("Plugin contract is frozen")
struct ContractFreezeTests {

    // MARK: - The closed protocols

    /// A type conforming to `AinkradApp` with ONLY the generation-7 members.
    /// If a requirement is ever added, this stops compiling — which is the
    /// whole mechanism. It is a compile-time assertion wearing a test's
    /// clothes; the runtime checks below just keep it referenced.
    private enum FrozenApp: AinkradApp {
        static let id = "frozen"
        static let displayName = "Frozen"
        static let icon = "lock"
        static func makeRootView(host: HostServices) -> AnyView { AnyView(EmptyView()) }
        static func makeSettingsView(host: HostServices) -> AnyView { AnyView(EmptyView()) }
        // `chromeFill` deliberately omitted — it must remain DEFAULTED.
    }

    private final class FrozenEntryPoint: AinkradPluginEntryPoint {
        static func app() -> any AinkradApp.Type { FrozenApp.self }
    }

    @Test("A generation-7 shaped app still satisfies AinkradApp")
    @MainActor
    func generationSevenAppStillConforms() {
        #expect(FrozenApp.id == "frozen")
        #expect(FrozenApp.chromeFill(host: StubHost()) == nil, "chromeFill must stay defaulted")
        #expect(FrozenEntryPoint.app() is FrozenApp.Type)
    }

    /// This stub failing to compile means a requirement was added to
    /// `HostServices`.
    ///
    /// It used to say the host is the only conformer. That is true in
    /// production, but NOT in the plugin repos: Raven, Rune and GitMage each
    /// fake a conformance in their test support, so a new requirement breaks
    /// their builds too. Verified at generation 9, when `signals` was added and
    /// all three needed updating. Do not restate the old claim.
    @MainActor
    private struct StubHost: HostServices {
        var documents: PluginDocumentStore { StubDocs() }
        var secrets: PluginSecretStore { StubSecrets() }
        var theme: HostTheme { HostTheme(.init(themeID: "t", background: .black, surface: .black,
                                               surfaceElevated: .black, accentPrimary: .white,
                                               accentSecondary: .white, accentTertiary: .white,
                                               foreground: .white)) }
        var log: PluginLogger { StubLog() }
        var context: PluginContextRegistry { StubContext() }
        var actions: AgentActionProvider { StubActions() }
        var apps: PluginAppLauncher { StubLauncher() }
        var presentation: PluginPresentationControl { StubPresentation() }
        var signals: PluginSignalEmitter { NoopSignalEmitter() }
    }

    // MARK: - New capability must be opt-in, never required

    @Test("Teardown is discovered by cast, not required of every app")
    @MainActor
    func teardownIsOptIn() {
        // The generation-7 app does NOT conform — and that must be fine.
        #expect((FrozenApp.self as Any) as? AinkradAppTeardown.Type == nil,
                "teardown must not be a requirement of AinkradApp")

        // An app that opts in is found by exactly the cast the host performs.
        #expect((OptsIntoTeardown.self as Any) as? AinkradAppTeardown.Type != nil)
    }

    private enum OptsIntoTeardown: AinkradApp, AinkradAppTeardown {
        static let id = "opts-in"
        static let displayName = "Opts In"
        static let icon = "lock.open"
        static func makeRootView(host: HostServices) -> AnyView { AnyView(EmptyView()) }
        static func makeSettingsView(host: HostServices) -> AnyView { AnyView(EmptyView()) }
        nonisolated(unsafe) static var torndown: [PluginInstanceID] = []
        static func teardown(instance: PluginInstanceID) { torndown.append(instance) }
    }

    @Test("Instance identity is discovered by cast, not a HostServices requirement")
    @MainActor
    func identityIsOptIn() {
        // A generation-7 host provides no identity; the cast fails and the
        // plugin falls back rather than breaking.
        #expect((StubHost() as Any) as? PluginInstanceIdentity == nil)
    }

    // MARK: - Generation window

    @Test("The supported range is honest about what can actually load")
    func generationWindowIsHonest() {
        // The POLICY is a one-release window (`current - 1`), so a generation
        // bump is a migration rather than an outage. It took effect at
        // generation 9.
        //
        // Generation 8 could not honour it: splitting the module renamed every
        // symbol (Swift mangles the module name in), so a generation-7 binary
        // passed the version check and then failed to LINK. Promising support
        // we cannot deliver turns a clear "update this app" into an opaque
        // "failed to load". See abi/README-module-renames.md.
        //
        // Generation 9 adds only `HostServices.signals` and
        // `PluginSignalEmitter`. Nothing moved, nothing was renamed, so the
        // window is real and a generation-8 bundle loads.
        //
        // Generation 10 WIDENED it to two releases. The floor is asserted as a
        // range rather than an exact offset because the honest invariant is
        // "at least one release, and never a floor above the generations still
        // in the field" — not a particular number. Generation 10's arithmetic
        // floor would have been 9, at which point every installed bundle (all
        // still generation 8) stopped loading; a host that launches with none
        // of the user's apps is the outage this window exists to prevent, not
        // the window working.
        //
        // The bound below still forbids the failure that motivated the policy:
        // generation 8 set the floor EQUAL to `apiVersion` and de-registered
        // every installed plugin the moment it shipped.
        #expect(AinkradAppKit.minSupportedAPIVersion <= AinkradAppKit.apiVersion - 1,
                "always advertise at least one release of support")
        #expect(AinkradAppKit.minSupportedAPIVersion >= AinkradAppKit.apiVersion - 2,
                "and not so many that every addition must stay optional forever")

        // Whatever the window is, the range must be self-consistent: the
        // current generation loads, the future one does not.
        #expect(AinkradAppKit.isCompatible(
            bundleAPIVersion: AinkradAppKit.apiVersion,
            minSupported: AinkradAppKit.minSupportedAPIVersion,
            current: AinkradAppKit.apiVersion))
        #expect(!AinkradAppKit.isCompatible(
            bundleAPIVersion: AinkradAppKit.apiVersion + 1,
            minSupported: AinkradAppKit.minSupportedAPIVersion,
            current: AinkradAppKit.apiVersion), "a future generation must not load")
        #expect(!AinkradAppKit.isCompatible(
            bundleAPIVersion: AinkradAppKit.minSupportedAPIVersion - 1,
            minSupported: AinkradAppKit.minSupportedAPIVersion,
            current: AinkradAppKit.apiVersion), "below the floor must not load")
    }

    // MARK: - Layering

    @Test("HostThemeTokens gained no stored fields")
    func themeTokensUnchanged() {
        // Status colors go in their own env-injected struct precisely so this
        // frozen type never grows. Guarded by name so the intent is explicit.
        let mirror = Mirror(reflecting: HostThemeTokens(
            themeID: "t", background: .black, surface: .black, surfaceElevated: .black,
            accentPrimary: .white, accentSecondary: .white, accentTertiary: .white, foreground: .white))
        #expect(mirror.children.map { $0.label ?? "" }.sorted() == [
            "accentPrimary", "accentSecondary", "accentTertiary",
            "background", "foreground", "surface", "surfaceElevated", "themeID",
        ])
    }
}

// MARK: - Minimal stubs for the frozen HostServices surface

private struct StubDocs: PluginDocumentStore {
    func data(forKey key: String) -> Data? { nil }
    func setData(_ data: Data?, forKey key: String) {}
}
private struct StubSecrets: PluginSecretStore {
    func secret(forKey key: String) -> String? { nil }
    func setSecret(_ value: String?, forKey key: String) {}
}
private struct StubLog: PluginLogger {
    func info(_ message: String) {}
    func error(_ message: String) {}
}

@MainActor private struct StubContext: PluginContextRegistry {
    func register(_ source: @escaping @MainActor () -> AgentContextSnapshot?) -> PluginContextToken {
        PluginContextToken(id: UUID())
    }
    func remove(_ token: PluginContextToken) {}
}
@MainActor private struct StubActions: AgentActionProvider {
    func register(actionID: String,
                  handler: @escaping @MainActor (String) async -> AgentActionResult) -> AgentActionToken {
        AgentActionToken(id: UUID())
    }
    func remove(_ token: AgentActionToken) {}
}
@MainActor private struct StubLauncher: PluginAppLauncher {
    func open(appID: String, payload: String?) {}
    func takePendingLaunch() -> String? { nil }
}
@MainActor private struct StubPresentation: PluginPresentationControl {
    var current: PluginPresentation { .pane }
    func set(_ presentation: PluginPresentation) {}
    func reset() {}
}
