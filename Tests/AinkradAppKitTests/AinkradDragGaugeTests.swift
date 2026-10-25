import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradDragGauge")
@MainActor
struct AinkradDragGaugeTests {
    @Test("a value snaps onto the step grid and clamps to the range")
    func snaps() {
        #expect(AinkradDragGauge.snapped(7.4, in: 0...100, step: 5) == 5)
        #expect(AinkradDragGauge.snapped(7.6, in: 0...100, step: 5) == 10)
        #expect(AinkradDragGauge.snapped(-3, in: 10...100, step: 5) == 10)
        #expect(AinkradDragGauge.snapped(999, in: 10...100, step: 5) == 100)
    }

    @Test("the gauge draws enabled, with a mark, and read-only")
    func draws() {
        let tint = Color.blue
        let view = VStack(spacing: 24) {
            AinkradDragGauge(value: 40, range: 0...100, step: 5, mark: 60, tint: tint, label: "Budget")
            AinkradDragGauge(value: 20, range: 0...100, tint: tint, isEnabled: false, label: "Locked")
        }
        #expect(PromotedRender.draws(view, width: 320, height: 120))
    }
}
