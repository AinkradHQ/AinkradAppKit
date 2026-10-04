import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@MainActor
@Suite("AinkradModal sizing")
struct AinkradModalTests {
    /// The number callers actually get. Half of one app's modal call sites were
    /// laid out against `maxWidth` and overflowed the panel border, because the
    /// modifier pads BEFORE it caps and nothing said so.
    @Test("contentWidth is maxWidth minus the modifier's own padding")
    func contentWidthAccountsForPadding() {
        #expect(AinkradModalMetrics.maxWidth == 480)
        #expect(
            AinkradModalMetrics.contentWidth
                == AinkradModalMetrics.maxWidth - 2 * AinkradSpacing.lg)
        #expect(AinkradModalMetrics.contentWidth == 448)
    }

    /// Both spellings must remain callable: the original is load-bearing for
    /// every modal already shipped, and reordering its arithmetic would move
    /// all of them at once.
    @Test("both modal entry points compile and are distinct")
    func bothEntryPointsExist() {
        let presented = Binding<Bool>(get: { true }, set: { _ in })
        _ = Color.clear.ainkradModal(isPresented: presented) { Text("historical") }
        _ = Color.clear.ainkradModal(
            isPresented: presented,
            contentWidth: 520
        ) { Text("explicit") }
    }
}
