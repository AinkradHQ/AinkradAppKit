import Foundation
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitUI

@Suite("AinkradMarkdownBlocks")
struct AinkradMarkdownBlocksTests {
    @Test func plainParagraph() {
        #expect(AinkradMarkdownBlocks.parse("hello **world**") == [.paragraph("hello **world**")])
    }

    @Test func heading() {
        #expect(AinkradMarkdownBlocks.parse("## Title") == [.heading(level: 2, text: "Title")])
    }

    @Test func closedFencedCodeWithLanguage() {
        let src = "```swift\nlet x = 1\n```"
        #expect(AinkradMarkdownBlocks.parse(src) == [.codeBlock(language: "swift", code: "let x = 1")])
    }

    @Test func unterminatedFenceStreamsAsCode() {
        let src = "```swift\nlet x = 1"
        #expect(AinkradMarkdownBlocks.parse(src) == [.codeBlock(language: "swift", code: "let x = 1")])
    }

    @Test func fenceWithoutLanguage() {
        let src = "```\nraw\n```"
        #expect(AinkradMarkdownBlocks.parse(src) == [.codeBlock(language: nil, code: "raw")])
    }

    @Test func bulletList() {
        #expect(AinkradMarkdownBlocks.parse("- a\n- b") == [.bulletList(["a", "b"])])
    }

    @Test func orderedList() {
        #expect(AinkradMarkdownBlocks.parse("1. a\n2. b") == [.orderedList(["a", "b"])])
    }

    @Test func mixedBlocksSeparatedByBlankLines() {
        let src = "intro\n\n- one\n- two\n\n```\ncode\n```\n\noutro"
        #expect(
            AinkradMarkdownBlocks.parse(src) == [
                .paragraph("intro"),
                .bulletList(["one", "two"]),
                .codeBlock(language: nil, code: "code"),
                .paragraph("outro"),
            ])
    }

    @Test func consecutiveTextLinesJoinIntoOneParagraph() {
        #expect(AinkradMarkdownBlocks.parse("line one\nline two") == [.paragraph("line one\nline two")])
    }

    @Test func emptyStringIsNoBlocks() {
        #expect(AinkradMarkdownBlocks.parse("") == [])
    }

    @Test func thematicBreakDashes() {
        #expect(AinkradMarkdownBlocks.parse("---") == [.thematicBreak])
    }

    @Test func thematicBreakAsterisks() {
        #expect(AinkradMarkdownBlocks.parse("***") == [.thematicBreak])
    }

    @Test func thematicBreakBetweenParagraphs() {
        #expect(AinkradMarkdownBlocks.parse("a\n\n---\n\nb") == [.paragraph("a"), .thematicBreak, .paragraph("b")])
    }

    @Test func bulletNotMistakenForRule() {
        #expect(AinkradMarkdownBlocks.parse("- a\n- b") == [.bulletList(["a", "b"])])
    }

    // MARK: - GD11: tables and quotes

    @Test func pipeTable() {
        let src = "| Repo | Tests | Note |\n|---|--:|:-:|\n| Forge | 93 + 13 | ok |\n| Grimoire | 96 |"
        let table = AinkradMarkdownTable(
            header: ["Repo", "Tests", "Note"], alignments: [.none, .trailing, .center],
            rows: [["Forge", "93 + 13", "ok"], ["Grimoire", "96", ""]])
        #expect(AinkradMarkdownBlocks.parse(src) == [.table(table)])
        #expect(table.isNumeric(column: 1))
        #expect(!table.isNumeric(column: 0))
    }

    @Test func tableWithoutOuterPipesAndEscapedPipe() {
        let src = "a | b\n--- | ---\nx \\| y | z"
        #expect(
            AinkradMarkdownBlocks.parse(src) == [
                .table(AinkradMarkdownTable(header: ["a", "b"], alignments: [.none, .none], rows: [["x | y", "z"]]))
            ])
    }

    @Test func aPipeLineWithoutSeparatorStaysProse() {
        #expect(AinkradMarkdownBlocks.parse("a | b\nnot a separator") == [.paragraph("a | b\nnot a separator")])
    }

    @Test func tableEndsAtProse() {
        let blocks = AinkradMarkdownBlocks.parse("Results:\n| a |\n|---|\n| 1 |\nDone.")
        #expect(blocks.count == 3)
        #expect(blocks.first == .paragraph("Results:"))
        #expect(blocks.last == .paragraph("Done."))
    }

    @Test func blockQuote() {
        #expect(AinkradMarkdownBlocks.parse("> one\n>two\n\nafter") == [.blockQuote("one\ntwo"), .paragraph("after")])
    }
}
