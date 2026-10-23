import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("Kit Citadel components")
@MainActor
struct AinkradCitadelKitTests {
    @Test("a budget bar warns at its mark, stops at its limit, and clamps its fill")
    func budgetLevels() {
        #expect(budgetBarState(value: 412, limit: 900, warnFraction: 0.8) == (412.0 / 900, .ok))
        #expect(budgetBarState(value: 4.2, limit: 5, warnFraction: 0.8).level == .warning)
        #expect(budgetBarState(value: 4.2, limit: 5, warnFraction: nil).level == .ok)
        #expect(budgetBarState(value: 40, limit: 40, warnFraction: 0.8).level == .over)
        #expect(budgetBarState(value: 55, limit: 40, warnFraction: 0.8) == (1, .over))
        #expect(budgetBarState(value: -3, limit: 40, warnFraction: 0.8) == (0, .ok))
        #expect(budgetBarState(value: 3, limit: 0, warnFraction: 0.8) == (0, .ok))
    }

    @Test("a reorder moves one element and clamps out-of-range targets")
    func reorder() {
        #expect(reorderedItems([1, 2, 3, 4], moving: 0, to: 2) == [2, 3, 1, 4])
        #expect(reorderedItems([1, 2, 3, 4], moving: 3, to: 0) == [4, 1, 2, 3])
        #expect(reorderedItems([1, 2, 3], moving: 0, to: -1) == [1, 2, 3])
        #expect(reorderedItems([1, 2, 3], moving: 2, to: 9) == [1, 2, 3])
        #expect(reorderedItems([1, 2, 3], moving: 5, to: 0) == [1, 2, 3])
    }

    @Test("a scope is equal only to the same source and value")
    func scopes() {
        #expect(AinkradValueScope.inherited(from: "company") == .inherited(from: "company"))
        #expect(
            AinkradValueScope.overridden(at: "project", inheritedValue: "company 15 min")
                != .overridden(at: "project", inheritedValue: nil))
    }

    @Test("a workspace defaults to own, untinted, nothing waiting")
    func workspaceDefaults() {
        let workspace = AinkradWorkspace(id: "a", name: "Ainkrad")
        #expect(workspace.kind == .own)
        #expect(workspace.tint == nil)
        #expect(workspace.needsYou == 0)
    }
}
