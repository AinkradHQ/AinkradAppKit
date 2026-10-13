import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Parity batch 4: every Forge/Grimoire mockup style is opt-in, off by default.
@Suite("Kit parity batch 4")
@MainActor
struct KitParityBatch4Tests {
    @Test("a dimmed composer text field is opt-in")
    func composerTextFieldDimmed() {
        #expect(!KitParityBatch2Tests.composer().dimsTextField)
        #expect(KitParityBatch2Tests.composer().textFieldDimmed(true).dimsTextField)
        #expect(!KitParityBatch2Tests.composer().textFieldDimmed(true).textFieldDimmed(false).dimsTextField)
    }
}
