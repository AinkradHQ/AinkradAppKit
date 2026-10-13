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

    @Test("editor hunk headers name the lines")
    func editorHunkTitles() {
        func hunk(_ oldStart: Int, _ oldCount: Int, _ newStart: Int, _ newCount: Int) -> AinkradDiffHunk {
            AinkradDiffHunk(
                id: 0, oldStart: oldStart, oldCount: oldCount, newStart: newStart, newCount: newCount, lines: [])
        }
        #expect(AinkradDiffReviewPresentation.editorHunkTitle(hunk(18, 1, 18, 3)) == "@@ lines 18–20")
        #expect(AinkradDiffReviewPresentation.editorHunkTitle(hunk(7, 1, 7, 1)) == "@@ line 7")
        #expect(AinkradDiffReviewPresentation.editorHunkTitle(hunk(24, 1, 23, 0)) == "@@ line 24 — removed")
        #expect(AinkradDiffReviewPresentation.editorHunkTitle(hunk(30, 3, 29, 0)) == "@@ lines 30–32 — removed")
        // A pure insert at the top (context 0) reports start 0; it is line 1.
        #expect(AinkradDiffReviewPresentation.editorHunkTitle(hunk(0, 0, 0, 2)) == "@@ lines 1–2")
    }

    @Test("diff editor lines and syntax colour are opt-in")
    func diffOptions() {
        let diff = AinkradDiffEngine.compute(old: "a", new: "b", path: "/f", context: 2)
        let plain = AinkradDiffReview(fileDiff: diff, rejectedHunkIDs: .constant([]))
        #expect(!plain.usesEditorLines && !plain.usesSyntaxColours)
        let editor = plain.editorLines().syntaxColoured()
        #expect(editor.usesEditorLines && editor.usesSyntaxColours)
    }

    @Test("the syntax scanner colours keywords, types, calls, strings, numbers and comments")
    func syntaxRuns() {
        func kinds(_ line: String) -> [String: AinkradSyntaxKind] {
            Dictionary(
                ainkradSyntaxRuns(line).map { ($0.text.trimmingCharacters(in: .whitespaces), $0.kind) },
                uniquingKeysWith: { first, _ in first })
        }
        let swift = kinds("    let isActive: Bool = check(\"x\", 13) // done")
        #expect(swift["let"] == .keyword)
        #expect(swift["Bool"] == .type)
        #expect(swift["check"] == .function)
        #expect(swift["\"x\""] == .string)
        #expect(swift["13"] == .number)
        #expect(swift["// done"] == .comment)
        let attrs = kinds("@Environment(\\.skin) #expect(a) # a ruby comment")
        #expect(attrs["@Environment"] == .attribute)
        #expect(attrs["#expect"] == .attribute)
        #expect(attrs["# a ruby comment"] == .comment)
        // Runs always rebuild the line exactly.
        let line = "x = \"unterminated \\\" str"
        #expect(ainkradSyntaxRuns(line).map(\.text).joined() == line)
        #expect(ainkradSyntaxRuns("").isEmpty)
    }

    @Test("markdown reply style is opt-in and colours code by line")
    func markdownReplyStyle() {
        #expect(!AinkradMarkdownText(text: "x").usesReplyStyle)
        #expect(AinkradMarkdownText(text: "x").replyStyle().usesReplyStyle)
        #expect(!AinkradCodeBlock("x").usesReplyStyle)
        let code = "let a = 1\n\nlet b = \"two\""
        #expect(String(ainkradSyntaxAttributed(lines: code, palette: .reply).characters) == code)
    }

    @Test("a label-cased decision caption is opt-in")
    func decisionCaption() {
        let bar = AinkradDecisionBar(
            icon: "terminal", iconTint: .secondary, caption: "Approval required", title: "Run git push", actions: [])
        #expect(!bar.casesCaption)
        #expect(bar.labelCasedCaption().casesCaption)
    }

    @Test("a borderless button is opt-in")
    func buttonBorderless() {
        #expect(!AinkradButton(title: "Cancel", style: .ghost) {}.isBorderless)
        #expect(AinkradButton(title: "Cancel", style: .ghost) {}.borderless().isBorderless)
        #expect(AinkradButton(title: "Cancel", style: .ghost, isLoading: false) {}.borderless().isBorderless)
    }

    @Test("menu groups are opt-in and never gap the first item")
    func menuGroups() {
        let items = [
            AinkradMenuItem(title: "New File…") {}.startingGroup(),
            AinkradMenuItem(title: "Rename") {},
            AinkradMenuItem(title: "Copy Path") {}.startingGroup(),
        ]
        #expect(!AinkradMenuItem(title: "x") {}.startsGroup)
        #expect(!ainkradMenuItemStartsGroup(items, at: 0))
        #expect(!ainkradMenuItemStartsGroup(items, at: 1))
        #expect(ainkradMenuItemStartsGroup(items, at: 2))
    }
}
