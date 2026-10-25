import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradValuePill and AinkradScopeChip options")
@MainActor
struct AinkradInlineChipOptionsTests {
    @Test("a readout pill, a validating pill and a chip with a tooltip draw")
    func optionsDraw() {
        let view = VStack(alignment: .leading, spacing: 12) {
            AinkradValuePill(text: "—") { _ in }.editable(false)
            AinkradValuePill(text: "3M tok") { _ in }
                .validating({ !$0.isEmpty }, onRefuse: { _ in })
            AinkradScopeChip(text: "server", overridden: false).tooltip("Inherited from the server")
        }
        #expect(PromotedRender.draws(view))
    }
}
