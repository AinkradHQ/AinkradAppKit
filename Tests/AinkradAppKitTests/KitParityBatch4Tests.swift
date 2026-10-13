import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Parity batch 4: every Forge/Grimoire mockup style is opt-in, off by default.
@Suite("Kit parity batch 4")
@MainActor
struct KitParityBatch4Tests {
    @Test("a dimmed composer text field is opt-in")
    func composerTextFieldDimmed() {
        #expect(!KitParityBatch2Tests.composer().dimsTextField)
        #expect(KitParityBatch2Tests.composer().textFieldDimmed(true).dimsTextField)
        #expect(!KitParityBatch2Tests.composer().textFieldDimmed(true).textFieldDimmed(false).dimsTextField)
    }

    @Test("an empty state's glyph size is opt-in")
    func emptyStateGlyphSize() {
        let plain = AinkradEmptyState(icon: "books.vertical", title: "No threads yet", message: "")
        #expect(plain.glyphSize == nil)
        #expect(plain.glyph("❖").glyphSize(40).glyphSize == 40)
        #expect(AinkradEmptyState(icon: "hammer", keyHints: []).glyphSize(34).glyphSize == 34)
    }

    @Test("a lit Send is opt-in")
    func composerSendStaysLit() {
        #expect(!KitParityBatch2Tests.composer().keepsSendLit)
        #expect(KitParityBatch2Tests.composer().sendGlyph("↵").sendStaysLit().keepsSendLit)
    }

    @Test("a tinted outline fill is opt-in")
    func buttonTintedFill() {
        #expect(!AinkradButton(title: "Stop", style: .danger) {}.outlined().hasTintedFill)
        #expect(AinkradButton(title: "Stop", style: .danger) {}.outlined().tintedFill().hasTintedFill)
        #expect(!KitParityBatch2Tests.composer().tintsStop)
        #expect(KitParityBatch2Tests.composer().tintedStopButton().tintsStop)
    }

    @Test("palette row kinds are opt-in")
    func commandMenuKinds() {
        let menu = AinkradCommandMenu(
            items: ["SidebarRow"], selection: .constant(nil), icon: { _ in "" }, label: { $0 })
        #expect(menu.kind == nil)
        let symbols = menu.paletteRows().kinds({ _ in "struct" }, tint: { _ in nil })
        #expect(symbols.kind?("SidebarRow") == "struct")
        #expect(symbols.kindTint?("SidebarRow") == nil)
    }
}
