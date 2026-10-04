import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("Picker selection")
struct AinkradPickerTests {
    @Test("selectionIndex finds the current item")
    func index() {
        #expect(pickerSelectionIndex(items: ["a", "b", "c"], selection: "b") == 1)
        #expect(pickerSelectionIndex(items: ["a", "b"], selection: "z") == nil)
    }
}

@Suite("Color-dot select support")
struct AinkradSwatchSelectTests {
    @Test("shouldShowSwatch is true only when the swatch resolves to a color")
    func swatchVisibility() {
        let swatch: (String) -> Color? = { $0 == "bug" ? .red : nil }
        #expect(shouldShowSwatch(swatch, for: "bug") == true)
        #expect(shouldShowSwatch(swatch, for: "docs") == false)
    }

    @Test("plain and swatch-carrying select inits both construct (compile smoke)")
    func constructs() {
        // Existing symbols must still exist, byte-unchanged.
        _ = AinkradSelect(items: ["a", "b"], selection: .constant("a"), label: { $0 })
        _ = AinkradMultiSelect(items: ["a", "b"], selection: .constant([]), label: { $0 })
        // NEW color-dot overloads.
        _ = AinkradSelect(
            items: ["a", "b"], selection: .constant("a"), label: { $0 },
            swatch: { $0 == "a" ? .green : nil })
        _ = AinkradMultiSelect(
            items: ["a", "b"], selection: .constant([]), label: { $0 },
            swatch: { _ in .purple })
    }
}

@Suite("AinkradSelect option rows")
struct AinkradSelectRowsTests {
    @Test("flags the selected row and only that row")
    func flagsSelectedRow() {
        let rows = selectOptionRows(items: ["a", "b", "c"], selected: "b")
        #expect(rows.map(\.item) == ["a", "b", "c"])
        #expect(rows.map(\.isSelected) == [false, true, false])
    }

    @Test("selecting a new item updates a testable reducer binding")
    func selectingUpdatesBinding() {
        var selection = "a"
        func select(_ item: String) { selection = item }
        select("c")
        let rows: [(item: String, isSelected: Bool)] = selectOptionRows(items: ["a", "b", "c"], selected: selection)
        #expect(rows.map(\.isSelected) == [false, false, true])
    }

    @Test("no item selected flags nothing")
    func noneSelected() {
        let rows = selectOptionRows(items: ["a", "b"], selected: "z")
        #expect(rows.allSatisfy { !$0.isSelected })
    }
}

@Suite("AinkradMultiSelect toggle")
struct AinkradMultiSelectTests {
    @Test("toggling an absent item adds it")
    func adds() {
        let result = toggledSelection("b", in: ["a"])
        #expect(result == ["a", "b"])
    }

    @Test("toggling a present item removes it")
    func removes() {
        let result = toggledSelection("a", in: ["a", "b"])
        #expect(result == ["b"])
    }

    @Test("toggling into an empty set")
    func togglesIntoEmpty() {
        let result = toggledSelection("a", in: [])
        #expect(result == ["a"])
    }
}

@Suite("Dropdown arrow-key highlight nav")
struct MovedHighlightTests {
    @Test("moves down within bounds")
    func movesDown() {
        #expect(movedHighlight(current: 0, delta: 1, count: 3) == 1)
    }

    @Test("moves up within bounds")
    func movesUp() {
        #expect(movedHighlight(current: 2, delta: -1, count: 3) == 1)
    }

    @Test("clamps at the top of the list")
    func clampsAtTop() {
        #expect(movedHighlight(current: 0, delta: -1, count: 3) == 0)
    }

    @Test("clamps at the bottom of the list")
    func clampsAtBottom() {
        #expect(movedHighlight(current: 2, delta: 1, count: 3) == 2)
    }

    @Test("a single large jump still clamps into range")
    func clampsLargeJump() {
        #expect(movedHighlight(current: 0, delta: 99, count: 5) == 4)
        #expect(movedHighlight(current: 4, delta: -99, count: 5) == 0)
    }

    @Test("an empty (fully filtered-out) list always highlights index 0")
    func emptyListReturnsZero() {
        #expect(movedHighlight(current: 3, delta: 1, count: 0) == 0)
        #expect(movedHighlight(current: 0, delta: -1, count: 0) == 0)
    }
}

@Suite("AinkradCombobox filter")
struct AinkradComboboxTests {
    @Test("empty query returns all items")
    func emptyQueryReturnsAll() {
        let result = comboboxFilter(items: ["Alpha", "Beta"], query: "", label: { $0 })
        #expect(result == ["Alpha", "Beta"])
    }

    @Test("query matches case-insensitively via label, substring anywhere")
    func matchesCaseInsensitiveSubstring() {
        let result = comboboxFilter(items: ["Alpha", "Beta", "Gamma"], query: "ph", label: { $0 })
        #expect(result == ["Alpha"])
    }

    @Test("no matches returns empty")
    func noMatches() {
        let result = comboboxFilter(items: ["Alpha", "Beta"], query: "zzz", label: { $0 })
        #expect(result.isEmpty)
    }
}
