import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradDisclosureGroup")
@MainActor
struct AinkradDisclosureGroupTests {
    @Test("the chevron reflects expansion state")
    func chevronDirection() {
        #expect(AinkradDisclosureGroup<EmptyView>.chevron(isExpanded: true) == "chevron.down")
        #expect(AinkradDisclosureGroup<EmptyView>.chevron(isExpanded: false) == "chevron.right")
    }

    @Test("binding drives expansion rather than internal state")
    func bindingDriven() {
        var expanded = false
        let binding = Binding(get: { expanded }, set: { expanded = $0 })
        let group = AinkradDisclosureGroup(title: "Advanced", isExpanded: binding) { EmptyView() }
        #expect(group.isExpanded.wrappedValue == false)
        group.isExpanded.wrappedValue = true
        #expect(expanded == true)
    }

    @Test("a hit count is carried and zero means no badge")
    func hitCount() {
        let none = AinkradDisclosureGroup(title: "A", isExpanded: .constant(true)) { EmptyView() }
        #expect(none.hitCount == 0)
        let some = AinkradDisclosureGroup(title: "A", isExpanded: .constant(true), hitCount: 3) { EmptyView() }
        #expect(some.hitCount == 3)
    }
}
