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
}
