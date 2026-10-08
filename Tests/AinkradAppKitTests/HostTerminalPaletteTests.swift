import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@MainActor
@Suite("HostTerminalPalette (generation 12)")
struct HostTerminalPaletteTests {
    private func theme() -> HostTheme {
        HostTheme(
            .init(
                themeID: "t", background: .black, surface: .black, surfaceElevated: .black,
                accentPrimary: .white, accentSecondary: .white, accentTertiary: .white, foreground: .white))
    }

    @Test("the adapter formats standard.terminal's hex tokens as RRGGBB")
    func adapterFormatsStandard() {
        let palette = HostTerminalPalette(AinkradSkin.standard.terminal)
        #expect(palette.background == "0A0E17")
        #expect(palette.foreground == "E2E8F0")
        #expect(palette.cursor == "22D3EE")
        #expect(palette.selection == "3B4252")
        #expect(
            palette.ansi == [
                "1A1D24", "E06C75", "98C379", "E5C07B", "61AFEF", "C678DD", "56B6C2", "ABB2BF",
                "5C6370", "E06C75", "98C379", "E5C07B", "61AFEF", "C678DD", "56B6C2", "FFFFFF",
            ])
    }

    @Test("a non-hex token has no fixed colour and maps to an empty string")
    func nonHexIsEmpty() {
        var terminal = AinkradSkin.standard.terminal
        terminal.cursor = .palette("accent", 1)
        terminal.selection = .clear
        let palette = HostTerminalPalette(terminal)
        #expect(palette.cursor.isEmpty)
        #expect(palette.selection.isEmpty)
        #expect(palette.background == "0A0E17")
    }

    @Test("HostTheme starts with no palette and publishes the host's one")
    func hostThemeStoresPalette() {
        let theme = theme()
        #expect(theme.terminalPalette == nil, "nil = the host published none")
        let palette = HostTerminalPalette(AinkradSkin.standard.terminal)
        theme.updateTerminalPalette(palette)
        #expect(theme.terminalPalette == palette)
    }

    @Test("a token update leaves the published palette alone")
    func tokenUpdateKeepsPalette() {
        let theme = theme()
        let palette = HostTerminalPalette(AinkradSkin.standard.terminal)
        theme.updateTerminalPalette(palette)
        theme.update(theme.tokens)
        #expect(theme.terminalPalette == palette)
    }
}
