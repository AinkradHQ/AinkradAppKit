import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Parity batch 5: every Forge mockup style is opt-in, off by default.
@Suite("Kit parity batch 5")
@MainActor
struct KitParityBatch5Tests {
    static func review() -> AinkradDiffReview {
        AinkradDiffReview(fileDiff: KitParityBatch3RenderTests.replacePreview, rejectedHunkIDs: .constant([]))
    }

    @Test("an untickable bare hunk is opt-in")
    func bareHunksUntickable() {
        #expect(!Self.review().bareHunks().bareHunksUntickable)
        let untickable = Self.review().bareHunks(untickable: true)
        #expect(untickable.usesBareHunks && untickable.bareHunksUntickable)
        #expect(!Self.review().bareHunks(untickable: false).bareHunksUntickable)
    }
}
