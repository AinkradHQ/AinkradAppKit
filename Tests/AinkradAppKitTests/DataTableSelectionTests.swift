import Foundation
import Testing
import AppKit
import SwiftUI
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("nextSelection")
struct NextSelectionTests {
    private let order = ["a", "b", "c", "d", "e"]

    @Test("a plain click selects only the clicked row and anchors there")
    func plainClick() {
        let next = nextSelection(current: ["b", "c"], anchor: "b", clicked: "d", in: order, gesture: .plain)
        #expect(next.selection == ["d"])
        #expect(next.anchor == "d")
    }

    @Test("⌘-click toggles one row and moves the anchor to it")
    func toggle() {
        let added = nextSelection(current: ["a"], anchor: "a", clicked: "c", in: order, gesture: .toggle)
        #expect(added.selection == ["a", "c"])
        #expect(added.anchor == "c")
        let removed = nextSelection(current: added.selection, anchor: added.anchor, clicked: "a", in: order, gesture: .toggle)
        #expect(removed.selection == ["c"])
    }

    @Test("⇧-click selects the contiguous range from the anchor, in either direction")
    func extendRange() {
        let down = nextSelection(current: ["b"], anchor: "b", clicked: "d", in: order, gesture: .extend)
        #expect(down.selection == ["b", "c", "d"])
        #expect(down.anchor == "b")
        let up = nextSelection(current: ["d"], anchor: "d", clicked: "b", in: order, gesture: .extend)
        #expect(up.selection == ["b", "c", "d"])
    }

    @Test("⇧-click with no anchor, or an anchor no longer shown, acts as a plain click")
    func extendWithoutAnchor() {
        #expect(nextSelection(current: [], anchor: nil, clicked: "c", in: order, gesture: .extend).selection == ["c"])
        #expect(nextSelection(current: ["z"], anchor: "z", clicked: "c", in: order, gesture: .extend).selection == ["c"])
    }

    @Test("a range follows the order rows are shown in, so it respects a re-sort")
    func rangeFollowsDisplayedOrder() {
        let resorted = ["e", "d", "c", "b", "a"]
        #expect(nextSelection(current: ["e"], anchor: "e", clicked: "c", in: resorted, gesture: .extend).selection == ["e", "d", "c"])
    }
}

@Suite("AinkradDataTable selection")
@MainActor
struct DataTableSelectionViewTests {
    private struct Row: Identifiable { let id: Int; let name: String }

    @Test("a selectable table builds and lays out every row")
    func selectableTableBuilds() {
        _ = NSApplication.shared
        var picked: Set<Int> = [1]
        var built = 0
        let rows = (0..<3).map { Row(id: $0, name: "row \($0)") }
        let column = AinkradTableColumn<Row>(id: "name", title: "Name") { row in built += 1; return row.name }
        let binding = Binding(get: { picked }, set: { picked = $0 })
        let host = NSHostingView(rootView: AinkradDataTable(rows: rows, columns: [column], selection: binding).frame(width: 300, height: 200))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        #expect(built >= rows.count)
        #expect(picked == [1], "laying out must not change the caller's selection")
    }
}
