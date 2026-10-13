import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradStateViews")
struct AinkradStateViewsTests {
    @Test("empty state reports whether it has an action")
    func emptyAction() {
        #expect(AinkradEmptyState(icon: "tray", title: "None", message: "x", actionTitle: "Add", action: {}).hasAction)
        #expect(!AinkradEmptyState(icon: "tray", title: "None", message: "x").hasAction)
    }

    @Test("empty state takes an optional secondary action") @MainActor
    func emptySecondaryAction() {
        let plain = AinkradEmptyState(icon: "tray", title: "None", message: "x", actionTitle: "Add", action: {})
        #expect(!plain.hasSecondaryAction)
        var fired = false
        let both = plain.secondaryAction("Open folder…") { fired = true }
        #expect(both.hasSecondaryAction)
        #expect(both.hasAction)
        #expect(both.secondaryTitle == "Open folder…")
        both.secondary?()
        #expect(fired)
        // A secondary alone still renders without a primary.
        #expect(
            AinkradEmptyState(icon: "tray", title: "None", message: "x").secondaryAction("Open") {}.hasSecondaryAction)
    }
}
