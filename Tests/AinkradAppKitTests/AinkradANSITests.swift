import Foundation
import Testing
import SwiftUI
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

// Ported from Thrall's ThrallANSIParserTests when the parser moved into the kit.
@Suite("AinkradANSIParser")
struct AinkradANSIParserTests {
    private func runs(_ text: String) -> [AinkradStyledRun] {
        var parser = AinkradANSIParser()
        return parser.parse(text)
    }

    @Test("plain text is one run with no colour")
    func plainText() {
        #expect(runs("starting worker") == [AinkradStyledRun(colorSlot: nil, text: "starting worker")])
    }

    /// Slot indices, never colours — the mapping happens through the theme at
    /// render time so a log follows the user's colours.
    @Test("standard and bright foreground codes map to slots", arguments: [
        ("\u{1B}[31mred", 1), ("\u{1B}[32mgreen", 2), ("\u{1B}[33myellow", 3),
        ("\u{1B}[91mbright", 9), ("\u{1B}[97mwhite", 15),
    ])
    func colorSlots(text: String, slot: Int) {
        #expect(runs(text).last?.colorSlot == slot)
    }

    @Test("reset clears colour and weight")
    func reset() {
        let parsed = runs("\u{1B}[1;31mbad\u{1B}[0m fine")
        #expect(parsed.count == 2)
        #expect(parsed[0].colorSlot == 1)
        #expect(parsed[0].isBold)
        #expect(parsed[1].colorSlot == nil)
        #expect(!parsed[1].isBold)
    }

    @Test("a bare ESC[m is a reset")
    func bareReset() {
        #expect(runs("\u{1B}[31mred\u{1B}[mplain").last?.colorSlot == nil)
    }

    /// A colour code split across two reads would otherwise print as literal
    /// text — and with a dechunker above, a boundary lands there constantly.
    @Test("an escape split across chunks is reassembled", arguments: [1, 2, 3, 4, 5])
    func splitEscape(splitAt: Int) {
        let text = "\u{1B}[31mfailed"
        var parser = AinkradANSIParser()
        var collected = parser.parse(String(text.prefix(splitAt)))
        collected += parser.parse(String(text.dropFirst(splitAt)))
        #expect(collected.map(\.text).joined() == "failed")
        #expect(collected.last?.colorSlot == 1)
    }

    /// A log that picks colour 208 is decorating; honouring it would put a
    /// colour outside the theme on screen.
    @Test("256-colour and truecolour fold onto the 16 slots")
    func extendedColors() {
        #expect(runs("\u{1B}[38;5;208mwarn").last?.colorSlot == 208 % 16)
        #expect(runs("\u{1B}[38;2;255;0;0mred").last?.text == "red")
    }

    @Test("background colours are ignored, not printed")
    func backgroundIgnored() {
        let parsed = runs("\u{1B}[41mtext")
        #expect(parsed.map(\.text).joined() == "text")
        #expect(parsed.last?.colorSlot == nil)
    }

    @Test("cursor and erase sequences are dropped, not rendered",
          arguments: ["\u{1B}[2J", "\u{1B}[H", "\u{1B}[1A", "\u{1B}[K"])
    func nonSGRDropped(sequence: String) {
        #expect(runs("before\(sequence)after").map(\.text).joined() == "beforeafter")
    }

    @Test("a stray escape byte is not printed")
    func strayEscape() {
        #expect(runs("a\u{1B}Xb").map(\.text).joined() == "ab")
    }
}

@Suite("AinkradANSIPalette")
@MainActor
struct AinkradANSIPaletteTests {
    private let theme = EnvironmentValues().ainkradTheme
    private let status = AinkradStatusColors.default

    @Test("sixteen slots, one per ANSI colour")
    func sixteenSlots() {
        #expect(AinkradANSIPalette(theme: theme, statusColors: status).colors.count == 16)
    }

    @Test("no slot, or one outside 0–15, falls back to the default colour")
    func fallback() {
        let palette = AinkradANSIPalette(theme: theme, statusColors: status)
        #expect(palette.color(slot: nil, default: .pink) == .pink)
        #expect(palette.color(slot: 16, default: .pink) == .pink)
        #expect(palette.color(slot: -1, default: .pink) == .pink)
    }

    /// An error line in a log is the same red as an error badge beside it.
    @Test("red, yellow and green are the app's own danger, warning and success colours")
    func statusSlots() {
        let palette = AinkradANSIPalette(theme: theme, statusColors: status)
        #expect(palette.color(slot: 1, default: .clear) == AinkradStatus.danger.color(in: theme, statusColors: status))
        #expect(palette.color(slot: 3, default: .clear) == AinkradStatus.warning.color(in: theme, statusColors: status))
        #expect(palette.color(slot: 2, default: .clear) == AinkradStatus.success.color(in: theme, statusColors: status))
        #expect(palette.color(slot: 9, default: .clear) == palette.color(slot: 1, default: .clear))
    }
}
