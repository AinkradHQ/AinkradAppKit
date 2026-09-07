// swift-tools-version: 6.0
import PackageDescription

// Resilient ABI on every target: additive public changes no longer break
// already-compiled plugin bundles that reuse the host's embedded copy. See the
// SDK Generation Contract design. Revision-pinned/branch dependents (host +
// plugins) are unaffected by the unsafeFlags version-pin restriction.
let resilient: [SwiftSetting] = [
    .unsafeFlags([
        "-enable-library-evolution",
        "-emit-module-interface",
    ])
]

let package = Package(
    name: "AinkradAppKit",
    platforms: [.macOS(.v14)],
    products: [
        // DYNAMIC: host embeds one copy; plugins resolve it at runtime. A static
        // product would duplicate protocol type metadata and break dynamic casts.
        //
        // Still ONE product and one image, even though there are now three
        // targets — the split is about ABI accounting, not about shipping more
        // binaries. Plugins link exactly what they linked before.
        .library(name: "AinkradAppKit", type: .dynamic, targets: ["AinkradAppKit"]),
    ],
    targets: [
        // The Signal event envelope, routing and store. Pure Swift: no
        // SwiftUI, no AppKit, no host imports — so routing and retention are
        // testable headless. Deliberately NOT inside AinkradAppKitContract:
        // the host consumes it in M1, a full milestone before any plugin-facing
        // API exists, and the contract must not grow a dependency it does not
        // yet use.
        .target(name: "AinkradSignal", swiftSettings: resilient),

        // The ABI-frozen plugin contract. Held to a strict standard by
        // `make abi-check`; see Sources/AinkradAppKit/AinkradAppKit.swift.
        .target(name: "AinkradAppKitContract",
                dependencies: ["AinkradSignal"],
                swiftSettings: resilient),

        // The Cardinal HUD component kit. Depends on the contract (for
        // `HostThemeTokens`); the contract must never depend on this.
        .target(
            name: "AinkradAppKitUI",
            dependencies: ["AinkradAppKitContract"],
            swiftSettings: resilient
        ),

        // Storage-root contract: the single place any app in the family may
        // compute a path. Deliberately NOT in AinkradAppKitContract — it is not
        // part of the ABI-frozen plugin surface.
        .target(name: "AinkradAppKitHome", swiftSettings: resilient),

        // Umbrella: re-exports both, so `import AinkradAppKit` is unchanged for
        // the host and all five plugins.
        .target(
            name: "AinkradAppKit",
            dependencies: ["AinkradAppKitContract", "AinkradAppKitUI", "AinkradAppKitHome",
                           "AinkradSignal"],
            swiftSettings: resilient
        ),

        .testTarget(
            name: "AinkradAppKitTests",
            // Depends on the sub-targets directly: `@testable` reaches internal
            // symbols per MODULE, and after the split those live in
            // Contract/UI rather than in the umbrella.
            dependencies: ["AinkradAppKit", "AinkradAppKitContract", "AinkradAppKitUI", "AinkradAppKitHome",
                           "AinkradSignal"]
        ),
    ]
)
