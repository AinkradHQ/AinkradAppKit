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

    @Test("diff line metrics are opt-in")
    func diffLineMetrics() {
        #expect(Self.review().lineFontSize == nil && Self.review().lineRowHeight == nil)
        let sized = Self.review().lineMetrics(fontSize: 12.5, rowHeight: 20)
        #expect(sized.lineFontSize == 12.5 && sized.lineRowHeight == 20)
    }
}
