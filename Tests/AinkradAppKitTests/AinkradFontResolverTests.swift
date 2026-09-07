import Testing
import SwiftUI
@testable import AinkradAppKitUI

@Suite("Size-based font resolution")
struct AinkradFontResolverSizeTests {
    @Test("an explicit size is scaled by typography, not rounded to a role")
    func explicitSizeScales() {
        let typo = AinkradTypography(fontFamilyName: nil, scale: 2)
        #expect(AinkradFontResolver.pointSize(12.5, typography: typo) == 25)
        #expect(AinkradFontResolver.pointSize(9.5, typography: typo) == 19)
    }

    @Test("role-based resolution is unchanged")
    func rolesUnchanged() {
        let typo = AinkradTypography.default
        #expect(AinkradFontResolver.pointSize(.caption, typography: typo) == 11)
        #expect(AinkradFontResolver.pointSize(.body, typography: typo) == 14)
    }

    @Test("a tuned size survives, where the nearest role would have re-scaled it")
    func tunedSizesAreNotRounded() {
        let typo = AinkradTypography.default
        // The Signal feed's sizes sit between the role steps (.caption 11,
        // .mono 13, .body 14). Rounding each to a role would redesign the feed.
        for size in [12.5, 11.5, 10.0, 9.5] as [CGFloat] {
            #expect(AinkradFontResolver.pointSize(size, typography: typo) == size)
        }
    }
}
