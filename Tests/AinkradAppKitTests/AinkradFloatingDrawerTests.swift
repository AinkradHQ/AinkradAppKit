import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradFloatingDrawer")
@MainActor
struct AinkradFloatingDrawerTests {
    @Test("a reader panel and a form panel (with footer, trailing slot and sections) draw")
    func panelsDraw() {
        let reader = AinkradDrawerPanel(onClose: {}, header: { AinkradDrawerCrumb(["Runs", "#4"]) }) {
            Text("Body")
        }
        #expect(PromotedRender.draws(reader.frame(width: 320, height: 160)))

        let form = AinkradDrawerPanel(
            style: .form, onClose: {}, header: { AinkradDrawerCrumb(["Cost", "Set a price"], monospaced: true) },
            trailing: { Text("1 / 3") },
            content: {
                AinkradDrawerHero(tint: .blue, title: "Model", subtitle: "priced", leading: { Text("◆") }) {
                    EmptyView()
                }
                AinkradDrawerSection(title: "Apply to", hint: "now") { AinkradDrawerHint("A hint") }
            }
        ) {
            Text("Save")
        }
        #expect(PromotedRender.draws(form.frame(width: 320, height: 320), height: 340))
    }

    @Test("a presented drawer draws over its host")
    func hostDraws() {
        func host(_ shown: Bool) -> some View {
            Color.clear.ainkradFloatingDrawer(isPresented: .constant(shown)) {
                AinkradDrawerPanel(onClose: {}, header: { Text("Head") }) { Text("Body") }
            }
            .frame(width: 400, height: 240)
        }
        #expect(PromotedRender.draws(host(true), width: 400, height: 240))
    }

    @Test("the pager button and the close button draw")
    func buttonsDraw() {
        #expect(PromotedRender.draws(AinkradDrawerButton(glyph: "chevron.left", size: 28, filled: true) {}))
        #expect(PromotedRender.draws(AinkradDrawerButton {}))
    }
}
