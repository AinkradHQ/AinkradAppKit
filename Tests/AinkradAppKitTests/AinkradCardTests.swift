import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradCard")
struct AinkradCardTests {
    @Test("isInteractive reflects presence of onTap")
    func interactive() {
        #expect(AinkradCard(isSelected: false, onTap: {}) {}.isInteractive == true)
        #expect(AinkradCard(isSelected: false, onTap: nil) {}.isInteractive == false)
    }
}
