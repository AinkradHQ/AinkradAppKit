import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradCheckbox toggle")
struct AinkradCheckboxTests {
    @Test("toggling flips the boolean")
    func flips() {
        #expect(checkboxToggled(false) == true)
        #expect(checkboxToggled(true) == false)
    }
}

@Suite("AinkradRadioGroup selection")
struct AinkradRadioGroupTests {
    @Test("radioOptionRows flags only the selected option")
    func flagsSelected() {
        let rows = radioOptionRows(options: ["a", "b", "c"], selected: "c")
        #expect(rows.map(\.isSelected) == [false, false, true])
    }

    @Test("selecting a new option updates via a testable reducer")
    func selectingUpdates() {
        var selection = "a"
        func select(_ option: String) { selection = option }
        select("b")
        let rows: [(option: String, isSelected: Bool)] = radioOptionRows(options: ["a", "b", "c"], selected: selection)
        #expect(rows.map(\.isSelected) == [false, true, false])
    }
}
