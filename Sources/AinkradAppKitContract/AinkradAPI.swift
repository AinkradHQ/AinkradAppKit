import Foundation

/// The public entry namespace for the Ainkrad Built-in App SDK.
public enum AinkradAppKit {
    /// The API generation this SDK represents. A plugin bundle records the
    /// value it was built against; the host loads it only if that value is
    /// within the host's supported range.
    ///
    /// Generation 7 is the first resilient-ABI generation: the module builds
    /// with `-enable-library-evolution`, so additive public changes no
    /// longer break already-compiled plugin bundles that reuse the host's
    /// embedded copy.
    /// Generation 8 splits the module into an ABI-frozen contract plus a UI
    /// kit, and widens the plugin boundary: per-instance identity and
    /// `teardown`, host-owned focus, a typed cross-app launch payload, and
    /// status colors. Every one of those is **additive** — a generation-7
    /// bundle keeps loading, which is what `minSupportedAPIVersion` is for.
    /// Generation 10 adds cross-app READ, which is the first capability in
    /// this contract that lets one app see another's data — so it is the first
    /// one gated on the user rather than on the manifest alone. An app declares
    /// `AinkradSignalSubscriptions`, the user approves the named list at
    /// install, and only then does `PluginSignalObserver` receive anything.
    ///
    /// Also adds the pane locator, so a notification can focus the pane that
    /// produced it rather than the first pane of that app.
    ///
    /// Additive, so a generation-9 bundle keeps loading: the observer is a
    /// SEPARATE protocol discovered by cast (never a requirement added to
    /// `HostServices`), the manifest key is read outside the frozen
    /// `PluginBundleMetadata.parse`, and the locator travels through the
    /// SwiftUI environment rather than through `AinkradApp`.
    public static let apiVersion = 10

    /// The oldest generation a host built on this SDK still loads.
    ///
    /// **Generation 9 opens the one-release deprecation window generation 8
    /// documented and could not honor**, so this is `apiVersion - 1` (8).
    ///
    /// Generation 8 had to set this equal to `apiVersion`: splitting the module
    /// into `AinkradAppKitContract` + `AinkradAppKitUI` renamed every symbol,
    /// because Swift mangles the module name into its mangled names, so a
    /// generation-7 bundle referenced 71 symbols that no longer existed. It
    /// passed the version check and then failed to link.
    ///
    /// Generation 9 adds the Signal capability — `HostServices.signals` and the
    /// `PluginSignalEmitter` protocol — and adds nothing else. No symbol moved,
    /// no module was renamed, so a generation-8 bundle keeps loading. That is
    /// verified against a real signed fixture, not reasoned about: see M2 Task 8.
    ///
    /// One distinction this value does NOT cover, and which cost real work to
    /// discover: `HostServices` gaining a requirement is a **source** break for
    /// anything that conforms to it. Nothing outside the host does so in
    /// production, but Raven, Rune and GitMage each fake a conformance in their
    /// test support, and those had to be updated. A compiled bundle keeps
    /// loading; a plugin's test suite does not keep compiling. Both are true,
    /// and only the first is what this promises.
    /// **Two releases as of generation 10, not one.** This was `apiVersion - 1`
    /// from generation 9, and the bump to 10 would have moved the floor to 9 —
    /// at which point every plugin bundle actually installed in the field
    /// stopped loading, because all of them were still built against
    /// generation 8. A host that launches with none of the user's apps is not
    /// a deprecation window working; it is the outage the window exists to
    /// prevent.
    ///
    /// The change is in the SAFE direction: supporting more generations, not
    /// fewer. Nothing that loaded before stops loading, and the promise made
    /// to plugin authors gets longer rather than shorter.
    ///
    /// It is stated as `- 2` rather than a literal `8` so it keeps tracking
    /// `apiVersion` — a hard-coded floor is how generation 8 ended up equal to
    /// `apiVersion` and de-registered everything.
    ///
    /// The cost is a wider compatibility surface: generation 10 must keep
    /// working for a generation-8 bundle, so every addition in 9 AND 10 has to
    /// stay genuinely optional. That is already true of all of them —
    /// `HostServices.signals` is consumed and never implemented by plugins,
    /// `PluginSignalObserver` is discovered by cast, the manifest key is read
    /// outside the frozen parse, and the pane locator rides the SwiftUI
    /// environment.
    public static let minSupportedAPIVersion = apiVersion - 2

    /// A bundle built against `bundleAPIVersion` is loadable exactly when it
    /// falls within the host's inclusive supported range.
    public static func isCompatible(bundleAPIVersion: Int, minSupported: Int, current: Int) -> Bool {
        bundleAPIVersion >= minSupported && bundleAPIVersion <= current
    }
}
