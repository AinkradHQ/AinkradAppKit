import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Parity batch 6: every Forge mockup style is opt-in, off by default.
@Suite("Kit parity batch 6")
@MainActor
struct KitParityBatch6Tests {
    /// The standard skin with the Glass material: Apple's controls on macOS 26+.
    static var glass: AinkradSkin {
        var skin = AinkradSkin.standard
        skin.material.kind = "glass"
        return skin
    }

    static func fittingSize(_ view: some View, skin: AinkradSkin = .standard) -> CGSize {
        NSHostingView(rootView: view.ainkradSkin(skin).environment(\.colorScheme, .dark)).fittingSize
    }

    static var replaceAll: AinkradButton { AinkradButton(title: "Replace All", style: .primary) {}.compact() }

    @Test("a button height is opt-in")
    func buttonHeightOptIn() {
        #expect(Self.replaceAll.height == nil)
        #expect(Self.replaceAll.buttonHeight(30).height == 30)
    }

    @Test("a button height sets the button's height, Neon and Glass")
    func buttonHeight() {
        #expect(Self.fittingSize(Self.replaceAll).height < 26)
        for height: CGFloat in [26, 30] {
            #expect(Self.fittingSize(Self.replaceAll.buttonHeight(height)).height == height)
            let regular = AinkradButton(title: "Restart Server", style: .primary) {}.buttonHeight(height)
            #expect(Self.fittingSize(regular).height == height)
            if #available(macOS 26, *) {
                #expect(Self.fittingSize(Self.replaceAll.buttonHeight(height), skin: Self.glass).height == height)
                #expect(Self.fittingSize(regular, skin: Self.glass).height == height)
            }
        }
        // The width is the compact button's: only the height changes.
        #expect(Self.fittingSize(Self.replaceAll.buttonHeight(30)).width == Self.fittingSize(Self.replaceAll).width)
    }

    static var renameField: AinkradTextField { AinkradTextField(text: .constant("isActive"), placeholder: "") }

    @Test("a monospaced text field and its Return hook are opt-in")
    func textFieldOptIn() {
        #expect(!Self.renameField.isMonospaced && Self.renameField.returnAction == nil)
        #expect(Self.renameField.monospaced().isMonospaced)
        var got: [EventModifiers] = []
        let hooked = Self.renameField.onReturn { got.append($0) }
        hooked.returnAction?([])
        hooked.returnAction?(.shift)
        #expect(got == [[], .shift])
    }

    @Test("a monospaced text field changes its text, not its height")
    func monospacedField() throws {
        func shot(_ field: AinkradTextField) throws -> NSBitmapImageRep {
            try #require(KitParityBatch5RenderTests.render(field.frame(width: 260), width: 300, height: 60))
        }
        let field = Self.renameField.fieldHeight(28)
        #expect(KitParityBatch5RenderTests.differs(try shot(field), try shot(field.monospaced()), rows: 16..<44))
        #expect(Self.fittingSize(field.monospaced()).height == 28)
        if #available(macOS 26, *) {
            #expect(Self.fittingSize(field.monospaced(), skin: Self.glass).height == 28)
        }
    }

    static func drawerButton(_ glyph: String) -> AinkradIconButton {
        AinkradIconButton(systemName: "xmark", tooltip: "Hide") {}.textGlyph(glyph, size: 14)
    }

    @Test("an outline box is opt-in")
    func outlineBoxOptIn() {
        #expect(!Self.drawerButton("✕").isOutlineBox)
        #expect(Self.drawerButton("✕").outlineBox().isOutlineBox)
    }

    @Test("an outline box changes the rim, fill and glyph, not the frame")
    func outlineBox() throws {
        func shot(_ button: AinkradIconButton) throws -> NSBitmapImageRep {
            try #require(KitParityBatch5RenderTests.render(button, width: 62, height: 62))
        }
        let plain = try shot(Self.drawerButton("✕"))
        let outlined = try shot(Self.drawerButton("✕").outlineBox())
        // The rim on the 30 pt frame's top edge (y 16), the fill and glyph inside it.
        #expect(KitParityBatch5RenderTests.differs(plain, outlined, rows: 16..<17))
        #expect(KitParityBatch5RenderTests.differs(plain, outlined, rows: 20..<42))
        // Nothing is drawn outside the frame.
        #expect(!KitParityBatch5RenderTests.differs(plain, outlined, rows: 0..<14))
        #expect(Self.fittingSize(Self.drawerButton("✕").outlineBox()) == CGSize(width: 30, height: 30))
    }

    /// Mockup 19 A's empty Files tab, compact.
    static var folderEmpty: AinkradEmptyState { KitParityBatch5RenderTests.folderEmpty.compact().secondaryAccent() }

    static func height(_ state: AinkradEmptyState, skin: AinkradSkin = .standard) -> CGFloat {
        fittingSize(state.fixedSize(horizontal: false, vertical: true).frame(width: 280), skin: skin).height
    }

    @Test("an empty state's button height and plain primary are opt-in")
    func emptyStateOptIn() {
        let state = Self.folderEmpty
        #expect(state.buttonHeight == nil && !state.usesPlainPrimary)
        #expect(state.buttonHeight(26).buttonHeight == 26 && state.plainPrimary().usesPlainPrimary)
    }

    @Test("an empty state's button height sets its buttons' height")
    func emptyStateButtonHeight() {
        let compactButton = Self.fittingSize(AinkradButton(title: "New Folder", style: .secondary) {}.compact()).height
        #expect(compactButton < 26)
        #expect(Self.height(Self.folderEmpty.buttonHeight(26)) == Self.height(Self.folderEmpty) + 26 - compactButton)
    }

    @Test("a plain primary unfills the call-to-action only")
    func plainPrimary() throws {
        func shot(_ state: AinkradEmptyState) throws -> NSBitmapImageRep {
            try #require(KitParityBatch5RenderTests.render(state.frame(width: 280, height: 260), width: 312, height: 292))
        }
        let filled = try shot(Self.folderEmpty)
        let plain = try shot(Self.folderEmpty.plainPrimary())
        #expect(KitParityBatch5RenderTests.differs(filled, plain, rows: 0..<292))
        // The glyph, title and message above the buttons are untouched.
        #expect(!KitParityBatch5RenderTests.differs(filled, plain, rows: 0..<150))
        #expect(Self.height(Self.folderEmpty.plainPrimary()) == Self.height(Self.folderEmpty))
    }
}
