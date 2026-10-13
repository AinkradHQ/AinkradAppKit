import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Parity batch 2: every Forge/Grimoire mockup style is opt-in, off by default.
@Suite("Kit parity batch 2")
@MainActor
struct KitParityBatch2Tests {
    @Test("an outlined keycap is opt-in")
    func kbdOutlined() {
        #expect(!AinkradKbd("⌘K").isOutlined)
        #expect(AinkradKbd("⌘K").outlined().isOutlined)
    }

    @Test("a breadcrumb keeps its case and takes one segment icon only when asked")
    func breadcrumbOptions() {
        let plain = AinkradBreadcrumb(items: ["Sources", "SidebarRow.swift"])
        #expect(!plain.keepsCase)
        #expect(plain.segmentIcon == nil)
        let forge = plain.preservesCase().icon(at: 1) { Image(systemName: "swift") }
        #expect(forge.keepsCase)
        #expect(forge.segmentIcon?.index == 1)
    }
}
