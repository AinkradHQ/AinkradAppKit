import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradMenuItem")
struct AinkradMenuItemTests {
    @Test("a shortcut is optional and absent by default")
    func shortcutDefaultsToNil() {
        #expect(AinkradMenuItem(title: "Copy", action: {}).shortcut == nil)
    }

    @Test("a shortcut is carried through verbatim")
    func shortcutIsVerbatim() {
        // Glyphs, not words: the keycap renders exactly what it is given, so
        // the caller decides "⌘R" rather than the component guessing at it.
        let item = AinkradMenuItem(
            title: "Rename", systemName: "pencil",
            shortcut: "\u{2318}R", action: {})
        #expect(item.shortcut == "\u{2318}R")
        #expect(item.systemName == "pencil")
        #expect(item.isDestructive == false)
    }

    // `shortcut` was inserted BEFORE `isDestructive` in the parameter list.
    // Every existing call site omits it, so it must remain compilable purely
    // positionally as well as by label — this test is that guarantee.
    @Test("the pre-shortcut call shapes still compile")
    func sourceCompatibility() {
        _ = AinkradMenuItem(title: "Open", action: {})
        _ = AinkradMenuItem(title: "Open", systemName: "folder", action: {})
        _ = AinkradMenuItem(
            title: "Delete", systemName: "trash",
            isDestructive: true, action: {})
    }

    @Test("the action runs on demand and not before")
    func actionIsDeferred() {
        final class Box: @unchecked Sendable { var ran = false }
        let box = Box()
        let item = AinkradMenuItem(title: "Run", action: { box.ran = true })
        #expect(box.ran == false)
        item.action()
        #expect(box.ran == true)
    }

    @Test("items are individually identifiable")
    func distinctIdentity() {
        // Two rows with the same title are still two rows — `ForEach` would
        // collapse them if `id` were derived from the title.
        let a = AinkradMenuItem(title: "Open", action: {})
        let b = AinkradMenuItem(title: "Open", action: {})
        #expect(a.id != b.id)
    }
}
