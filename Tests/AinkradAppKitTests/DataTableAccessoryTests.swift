import Foundation
import Testing
import AppKit
import SwiftUI
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

private final class BuildCounter: @unchecked Sendable { var count = 0 }

@Suite("AinkradDataTable accessory column")
@MainActor
struct DataTableAccessoryTests {
    private struct Row: Identifiable { let id: Int; let name: String }
    private let rows = [Row(id: 0, name: "b"), Row(id: 1, name: "a"), Row(id: 2, name: "c")]

    @Test("the text initializer still makes a plain text column")
    func textColumnUnchanged() {
        let column = AinkradTableColumn<Row>(id: "name", title: "Name") { $0.name }
        #expect(column.accessory == nil)
        #expect(column.cell(rows[0]) == "b")
    }

    @Test("an accessory column has no sort value, so sorting by it keeps the order")
    func accessoryDoesNotSort() {
        let columns: [AinkradTableColumn<Row>] = [
            AinkradTableColumn(id: "name", title: "Name") { $0.name },
            .accessory(id: "actions") { _ in Text("run") },
        ]
        #expect(sortedRows(rows, by: columns, column: "actions", ascending: true).map(\.id) == [0, 1, 2])
        #expect(sortedRows(rows, by: columns, column: "actions", ascending: false).map(\.id) == [0, 1, 2])
        #expect(sortedRows(rows, by: columns, column: "name", ascending: true).map(\.id) == [1, 0, 2])
    }

    @Test("the table builds the accessory view for each row")
    func buildsAccessoryViews() {
        _ = NSApplication.shared
        let counter = BuildCounter()
        let columns: [AinkradTableColumn<Row>] = [
            AinkradTableColumn(id: "name", title: "Name") { $0.name },
            .accessory(id: "actions") { row in
                counter.count += 1
                return Button("Run \(row.name)") {}
            },
        ]
        let host = NSHostingView(rootView: AinkradDataTable(rows: rows, columns: columns).frame(width: 400, height: 300))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        #expect(counter.count >= rows.count, "accessory built \(counter.count) times for \(rows.count) rows")
    }
}
