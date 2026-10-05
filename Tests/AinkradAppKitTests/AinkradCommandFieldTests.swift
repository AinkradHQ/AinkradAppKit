import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradCommandField")
struct AinkradCommandFieldTests {
    @Test("the four arrow keys map to their arrow, any other key to nil")
    func keyRouting() {
        #expect(ainkradArrow(for: .upArrow) == .up)
        #expect(ainkradArrow(for: .downArrow) == .down)
        #expect(ainkradArrow(for: .leftArrow) == .left)
        #expect(ainkradArrow(for: .rightArrow) == .right)
        #expect(ainkradArrow(for: .return) == nil)
        #expect(ainkradArrow(for: .escape) == nil)
        #expect(ainkradArrow(for: "a") == nil)
        #expect(ainkradArrowKeys.count == 4)
    }

    @Test("standard tokens equal the Launcher's literals")
    func standardTokens() {
        let tokens = AinkradSkin.standard.components.commandField
        #expect(tokens.height == 56)
        #expect(tokens.horizontalPadding == 18)
        #expect(tokens.gap == 12)
        #expect(tokens.font == AinkradFontToken(size: 17, weight: "regular"))
        #expect(tokens.markWidth == 16)
        #expect(tokens.markHeight == 14)
        #expect(tokens.markGlow.radius.resolve([]) == 6)
        #expect(tokens.markGlow.color.resolve([]) == .palette("accentSecondary", 0.9))
    }

    @Test("both inits construct and the field is one token-height tall")
    @MainActor
    func constructsAtTokenHeight() {
        struct Host: View {
            @State var text = ""
            @FocusState var focused: Bool
            var custom: Bool
            var body: some View {
                if custom {
                    AinkradCommandField(
                        "Go", text: $text, focus: $focused, leading: { Color.red.frame(width: 4, height: 4) },
                        onArrow: { _ in false }, onSubmit: {}, onEscape: {})
                } else {
                    AinkradCommandField(
                        "Go", text: $text, focus: $focused, onArrow: { _ in true }, onSubmit: {}, onEscape: {})
                }
            }
        }
        let height = CGFloat(AinkradSkin.standard.components.commandField.height)
        for custom in [false, true] {
            let host = NSHostingView(rootView: Host(custom: custom).frame(width: 400))
            #expect(host.fittingSize.height == height)
        }
    }
}
