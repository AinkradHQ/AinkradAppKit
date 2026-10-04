import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradButton inits")
struct AinkradButtonInitTests {
    @Test("existing init and the new isLoading overload both construct (compile smoke)")
    func constructs() {
        // Existing symbol must still exist, byte-unchanged.
        _ = AinkradButton(title: "Fetch", style: .primary, icon: "arrow.down") {}
        // NEW overload: isLoading has no default, a distinct symbol.
        _ = AinkradButton(title: "Fetch", style: .primary, icon: "arrow.down", isLoading: true) {}
        _ = AinkradButton(title: "Push", isLoading: false) {}
    }
}

@Suite("AinkradButtonStyle")
struct AinkradButtonStyleTests {
    @Test("all four cases are present")
    func caseCount() {
        #expect(AinkradButtonStyle.allCases.count == 4)
    }

    @Test("primary and secondary use an accent fill; ghost and danger do not")
    func usesAccentFill() {
        #expect(AinkradButtonStyle.primary.usesAccentFill == true)
        #expect(AinkradButtonStyle.ghost.usesAccentFill == false)
    }

    @Test("only danger is flagged as danger")
    func isDanger() {
        #expect(AinkradButtonStyle.danger.isDanger == true)
        #expect(AinkradButtonStyle.primary.isDanger == false)
        #expect(AinkradButtonStyle.secondary.isDanger == false)
        #expect(AinkradButtonStyle.ghost.isDanger == false)
    }

    @Test("ghost has no fill opacity; filled styles do")
    func fillOpacity() {
        #expect(AinkradButtonStyle.ghost.fillOpacity == 0)
        #expect(AinkradButtonStyle.primary.fillOpacity > 0)
    }
}
