import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradFormControls")
struct AinkradFormControlsTests {
    @Test("FormRow exposes its title and help")
    func formRow() {
        let row = AinkradFormRow(title: "Enabled", help: "Turns it on") { EmptyView() }
        #expect(row.title == "Enabled")
        #expect(row.help == "Turns it on")
    }
}

@Suite("AinkradTextArea")
struct AinkradTextAreaTests {
    @Test("all three inits construct; bare 2-arg resolves to init(text:placeholder:)")
    func constructs() {
        var s = ""
        let binding = Binding<String>(get: { s }, set: { s = $0 })
        // Bare 2-arg — must resolve to the non-defaulted init(text:placeholder:).
        _ = AinkradTextArea(text: binding, placeholder: "notes")
        // Existing autoFocus overload.
        _ = AinkradTextArea(text: binding, placeholder: "notes", autoFocus: true)
        // New minHeight overload.
        _ = AinkradTextArea(text: binding, placeholder: "comment", minHeight: 44)
    }
}
