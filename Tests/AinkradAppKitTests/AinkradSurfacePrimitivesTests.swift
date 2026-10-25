import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("Promoted Citadel surface primitives")
@MainActor
struct AinkradSurfacePrimitivesTests {
    @Test("a bento tile (plain, tinted, tappable), a section head and a state pill draw")
    func surfacesDraw() {
        let view = VStack(alignment: .leading, spacing: 10) {
            AinkradSectionHead(title: "What needs you now", count: "8", link: "Open inbox →") {}
            HStack {
                AinkradBentoTile { Text("Plain") }
                AinkradBentoTile(tint: .orange, onTap: {}) { Text("Tinted") }
            }
            HStack {
                AinkradStatePill(text: "running", tint: .green, dot: true)
                AinkradStatePill(text: "failed", tint: .red)
            }
        }
        #expect(PromotedRender.draws(view, width: 380, height: 220))
    }

    @Test("icon tiles draw as a symbol (plain, filled, ringed) and as a text glyph")
    func iconTilesDraw() {
        let view = HStack {
            AinkradIconTile(systemName: "doc", tint: .blue)
            AinkradIconTile(systemName: "doc", tint: .blue, size: 40, radius: 12, filled: true)
            AinkradIconTile(systemName: "doc", tint: .blue, size: 28, ring: true)
            AinkradIconTile(glyph: "⚿", tint: .orange)
        }
        #expect(PromotedRender.draws(view, width: 260, height: 100))
    }
}
