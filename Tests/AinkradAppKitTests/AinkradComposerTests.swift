import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitUI

@Suite("AinkradComposer triggers")
struct AinkradComposerTriggerTests {
    private func row(_ insert: String) -> AinkradComposerSuggestion {
        AinkradComposerSuggestion(id: insert, icon: "doc", title: insert, insertText: insert)
    }

    @Test("a leading slash is a command until a space or newline follows")
    func command() {
        #expect(AinkradComposerTrigger.detect(in: "/") == .command(query: ""))
        #expect(AinkradComposerTrigger.detect(in: "/rev") == .command(query: "rev"))
        #expect(AinkradComposerTrigger.detect(in: "/review now") == nil)
        #expect(AinkradComposerTrigger.detect(in: "/a\nb") == nil)
        #expect(AinkradComposerTrigger.detect(in: "fix /path") == nil)
    }

    @Test("a trailing @token is a mention, anywhere in the draft")
    func mention() {
        #expect(AinkradComposerTrigger.detect(in: "@") == .mention(query: ""))
        #expect(AinkradComposerTrigger.detect(in: "look at @Sources/ma") == .mention(query: "Sources/ma"))
        #expect(AinkradComposerTrigger.detect(in: "mail me@x.com later") == nil)
        #expect(AinkradComposerTrigger.detect(in: "plain text") == nil)
        #expect(AinkradComposerTrigger.detect(in: "") == nil)
    }

    @Test("picking a command replaces the whole draft")
    func applyCommand() {
        let trigger = AinkradComposerTrigger.command(query: "re")
        #expect(trigger.applying(row("/review"), to: "/re") == "/review ")
    }

    @Test("picking a mention replaces only the trailing token")
    func applyMention() {
        let trigger = AinkradComposerTrigger.mention(query: "ma")
        #expect(trigger.applying(row("@/repo/main.swift"), to: "explain @ma") == "explain @/repo/main.swift ")
        #expect(trigger.applying(row("@/repo/main.swift"), to: "@ma") == "@/repo/main.swift ")
        #expect(trigger.applying(row("@/a"), to: "one\n@") == "one\n@/a ")
    }

    @Test("the overlay swallows arrows and both Return keys, nothing else")
    func keys() {
        #expect(AinkradComposerOverlayKey.key(for: 126) == .up)
        #expect(AinkradComposerOverlayKey.key(for: 125) == .down)
        #expect(AinkradComposerOverlayKey.key(for: 36) == .confirm)
        #expect(AinkradComposerOverlayKey.key(for: 76) == .confirm)
        for code: UInt16 in [53, 48, 0, 123, 124] {
            #expect(AinkradComposerOverlayKey.key(for: code) == nil)
        }
    }

    @Test("the highlight wraps at both ends and survives an empty list")
    func wrap() {
        #expect(AinkradComposerOverlayKey.moved(0, by: -1, count: 3) == 2)
        #expect(AinkradComposerOverlayKey.moved(2, by: 1, count: 3) == 0)
        #expect(AinkradComposerOverlayKey.moved(1, by: 1, count: 3) == 2)
        #expect(AinkradComposerOverlayKey.moved(4, by: 1, count: 0) == 0)
    }

    @Test("the highlight resets only when the overlay switches kind")
    func sameKind() {
        typealias Composer = AinkradComposer<EmptyView, EmptyView, EmptyView>
        #expect(Composer.sameKind(.command(query: "a"), .command(query: "ab")))
        #expect(!Composer.sameKind(.command(query: "a"), .mention(query: "a")))
        #expect(!Composer.sameKind(nil, .mention(query: "")))
    }

    @MainActor @Test("constructs with empty slots (compile smoke)")
    func constructs() {
        _ = AinkradComposer(
            text: .constant(""), placeholder: "Message…", isEditable: true, canSend: false, autoFocus: false,
            suggestions: { _ in [] }, onPick: { _, _ in }, onDrop: nil, onSend: {},
            chips: { EmptyView() }, leading: { EmptyView() }, trailing: { EmptyView() })
    }
}
