import Foundation
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitUI

@Suite("AinkradInlineMarkdownCache", .serialized)
struct AinkradInlineMarkdownCacheTests {

    @Test func resolvesInlineBold() {
        AinkradInlineMarkdownCache.clear()
        let result = AinkradInlineMarkdownCache.attributed("hello **world**")
        #expect(String(result.characters) == "hello world")
    }

    @Test func repeatedLookupsReturnAnEqualValue() {
        AinkradInlineMarkdownCache.clear()
        let first = AinkradInlineMarkdownCache.attributed("a *b* c")
        let second = AinkradInlineMarkdownCache.attributed("a *b* c")
        #expect(first == second)
    }

    @Test func distinctSourcesProduceDistinctEntries() {
        AinkradInlineMarkdownCache.clear()
        _ = AinkradInlineMarkdownCache.attributed("one")
        _ = AinkradInlineMarkdownCache.attributed("two")
        #expect(AinkradInlineMarkdownCache.countForTesting == 2)
    }

    @Test func theSameSourceIsStoredOnce() {
        AinkradInlineMarkdownCache.clear()
        for _ in 0..<50 { _ = AinkradInlineMarkdownCache.attributed("same") }
        #expect(AinkradInlineMarkdownCache.countForTesting == 1)
    }

    @Test func whitespaceIsPreservedAsTheRendererExpects() {
        AinkradInlineMarkdownCache.clear()
        // .inlineOnlyPreservingWhitespace is what AinkradMarkdownText used; losing
        // it would silently collapse indentation in the transcript.
        let result = AinkradInlineMarkdownCache.attributed("a    b")
        #expect(String(result.characters) == "a    b")
    }

    @Test func unparseableSourceFallsBackToPlainTextRatherThanThrowing() {
        AinkradInlineMarkdownCache.clear()
        let weird = "[unclosed(("
        let result = AinkradInlineMarkdownCache.attributed(weird)
        #expect(String(result.characters).contains("unclosed"))
    }

    @Test func clearEmptiesTheCache() {
        AinkradInlineMarkdownCache.clear()
        _ = AinkradInlineMarkdownCache.attributed("x")
        AinkradInlineMarkdownCache.clear()
        #expect(AinkradInlineMarkdownCache.countForTesting == 0)
    }
}
