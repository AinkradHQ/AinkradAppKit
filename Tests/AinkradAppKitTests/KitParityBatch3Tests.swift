import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Parity batch 3: every Forge/Grimoire mockup style is opt-in, off by default.
@Suite("Kit parity batch 3")
@MainActor
struct KitParityBatch3Tests {
    @Test("a full-width button is opt-in")
    func buttonFullWidth() {
        #expect(!AinkradButton(title: "Commit") {}.fillsWidth)
        #expect(AinkradButton(title: "Commit") {}.fullWidth().fillsWidth)
    }
}
