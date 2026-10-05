import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// Epic 4.3a: the targeting-bracket shape is public. For rects at least
/// `2 * length` wide the path equals the host `TargetingBrackets` copy
/// (proven in Scratch against the verbatim original, then deleted); a smaller
/// rect clamps, as the kit does today.
@Suite("AinkradCornerBrackets")
struct CornerBracketsTests {
    @Test("default arm length is 8")
    func defaultLength() {
        #expect(AinkradCornerBrackets().length == 8)
    }

    @Test("path geometry is pinned at Gallery lengths")
    func pinnedPaths() {
        let rect = CGRect(x: 0, y: 0, width: 120, height: 80)
        #expect(
            AinkradCornerBrackets(length: 7).path(in: rect).description
                == "0 7 m 0 0 l 7 0 l 113 0 m 120 0 l 120 7 l 120 73 m 120 80 l 113 80 l 7 80 m 0 80 l 0 73 l")
        #expect(
            AinkradCornerBrackets(length: 9).path(in: rect).description
                == "0 9 m 0 0 l 9 0 l 111 0 m 120 0 l 120 9 l 120 71 m 120 80 l 111 80 l 9 80 m 0 80 l 0 71 l")
        #expect(
            AinkradCornerBrackets(length: 13).path(in: rect).description
                == "0 13 m 0 0 l 13 0 l 107 0 m 120 0 l 120 13 l 120 67 m 120 80 l 107 80 l 13 80 m 0 80 l 0 67 l")
    }

    @Test("a rect narrower than 2 * length clamps the arms")
    func smallRectClamps() {
        let tiny = CGRect(x: 0, y: 0, width: 10, height: 10)
        #expect(
            AinkradCornerBrackets(length: 13).path(in: tiny).description
                == AinkradCornerBrackets(length: 5).path(in: tiny).description)
    }
}
