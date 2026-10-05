import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("SkinStorageTests")
struct SkinStorageTests {
    /// Every view that reads `@Environment(\.ainkradSkin)` stores the value
    /// inline; a large skin made each such view ~9 KB and overflowed the
    /// host's Gallery parity test stack.
    @Test("the skin, and a view reading it, stay pointer-sized")
    func smallValue() {
        #expect(MemoryLayout<AinkradSkin>.size <= 16)
        #expect(MemoryLayout<Environment<AinkradSkin>>.size <= 32)
    }

    @Test("a mutated copy leaves the original untouched")
    func copyOnWrite() {
        let original = AinkradSkin.standard
        var copy = original
        copy.name = "Changed"
        copy.components.card.hoverScale = 2
        #expect(original.name == "Neon Blue")
        #expect(original.components.card.hoverScale == AinkradSkin.standard.components.card.hoverScale)
        #expect(copy.name == "Changed")
        #expect(copy != original)
    }
}
