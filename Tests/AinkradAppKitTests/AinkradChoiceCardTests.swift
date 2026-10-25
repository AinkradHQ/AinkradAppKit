import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradChoiceCard family")
@MainActor
struct AinkradChoiceCardTests {
    @Test("cards draw in every state, axis and height mode")
    func cardsDraw() {
        let grid = AinkradCardGrid(columns: 3) {
            AinkradChoiceCard(isOn: true, height: 52, action: {}) {
                AinkradChoiceGlyph("bolt", isOn: true)
                AinkradChoiceText(title: "Engineer", caption: "Writes the code")
            }
            AinkradChoiceCard(isAdd: true, minHeight: 46) {
                AinkradChoiceGlyph("plus")
                AinkradChoiceText(title: "Custom", caption: "Name it", compact: true)
            }
            AinkradChoiceCard(axis: .vertical, action: {}) {
                AinkradCheckBox(isOn: true)
                AinkradDotMeter(value: 2)
                AinkradLevelBars(level: 1)
            }
        }
        #expect(PromotedRender.draws(grid, width: 520, height: 140))
    }

    @Test("a toggle card, a group label and an option grid draw")
    func companionsDraw() {
        let view = VStack(alignment: .leading) {
            AinkradGroupLabel(title: "Guidelines", trailing: "5 on")
            AinkradToggleCard(title: "No force push", isOn: true, flash: true) {}
            AinkradOptionGrid(
                options: [
                    AinkradOption(id: "a", title: "Claude", detail: "Anthropic", systemImage: "sparkles"),
                    AinkradOption(id: "b", title: "Codex", detail: "OpenAI", isEnabled: false),
                ], columns: 2, isOn: { $0 == "a" }, pick: { _ in })
        }
        #expect(PromotedRender.draws(view, width: 420, height: 260))
    }

    @Test("the inline chips draw")
    func chipsDraw() {
        let view = VStack(alignment: .leading) {
            AinkradValuePill(text: "3M tok") { _ in }
            AinkradScopeChip(text: "project", overridden: true) {}
            AinkradToggleChip(title: "rate-limited", isOn: true) {}
            AinkradMiniSegment(options: [(1, "Tokens"), (2, "Time")], selection: .constant(1))
        }
        #expect(PromotedRender.draws(view))
    }
}
