import Foundation
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

private struct FixtureRow: Identifiable {
    let id: String
    let name: String
    let count: String
}

private func makeFixtureColumns() -> [AinkradTableColumn<FixtureRow>] {
    [
        AinkradTableColumn(id: "name", title: "Name") { $0.name },
        AinkradTableColumn(id: "count", title: "Count") { $0.count },
    ]
}

private func makeFixtureRows() -> [FixtureRow] {
    [
        FixtureRow(id: "1", name: "Charlie", count: "3"),
        FixtureRow(id: "2", name: "Alice", count: "10"),
        FixtureRow(id: "3", name: "Bob", count: "2"),
    ]
}

@Suite("sortedRows")
struct SortedRowsTests {
    @Test("ascending sorts by the named column")
    func ascending() {
        let sorted = sortedRows(makeFixtureRows(), by: makeFixtureColumns(), column: "name", ascending: true)
        #expect(sorted.map(\.name) == ["Alice", "Bob", "Charlie"])
    }

    @Test("descending reverses the order")
    func descending() {
        let sorted = sortedRows(makeFixtureRows(), by: makeFixtureColumns(), column: "name", ascending: false)
        #expect(sorted.map(\.name) == ["Charlie", "Bob", "Alice"])
    }

    @Test("an unknown column id leaves the rows unchanged")
    func unknownColumn() {
        let rows = makeFixtureRows()
        let sorted = sortedRows(rows, by: makeFixtureColumns(), column: "missing", ascending: true)
        #expect(sorted.map(\.id) == rows.map(\.id))
    }

    @Test("sorting is stable for equal cell values")
    func stableForTies() {
        let tiedRows: [FixtureRow] = [
            FixtureRow(id: "a", name: "Same", count: "1"),
            FixtureRow(id: "b", name: "Same", count: "2"),
        ]
        let sorted = sortedRows(tiedRows, by: makeFixtureColumns(), column: "name", ascending: true)
        #expect(sorted.map(\.id) == ["a", "b"])
    }
}

@Suite("nextSort")
struct NextSortTests {
    @Test("no current sort starts ascending on the clicked column")
    func startsAscending() {
        let next = nextSort(current: nil, column: "name")
        #expect(next == AinkradTableSort(columnID: "name", ascending: true))
    }

    @Test("clicking the same column toggles ascending to descending")
    func togglesSameColumn() {
        let current = AinkradTableSort(columnID: "name", ascending: true)
        let next = nextSort(current: current, column: "name")
        #expect(next == AinkradTableSort(columnID: "name", ascending: false))
    }

    @Test("clicking the same column again toggles back to ascending")
    func togglesBack() {
        let current = AinkradTableSort(columnID: "name", ascending: false)
        let next = nextSort(current: current, column: "name")
        #expect(next == AinkradTableSort(columnID: "name", ascending: true))
    }

    @Test("clicking a different column resets to ascending on that column")
    func switchesColumn() {
        let current = AinkradTableSort(columnID: "name", ascending: false)
        let next = nextSort(current: current, column: "count")
        #expect(next == AinkradTableSort(columnID: "count", ascending: true))
    }
}
