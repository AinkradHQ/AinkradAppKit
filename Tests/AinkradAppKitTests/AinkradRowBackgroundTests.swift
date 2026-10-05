import Testing

@testable import AinkradAppKitUI

@Suite("AinkradRowBackground")
struct AinkradRowBackgroundTests {
    @Test("selected beats hovered; hover shows only when not selected")
    func rowState() {
        #expect(ainkradRowState(isSelected: false, isHovered: false) == .rest)
        #expect(ainkradRowState(isSelected: false, isHovered: true) == .hovered)
        #expect(ainkradRowState(isSelected: true, isHovered: false) == .selected)
        #expect(ainkradRowState(isSelected: true, isHovered: true) == .selected)
    }
}
