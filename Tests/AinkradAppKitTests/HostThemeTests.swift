import Observation
import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@MainActor
struct HostThemeTests {
    private func tokens(_ id: String, _ bg: Color = .black) -> HostThemeTokens {
        HostThemeTokens(
            themeID: id, background: bg, surface: bg, surfaceElevated: bg,
            accentPrimary: bg, accentSecondary: bg, accentTertiary: bg, foreground: bg)
    }

    @Test("update publishes an observation change and swaps tokens")
    func updatePublishes() {
        let theme = HostTheme(tokens("neonBlue"))
        class Fired: @unchecked Sendable { var value = false }
        let fired = Fired()
        withObservationTracking {
            _ = theme.tokens
        } onChange: {
            fired.value = true
        }
        theme.update(tokens("dracula"))
        #expect(fired.value)
        #expect(theme.tokens.themeID == "dracula")
    }

    @Test("themeID participates in equality")
    func themeIDEquatable() {
        #expect(tokens("a") != tokens("b"))
        #expect(tokens("a") == tokens("a"))
    }
}
