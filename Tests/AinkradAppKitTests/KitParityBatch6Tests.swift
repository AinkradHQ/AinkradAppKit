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
}
