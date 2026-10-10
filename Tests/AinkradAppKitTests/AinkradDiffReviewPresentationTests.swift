import Foundation
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
}
