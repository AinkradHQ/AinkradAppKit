import Foundation
import SwiftUI
// design-lint: allow-file hex-color,raw-color,radius-literal,font-size,padding-literal,spacing-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — skin colour group tests
import Testing

@testable import AinkradAppKitUI

@Suite("SkinColourGroupTests")
@MainActor
struct SkinColourGroupTests {
    @Test("text group tokens")
    func textGroup() {
        let text = AinkradSkin.standard.text
        #expect(text.primary == .palette("foreground", 1.0))
        #expect(text.muted == .palette("foreground", 0.55))
        #expect(text.faint == .palette("foreground", 0.45))
    }

    @Test("syntax group tokens and Lore keyword math (hued 285)")
    func syntaxGroup() {
        let syntax = AinkradSkin.standard.syntax
        #expect(syntax.comment == .palette("foreground", 0.45))
        #expect(syntax.stringHue == 140)
        #expect(syntax.numberHue == 30)
        #expect(syntax.keywordHue == 285)
        #expect(syntax.typeHue == 200)

        let kwTokenOnDark = syntax.color(.keyword, onDark: true)
        if case .hex(let r, let g, let b, let a) = kwTokenOnDark {
            #expect(a == 1.0)
            // H: 285/360 = 0.791666..., S: 0.50, B: 0.95
            // Expected RGB math:
            // angle = 0.791666... * 6 = 4.75 -> i = 4, f = 0.75
            // p = 0.95 * 0.5 = 0.475
            // q = 0.95 * (1 - 0.5 * 0.75) = 0.59375
            // t = 0.95 * (1 - 0.5 * 0.25) = 0.83125
            // RGB = (t, p, b) = (0.83125, 0.475, 0.95)
            #expect(abs(r - 0.83125) < 0.001)
            #expect(abs(g - 0.475) < 0.001)
            #expect(abs(b - 0.95) < 0.001)
        } else {
            Issue.record("keyword color on dark should resolve to .hex")
        }
    }

    @Test("terminal group tokens (neonBlue row)")
    func terminalGroup() {
        let term = AinkradSkin.standard.terminal
        let bgHex = AinkradColorToken.hex(0x0A / 255.0, 0x0E / 255.0, 0x17 / 255.0, 1.0)
        let fgHex = AinkradColorToken.hex(0xE2 / 255.0, 0xE8 / 255.0, 0xF0 / 255.0, 1.0)
        let curHex = AinkradColorToken.hex(0x22 / 255.0, 0xD3 / 255.0, 0xEE / 255.0, 1.0)
        let selHex = AinkradColorToken.hex(0x3B / 255.0, 0x42 / 255.0, 0x52 / 255.0, 1.0)
        let ansi0Hex = AinkradColorToken.hex(0x1A / 255.0, 0x1D / 255.0, 0x24 / 255.0, 1.0)
        let ansi15Hex = AinkradColorToken.hex(1.0, 1.0, 1.0, 1.0)

        #expect(term.background == bgHex)
        #expect(term.foreground == fgHex)
        #expect(term.cursor == curHex)
        #expect(term.selection == selHex)
        #expect(term.ansi.count == 16)
        #expect(term.ansi[0] == ansi0Hex)
        #expect(term.ansi[15] == ansi15Hex)
    }

    @Test("skin.font mono system and scaled false behavior")
    func fontResolution() {
        let skin = AinkradSkin.standard
        let monoToken = AinkradFontToken(size: 13, mono: "system")
        let fontResolved = skin.font(monoToken)
        let expectedFont = Font.system(size: 13, weight: .regular, design: .monospaced)
        #expect(fontResolved == expectedFont)

        let unscaledToken = AinkradFontToken(size: 12, scaled: false)
        let customTypography = AinkradTypography(scale: 1.5)
        let unscaledFont = skin.font(unscaledToken, typography: customTypography)
        let expectedUnscaled = Font.system(size: 12, weight: .regular)
        #expect(unscaledFont == expectedUnscaled)
    }
}
