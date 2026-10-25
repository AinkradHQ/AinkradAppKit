import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradChainEditor")
@MainActor
struct AinkradChainEditorTests {
    static let links = [
        AinkradChainLink(
            id: "a", kind: "claude", title: "opus", detail: "the agent's own", chip: "serving", isCurrent: true,
            isFixed: true),
        AinkradChainLink(id: "b", kind: "opencode", title: "qwen", detail: "unpriced", detailWarns: true),
    ]

    @Test("an editable chain, a read-only chain, a flow and an avatar stack draw")
    func chainsDraw() {
        struct Person: Identifiable { let id: Int }
        let view = VStack(alignment: .leading, spacing: 10) {
            AinkradChainEditor(links: Self.links) { kind in Text(kind) }
            AinkradChainEditor(links: Self.links, editable: false) { kind in Text(kind) }
            AinkradChainFlow(steps: [("claude", "opus"), ("opencode", "qwen")]) { Text($0) }
            AinkradAvatarStack(items: [Person(id: 1), Person(id: 2)], size: 22) { _ in Circle().fill(.pink) }
        }
        #expect(PromotedRender.draws(view.frame(width: 380), width: 420, height: 340))
    }

    @Test("a link is equal only to the same link")
    func equality() {
        #expect(Self.links[0] == Self.links[0])
        var moved = Self.links[1]
        moved.isCurrent = true
        #expect(moved != Self.links[1])
    }

    @Test("a drop zone draws over its content")
    func dropZoneDraws() {
        let view = Text("Backlog").frame(width: 200, height: 80).ainkradDropZone { _ in true }
        #expect(PromotedRender.draws(view, width: 240, height: 120))
    }
}
