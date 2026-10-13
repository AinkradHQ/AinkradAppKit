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

    @Test("a text area's font size is opt-in")
    func textAreaFontSize() {
        let area = AinkradTextArea(text: .constant(""), placeholder: "What should the agent do?")
        #expect(area.fontSize == nil)
        #expect(area.fontSize(12.5).fontSize == 12.5)
    }

    @Test("a field's height and chamfer are opt-in")
    func fieldHeightAndChamfer() {
        let text = AinkradTextField(text: .constant(""), placeholder: "")
        #expect(text.fieldHeight == nil && !text.isChamfered)
        #expect(text.fieldHeight(28).fieldHeight == 28 && text.chamfered().isChamfered)
        let search = AinkradSearchField(text: .constant(""), placeholder: "")
        #expect(search.fieldHeight == nil && !search.isChamfered)
        #expect(search.fieldHeight(28).fieldHeight == 28 && search.chamfered().isChamfered)
    }

    @Test("a compact empty state is opt-in")
    func emptyStateCompact() {
        let state = AinkradEmptyState(icon: "folder", title: "This folder is empty", message: "")
        #expect(!state.isCompact)
        #expect(state.compact().isCompact)
    }
}
