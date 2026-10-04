import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite struct StorePolicyTests {
    private func metadata(apiVersion: Int = 7) -> PluginBundleMetadata {
        PluginBundleMetadata(
            appID: "ok", displayName: "OK", iconSymbol: "star",
            apiVersion: apiVersion, principalClassName: "P")
    }

    private func validInput(
        apiVersion: Int = 7,
        author: String? = "Jane Doe",
        description: String? = "Does a thing.",
        iconSymbol: String? = "star.fill",
        declaredSHA256: String = "abc123",
        computedSHA256: String = "abc123"
    ) -> StoreManifestInput {
        StoreManifestInput(
            metadata: metadata(apiVersion: apiVersion),
            infoDictionary: ["CFBundleExecutable": "P"],
            author: author,
            description: description,
            iconSymbol: iconSymbol,
            declaredSHA256: declaredSHA256,
            computedSHA256: computedSHA256)
    }

    @Test func missingAuthorFails() {
        let issues = StorePolicy.check(manifest: validInput(author: nil), minSupported: 7, current: 7)
        #expect(issues.contains(where: { $0.code == "missing-author" }))
    }

    @Test func missingAuthorEmptyStringFails() {
        let issues = StorePolicy.check(manifest: validInput(author: ""), minSupported: 7, current: 7)
        #expect(issues.contains(where: { $0.code == "missing-author" }))
    }

    @Test func unresolvableIconSymbolFails() {
        let issues = StorePolicy.check(
            manifest: validInput(iconSymbol: "not-a-real-symbol-xyz"),
            minSupported: 7, current: 7)
        #expect(issues.contains(where: { $0.code == "missing-icon" }))
    }

    @Test func missingIconSymbolFails() {
        let issues = StorePolicy.check(manifest: validInput(iconSymbol: nil), minSupported: 7, current: 7)
        #expect(issues.contains(where: { $0.code == "missing-icon" }))
    }

    @Test func shaMismatchFails() {
        let issues = StorePolicy.check(
            manifest: validInput(declaredSHA256: "abc123", computedSHA256: "def456"),
            minSupported: 7, current: 7)
        #expect(issues.contains(where: { $0.code == "sha-mismatch" }))
    }

    @Test func unsupportedGenerationFailsWithHostWording() {
        let issues = StorePolicy.check(manifest: validInput(apiVersion: 5), minSupported: 7, current: 7)
        let expectedMessage = "built against generation 5; this host supports 7\u{2013}7 — update the app"
        #expect(issues.contains(StoreIssue(code: "unsupported-generation", message: expectedMessage)))
    }

    @Test func missingDescriptionFails() {
        let issues = StorePolicy.check(manifest: validInput(description: nil), minSupported: 7, current: 7)
        #expect(issues.contains(where: { $0.code == "missing-description" }))
    }

    @Test func fullyValidInputPasses() {
        let issues = StorePolicy.check(manifest: validInput(), minSupported: 7, current: 7)
        #expect(issues == [])
    }

    @Test func invalidAppIDFailsWithCorrectCode() {
        let invalidMetadata = PluginBundleMetadata(
            appID: "bad/id", displayName: "OK", iconSymbol: "star",
            apiVersion: 7, principalClassName: "P")
        let input = StoreManifestInput(
            metadata: invalidMetadata,
            infoDictionary: ["CFBundleExecutable": "P"],
            author: "Jane Doe",
            description: "Does a thing.",
            iconSymbol: "star.fill",
            declaredSHA256: "abc123",
            computedSHA256: "abc123")
        let issues = StorePolicy.check(manifest: input, minSupported: 7, current: 7)
        #expect(issues.contains(where: { $0.code == "invalid-app-id" }))
    }

    @Test func missingCFBundleExecutableFailsWithCorrectCode() {
        let input = StoreManifestInput(
            metadata: metadata(),
            infoDictionary: [:],
            author: "Jane Doe",
            description: "Does a thing.",
            iconSymbol: "star.fill",
            declaredSHA256: "abc123",
            computedSHA256: "abc123")
        let issues = StorePolicy.check(manifest: input, minSupported: 7, current: 7)
        #expect(issues.contains(where: { $0.code == "missing-executable" }))
    }
}
