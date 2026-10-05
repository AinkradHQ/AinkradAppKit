import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

struct PluginBundleMetadataTests {
    private var validDict: [String: Any] {
        [
            PluginInfoKey.appID: "hello",
            PluginInfoKey.displayName: "Hello",
            PluginInfoKey.iconSymbol: "hand.wave",
            PluginInfoKey.apiVersion: 1,
            PluginInfoKey.principalClass: "HelloPlugin.HelloEntryPoint",
        ]
    }

    @Test("parses a complete Info.plist")
    func parsesValid() {
        let result = PluginBundleMetadata.parse(infoDictionary: validDict)
        #expect(
            result
                == .success(
                    PluginBundleMetadata(
                        appID: "hello", displayName: "Hello", iconSymbol: "hand.wave",
                        apiVersion: 1, principalClassName: "HelloPlugin.HelloEntryPoint")))
    }

    @Test("rejects a missing required key")
    func rejectsMissingKey() {
        var dict = validDict
        dict.removeValue(forKey: PluginInfoKey.appID)
        #expect(PluginBundleMetadata.parse(infoDictionary: dict) == .failure(.missingKey(PluginInfoKey.appID)))
    }

    @Test("rejects a non-integer API version")
    func rejectsBadAPIVersion() {
        var dict = validDict
        dict[PluginInfoKey.apiVersion] = "one"
        #expect(PluginBundleMetadata.parse(infoDictionary: dict) == .failure(.invalidAPIVersion))
    }
}

@Suite("PluginBundleMetadata.presentation")
struct PresentationMetadataTests {
    private func base(_ extra: [String: Any] = [:]) -> [String: Any] {
        var d: [String: Any] = [
            PluginInfoKey.appID: "x",
            PluginInfoKey.displayName: "X",
            PluginInfoKey.iconSymbol: "star",
            PluginInfoKey.apiVersion: 4,
            PluginInfoKey.principalClass: "P",
        ]
        extra.forEach { d[$0] = $1 }
        return d
    }

    @Test("reads AinkradPresentation: overlay")
    func overlay() throws {
        let m = try PluginBundleMetadata.parse(infoDictionary: base([PluginInfoKey.presentation: "overlay"])).get()
        #expect(m.presentation == .overlay)
    }

    @Test("defaults to .pane when the key is absent")
    func defaultsToPaneWhenAbsent() throws {
        #expect(try PluginBundleMetadata.parse(infoDictionary: base()).get().presentation == .pane)
    }

    @Test("falls back to .pane for an unrecognized value")
    func unrecognizedFallsBackToPane() throws {
        let m = try PluginBundleMetadata.parse(infoDictionary: base([PluginInfoKey.presentation: "junk"])).get()
        #expect(m.presentation == .pane)
    }

    // Store-listing completeness keys (sub-project D). These names are a
    // cross-repo contract — the scaffold template, `ainkrad publish`, and the
    // host installer all read the same strings when building a `StoreManifestInput`
    // — so lock them here against an accidental rename.
    @Test("store-listing Info.plist key names are the cross-repo contract")
    func storeListingKeyNames() {
        #expect(PluginInfoKey.author == "AinkradAuthor")
        #expect(PluginInfoKey.description == "description")
    }
}
