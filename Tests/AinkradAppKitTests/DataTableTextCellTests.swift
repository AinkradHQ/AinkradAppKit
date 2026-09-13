import Foundation
import Testing
import AppKit
import SwiftUI
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradDataTable text cells")
@MainActor
struct DataTableTextCellTests {
    private struct Row: Identifiable { let id: Int; let name: String }

    private func rowHeight(_ name: String) -> CGFloat {
        _ = NSApplication.shared
        let column = AinkradTableColumn<Row>(id: "name", title: "Name") { $0.name }
        let table = AinkradDataTable(rows: [Row(id: 0, name: name)], columns: [column]).frame(width: 240)
        return NSHostingView(rootView: table).fittingSize.height
    }

    @Test("a long value holds one line, so its row is as tall as a short one")
    func longTextHoldsOneLine() {
        let short = rowHeight("alpine:3.20")
        let long = rowHeight(String(repeating: "local-worker-delivery-", count: 6) + "latest")
        #expect(long == short, "long value \(long) pt tall vs short \(short) pt")
    }
}
