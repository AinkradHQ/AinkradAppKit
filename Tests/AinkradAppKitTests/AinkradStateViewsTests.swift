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
}
