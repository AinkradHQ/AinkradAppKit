import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradConversationComposer")
@MainActor
struct AinkradConversationComposerTests {
    @Test("a composer with a To row, a chip and an attach button draws, empty and filled")
    func composerDraws() {
        for text in ["", "Ship it"] {
            let view = AinkradConversationComposer(
                text: .constant(text), placeholder: "Message the agent", isTargeted: true,
                hint: "↵ sends · ⇧↵ new line", onAttach: {}, onSend: {},
                toRow: { AinkradComposerChip(label: "Ada · question", onRemove: {}) { Circle().fill(.pink) } },
                avatar: { Circle().fill(.teal).frame(width: 28, height: 28) })
            #expect(PromotedRender.draws(view.frame(width: 420), width: 460, height: 200))
        }
    }

    @Test("the bare editor draws its placeholder")
    func bareEditorDraws() {
        let editor = AinkradBareEditor(text: .constant(""), placeholder: "What do you want?", sizeKey: "t20")
        #expect(PromotedRender.draws(editor.frame(width: 300), height: 80))
    }
}
