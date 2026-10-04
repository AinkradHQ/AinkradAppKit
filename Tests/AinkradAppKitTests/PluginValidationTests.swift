import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite struct PluginValidationTests {
    private func meta(_ api: Int) -> PluginBundleMetadata {
        PluginBundleMetadata(
            appID: "ok", displayName: "OK", iconSymbol: "star",
            apiVersion: api, principalClassName: "P")
    }
    @Test func rejectsMissingExecutable() {
        let r = PluginValidation.validate(metadata: meta(7), infoDictionary: [:], minSupported: 7, current: 7)
        #expect((try? r.get()) == nil)
    }
    @Test func acceptsValid() {
        let r = PluginValidation.validate(
            metadata: meta(7),
            infoDictionary: ["CFBundleExecutable": "P"], minSupported: 7, current: 7)
        #expect((try? r.get()) != nil)
    }
}
