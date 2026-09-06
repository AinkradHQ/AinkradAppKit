import Testing
@testable import AinkradAppKitContract

@Suite("AinkradLog")
struct AinkradLogTests {
    @Test func subsystemIsTheAppBundleIdentifier() {
        #expect(AinkradLog.subsystem == "com.ainkrad.app")
    }

    @Test func categoryJoinsAppAndAreaWithADot() {
        #expect(AinkradLog.category(app: "raven", area: "imap") == "raven.imap")
    }

    @Test func categoryLowercasesSoConsoleFiltersAreStable() {
        #expect(AinkradLog.category(app: "GitMage", area: "Diff") == "gitmage.diff")
    }

    @Test func loggerIsConstructibleForAnyCategory() {
        // Smoke: os.Logger has no readable category, so this asserts only that
        // construction does not trap for a category containing a dot.
        _ = AinkradLog.logger("lore.editor")
    }
}
