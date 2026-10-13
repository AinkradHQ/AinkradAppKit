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
}
