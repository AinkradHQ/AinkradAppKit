import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradDockButton modifiers")
@MainActor
struct AinkradDockButtonTests {
    @Test("tones, a tinted call to action, a busy one, a toggle and a custom icon all draw")
    func variantsDraw() {
        let row = VStack(alignment: .leading, spacing: 8) {
            HStack {
                AinkradDockButton("Plain") {}
                AinkradDockButton("Go", systemImage: "play", tone: .primary) {}
                AinkradDockButton("Stop", tone: .danger) {}
            }
            HStack {
                AinkradDockButton("Wake my Mac") {}.tinted(.orange)
                AinkradDockButton("Wake my Mac") {}.tinted(.orange, busyTitle: "Waking…")
            }
            HStack {
                AinkradDockButton("Follow live", systemImage: "arrow.down") {}.toggled(true).tooltip("⌘↓")
                AinkradDockButton("List", systemImage: "list.bullet") {}.toggled(false, tint: .teal)
                AinkradDockButton("Agent") {}.icon { Circle().fill(.pink) }
            }
        }
        #expect(PromotedRender.draws(row, width: 460, height: 200))
    }
}
