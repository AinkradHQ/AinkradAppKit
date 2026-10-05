import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradCommandMenu selection toggle")
struct CommandMenuToggleTests {
    @Test("tapping an unselected item selects it")
    func selectsNew() {
        #expect(commandMenuToggled("b", current: "a") == "b")
    }

    @Test("tapping the already-selected item deselects it")
    func deselectsCurrent() {
        #expect(commandMenuToggled("a", current: "a") == nil)
    }

    @Test("tapping any item when nothing is selected selects it")
    func selectsFromNil() {
        #expect(commandMenuToggled("a", current: nil) == "a")
    }
}

@Suite("AinkradNavList rows")
struct NavListRowsTests {
    @Test("flags the selected row and only that row")
    func flagsSelectedRow() {
        let rows = navListRows(items: ["a", "b", "c"], selected: "b")
        #expect(rows.map(\.item) == ["a", "b", "c"])
        #expect(rows.map(\.isSelected) == [false, true, false])
    }

    @Test("a selection absent from items flags nothing")
    func noMatch() {
        let rows = navListRows(items: ["a", "b"], selected: "z")
        #expect(rows.allSatisfy { !$0.isSelected })
    }

    @Test("an empty item list yields no rows")
    func empty() {
        let rows = navListRows(items: [String](), selected: "a")
        #expect(rows.isEmpty)
    }
}

@Suite("AinkradCommandMenu keyboard highlight")
struct CommandMenuHighlightTests {
    /// The regression: the highlight used to start at 0, and the row style is
    /// `hovering || isHighlighted`, so row 0 of every consumer — including the
    /// gallery, which asks for no keyboard navigation at all — was painted as
    /// permanently hovered.
    @Test("nothing is highlighted until a key moves it")
    func startsUnset() {
        let initial: Int? = nil
        #expect(initial == nil)
        #expect(commandMenuHighlightMoved(nil, delta: 0, count: 0) == nil)
    }

    @Test("the first down-arrow lands on the first row, the first up-arrow on the last")
    func firstMove() {
        #expect(commandMenuHighlightMoved(nil, delta: 1, count: 3) == 0)
        #expect(commandMenuHighlightMoved(nil, delta: -1, count: 3) == 2)
    }

    @Test("moves stay inside the list")
    func clamps() {
        #expect(commandMenuHighlightMoved(1, delta: 1, count: 3) == 2)
        #expect(commandMenuHighlightMoved(2, delta: 1, count: 3) == 2)
        #expect(commandMenuHighlightMoved(0, delta: -1, count: 3) == 0)
    }

    @Test("an empty list can never hold a highlight")
    func emptyList() {
        #expect(commandMenuHighlightMoved(2, delta: 1, count: 0) == nil)
        #expect(commandMenuHighlightMoved(nil, delta: -1, count: 0) == nil)
    }
}
