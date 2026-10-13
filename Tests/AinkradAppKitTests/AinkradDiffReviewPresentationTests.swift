import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitUI

@Suite struct AinkradDiffReviewPresentationTests {
    @Test func sideBySidePairsDeletionsWithInsertions() {
        let diff = AinkradDiffEngine.compute(old: "a\nb\nc", new: "a\nB\nc", path: "/f", context: 2)
        let rows = AinkradDiffReviewPresentation.sideBySideRows(diff.hunks[0])
        // context 'a' + changed 'b'/'B' + context 'c'
        let changed = rows.first { $0.left?.text == "b" }
        #expect(changed?.right?.text == "B")
        // context lines mirror on both sides
        #expect(rows.contains { $0.left?.text == "a" && $0.right?.text == "a" })
    }

    @Test func hunkControlTitlesFollowTheStyle() {
        #expect(AinkradDiffReviewPresentation.hunkControlTitle(accepted: true, keepUndo: false) == "Accepted")
        #expect(AinkradDiffReviewPresentation.hunkControlTitle(accepted: false, keepUndo: false) == "Rejected")
        #expect(AinkradDiffReviewPresentation.hunkControlTitle(accepted: true, keepUndo: true) == "✓ Keep")
        #expect(AinkradDiffReviewPresentation.hunkControlTitle(accepted: false, keepUndo: true) == "↶ Undo")
    }

    @Test @MainActor func optInsAreOffByDefaultAndSetByModifiers() {
        let diff = AinkradDiffEngine.compute(old: "a", new: "b", path: "/f", context: 2)
        let plain = AinkradDiffReview(fileDiff: diff, rejectedHunkIDs: .constant([]))
        #expect(plain.showsHeader)
        #expect(plain.callerSideBySide == nil)
        #expect(!plain.keepUndo)

        var split = true
        let custom =
            plain.hidesHeader()
            .sideBySide(Binding(get: { split }, set: { split = $0 }))
            .keepUndoHunkControls()
        #expect(!custom.showsHeader)
        #expect(custom.keepUndo)
        #expect(custom.callerSideBySide?.wrappedValue == true)
        custom.callerSideBySide?.wrappedValue = false
        #expect(!split)
    }
}
