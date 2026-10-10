import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// Glass Native E1.5: menu shortcut glyphs become native key equivalents.
@Suite("NativeMenuShortcutTests")
struct NativeMenuShortcutTests {
    @Test("modifiers and a letter")
    func letters() throws {
        let shortcut = try #require(ainkradKeyboardShortcut("⇧⌘K"))
        #expect(shortcut.key == KeyEquivalent("k"))
        #expect(shortcut.modifiers == [.command, .shift])
    }

    @Test("named keys")
    func named() throws {
        #expect(try #require(ainkradKeyboardShortcut("⌥↩")).key == .return)
        #expect(try #require(ainkradKeyboardShortcut("⌘⌫")).key == .delete)
        #expect(try #require(ainkradKeyboardShortcut("⎋")).modifiers == [])
    }

    @Test("unreadable strings give no shortcut, not a wrong one")
    func unreadable() {
        #expect(ainkradKeyboardShortcut("Cmd+R") == nil)
        #expect(ainkradKeyboardShortcut("⌘") == nil)
        #expect(ainkradKeyboardShortcut("") == nil)
    }
}
