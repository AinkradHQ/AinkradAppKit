import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Parity batch 2: every Forge/Grimoire mockup style is opt-in, off by default.
@Suite("Kit parity batch 2")
@MainActor
struct KitParityBatch2Tests {
    @Test("an outlined keycap is opt-in")
    func kbdOutlined() {
        #expect(!AinkradKbd("⌘K").isOutlined)
        #expect(AinkradKbd("⌘K").outlined().isOutlined)
    }

    @Test("a breadcrumb keeps its case and takes one segment icon only when asked")
    func breadcrumbOptions() {
        let plain = AinkradBreadcrumb(items: ["Sources", "SidebarRow.swift"])
        #expect(!plain.keepsCase)
        #expect(plain.segmentIcon == nil)
        let forge = plain.preservesCase().icon(at: 1) { Image(systemName: "swift") }
        #expect(forge.keepsCase)
        #expect(forge.segmentIcon?.index == 1)
    }

    @Test("matched letters split a label into runs")
    func matchRuns() {
        let runs = ainkradMatchRuns("SidebarRow", matched: [0, 4, 7, 8, 9, 40])
        #expect(runs.map(\.text) == ["S", "ide", "b", "ar", "Row"])
        #expect(runs.map(\.isMatch) == [true, false, true, false, true])
        #expect(ainkradMatchRuns("abc", matched: []).map(\.text) == ["abc"])
        #expect(ainkradMatchRuns("", matched: [0]).isEmpty)
    }

    @Test("command menu palette rows, matches and sections are opt-in")
    func commandMenuOptions() {
        let items = ["a.swift", "b.swift", "c.swift"]
        let plain = AinkradCommandMenu(items: items, selection: .constant(nil), icon: { _ in "" }, label: { $0 })
        #expect(!plain.usesPaletteRows)
        #expect(plain.matchedCharacters == nil)
        #expect(plain.sectionStart(at: 0) == nil)
        let palette =
            plain.paletteRows()
            .matchedCharacters { _ in [0] }
            .sections { $0 == "a.swift" ? "Recently opened" : "Files" }
        #expect(palette.usesPaletteRows)
        #expect(palette.matchedCharacters?("a.swift") == [0])
        #expect(palette.sectionStart(at: 0) == "Recently opened")
        #expect(palette.sectionStart(at: 1) == "Files")
        #expect(palette.sectionStart(at: 2) == nil)
    }

    static func composer() -> AinkradComposer<EmptyView, EmptyView, EmptyView> {
        AinkradComposer(
            text: .constant(""), placeholder: "Ask", isEditable: true, canSend: true, autoFocus: false,
            suggestions: { _ in [] }, onPick: { _, _ in }, onDrop: nil, onSend: {},
            chips: { EmptyView() }, leading: { EmptyView() }, trailing: { EmptyView() })
    }

    @Test("composer palette suggestion rows are opt-in")
    func composerPaletteRows() {
        #expect(!Self.composer().usesPaletteSuggestionRows)
        #expect(Self.composer().paletteSuggestionRows().usesPaletteSuggestionRows)
    }

    @Test("a labelled Send is opt-in")
    func composerSendTitle() {
        #expect(Self.composer().sendTitle == nil)
        #expect(Self.composer().sendTitle("Ask ⌘↵").sendTitle == "Ask ⌘↵")
    }

    @Test("a leading field label is opt-in")
    func textFieldLabel() {
        #expect(AinkradTextField(text: .constant(""), placeholder: "").label == nil)
        #expect(AinkradTextField(text: .constant(""), placeholder: "").leadingLabel("include").label == "include")
    }

    @Test("a search field key hint is opt-in")
    func searchKeyHint() {
        #expect(AinkradSearchField(text: .constant(""), placeholder: "").keyHint == nil)
        #expect(AinkradSearchField(text: .constant(""), placeholder: "").keyHint("⌘K").keyHint == "⌘K")
    }
}
