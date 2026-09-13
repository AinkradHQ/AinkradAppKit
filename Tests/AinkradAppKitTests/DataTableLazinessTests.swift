@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI
import Foundation
import Testing
import AppKit
import SwiftUI

/// Counts how many cells a table asks for. A lazy table inside a scroll view
/// asks only for the rows on screen; an eager one asks for every row.
private final class CellCounter: @unchecked Sendable {
    var count = 0
}

@Suite("AinkradDataTable laziness")
@MainActor
struct DataTableLazinessTests {
    private struct Row: Identifiable { let id: Int }

    @Test("a long table in a scroll view builds only the rows on screen")
    func buildsOnlyVisibleRows() {
        _ = NSApplication.shared
        let counter = CellCounter()
        let rows = (0..<1_000).map(Row.init)
        let column = AinkradTableColumn<Row>(id: "n", title: "N") { row in
            counter.count += 1
            return "\(row.id)"
        }
        let view = ScrollView { AinkradDataTable(rows: rows, columns: [column]) }
            .frame(width: 400, height: 300)
        let host = NSHostingView(rootView: view)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
                              styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        // 300 pt shows roughly a dozen rows. Allow generous headroom for
        // SwiftUI's prefetch; an eager table would ask for all 1,000.
        #expect(counter.count > 0)
        #expect(counter.count < 200, "built \(counter.count) of 1,000 rows")
    }
}
