// The umbrella module.
//
// `AinkradAppKit` is split into two targets that ship as ONE dynamic library:
//
//   • `AinkradAppKitContract` — the ABI-frozen plugin contract. `AinkradApp`,
//     `AinkradPluginEntryPoint`, `HostServices`, `HostThemeTokens`,
//     `PluginBundleMetadata`, `PluginValidation`, `StorePolicy`, `apiVersion`.
//     Small, slow-moving, and the only thing whose ABI actually matters: a
//     change here can stop an already-installed plugin from loading.
//
//   • `AinkradAppKitUI` — the Cardinal HUD component kit. ~40 files, most of
//     the package's 6k lines, and under continuous design iteration.
//
// They were one target purely for convenience, and the cost was paid every
// time: because the ABI digester saw a single module, *every* component tweak
// registered as an ABI event, and the committed baseline was ~90% component
// churn. Real contract changes had nowhere to stand out. Splitting them means
// `make abi-check` can hold the contract to a strict standard while the UI kit
// stays free to move.
//
// This file re-exports both, so `import AinkradAppKit` continues to mean
// exactly what it did — every plugin and the host compile unchanged.
@_exported import AinkradAppKitContract
@_exported import AinkradAppKitUI
@_exported import AinkradAppKitHome
// AinkradSignal ships inside the same dynamic image. It is a dependency of
// this umbrella rather than a standalone target for a concrete reason: a
// target that belongs to no product and is nobody's dependency is invisible
// to consumers of the package, so the host could not have imported it at all.
@_exported import AinkradSignal
