import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradFormRow slots")
@MainActor
struct AinkradFormRowTests {
    @Test("existing two-argument call sites still compile and carry no extras")
    func backwardCompatible() {
        let row = AinkradFormRow(title: "Blur", help: "Blur the workspace") { EmptyView() }
        #expect(row.title == "Blur")
        #expect(row.help == "Blur the workspace")
        #expect(row.badges.isEmpty)
        #expect(row.controlWidth == nil)
    }

    @Test("badges and a fixed control width are carried when supplied")
    func slotsCarried() {
        let row = AinkradFormRow(
            title: "Sandbox",
            help: nil,
            badges: ["ADVANCED", "RESTART REQUIRED"],
            controlWidth: 220
        ) { EmptyView() }
        #expect(row.badges == ["ADVANCED", "RESTART REQUIRED"])
        #expect(row.controlWidth == 220)
    }
}
