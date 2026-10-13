import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Parity batch 3: every Forge/Grimoire mockup style is opt-in, off by default.
@Suite("Kit parity batch 3")
@MainActor
struct KitParityBatch3Tests {
    @Test("a full-width button is opt-in")
    func buttonFullWidth() {
        #expect(!AinkradButton(title: "Commit") {}.fillsWidth)
        #expect(AinkradButton(title: "Commit") {}.fullWidth().fillsWidth)
    }

    @Test("an outlined button is opt-in")
    func buttonOutlined() {
        #expect(!AinkradButton(title: "Stop", style: .danger) {}.isOutlined)
        #expect(AinkradButton(title: "Stop", style: .danger) {}.outlined().isOutlined)
    }

    @Test("a compact button is opt-in")
    func buttonCompact() {
        #expect(!AinkradButton(title: "Replace All") {}.isCompact)
        #expect(AinkradButton(title: "Replace All") {}.compact().isCompact)
    }

    @Test("a glyph Send and a Stop button are opt-in")
    func composerGlyphAndStop() {
        let plain = KitParityBatch2Tests.composer()
        #expect(plain.sendGlyph == nil)
        #expect(plain.onStop == nil)
        let busy = plain.sendGlyph("↵").stopButton("■ Stop") {}
        #expect(busy.sendGlyph == "↵")
        #expect(busy.stopTitle == "■ Stop")
        #expect(busy.onStop != nil)
        #expect(plain.stopButton("■ Stop", action: nil).onStop == nil)
        #expect(AinkradIconButton(systemName: "arrow.up") {}.textGlyph("↵").textGlyph == "↵")
    }

    @Test("an empty state's text glyph and icon tint are opt-in")
    func emptyStateGlyph() {
        let plain = AinkradEmptyState(icon: "books.vertical", title: "No threads yet", message: "")
        #expect(plain.textGlyph == nil)
        #expect(plain.tint == nil)
        let grimoire = plain.glyph("❖").iconTint(.cyan)
        #expect(grimoire.textGlyph == "❖")
        #expect(grimoire.tint != nil)
    }

    @Test("a decision action's detail and the bar's text glyph are opt-in")
    func decisionBarDetailAndGlyph() {
        let action = AinkradDecisionBar.Action(title: "Always allow", style: .secondary) {}
        #expect(action.detail == nil)
        #expect(action.button.detail == nil)
        #expect(action.detail("git push *").button.detail == "git push *")
        let bar = AinkradDecisionBar(icon: "terminal", iconTint: .secondary, caption: "", title: "", actions: [])
        #expect(bar.textGlyph == nil)
        #expect(bar.iconGlyph("⌁").textGlyph == "⌁")
    }

    @Test("disabled segmented options are opt-in")
    func segmentedDisabledOptions() {
        let picker = AinkradSegmentedPicker(items: ["Claude", "Codex"], selection: .constant("Claude")) { $0 }
        #expect(picker.isOptionDisabled == nil)
        let gated = picker.disabledOptions { $0 == "Codex" }
        #expect(gated.isOptionDisabled?("Codex") == true)
        #expect(gated.isOptionDisabled?("Claude") == false)
    }

    @Test("a search field's trailing accessory and code query are opt-in")
    func searchFieldAccessory() {
        let plain = AinkradSearchField(text: .constant(""), placeholder: "Search")
        #expect(plain.accessory == nil)
        #expect(!plain.isCodeQuery)
        let forge = plain.codeQuery().trailingAccessory { Text("Aa") }
        #expect(forge.accessory != nil)
        #expect(forge.isCodeQuery)
    }

    @Test("a compact text field is opt-in")
    func textFieldCompact() {
        #expect(!AinkradTextField(text: .constant(""), placeholder: "").isCompact)
        #expect(AinkradTextField(text: .constant(""), placeholder: "").leadingLabel("include").compact().isCompact)
    }

    @Test("bare diff hunks are opt-in")
    func diffBareHunks() {
        let review = AinkradDiffReview(fileDiff: KitParityBatch2RenderTests.reviewDiff, rejectedHunkIDs: .constant([]))
        #expect(!review.usesBareHunks)
        #expect(review.bareHunks().usesBareHunks)
    }

    @Test("glyph palette icons are opt-in")
    func commandMenuGlyphIcons() {
        let menu = AinkradCommandMenu(items: ["a"], selection: .constant(nil), icon: { _ in "◆" }, label: { $0 })
        #expect(menu.glyphTint == nil)
        #expect(menu.iconGlyphs { _ in .orange }.glyphTint?("a") != nil)
    }

    @Test("per-segment breadcrumb colours are opt-in")
    func breadcrumbSegmentColors() {
        let crumb = AinkradBreadcrumb(items: ["Sources", "SidebarRow.swift", "SidebarRow", "body"])
        #expect(crumb.segmentColor == nil)
        let forge = crumb.segmentColors { $0 == 1 ? .white : nil }
        #expect(forge.segmentColor?(1) != nil)
        #expect(forge.segmentColor?(3) == nil)
    }

    @Test("text tabs are opt-in")
    func textTabs() {
        let tabs = AinkradTabs(tabs: ["Files", "Changes 2"], selection: .constant("Files")) { $0 }
        #expect(!tabs.usesTextTabs)
        #expect(tabs.textTabs().usesTextTabs)
    }

    @Test("a menu item tint is opt-in")
    func menuItemTint() {
        #expect(AinkradMenuItem(title: "sourcekit-lsp — ready") {}.tintColor == nil)
        #expect(AinkradMenuItem(title: "ruby-lsp — not installed") {}.tint(.orange).tintColor != nil)
    }

    @Test("a field toggle flips its binding")
    func fieldToggle() {
        var isOn = false
        let binding = Binding(get: { isOn }, set: { isOn = $0 })
        _ = AinkradFieldToggle("Aa", isOn: binding, help: "Match case")
        binding.wrappedValue.toggle()
        #expect(isOn)
    }

    @Test("text breadcrumb separators are opt-in")
    func breadcrumbTextSeparators() {
        let crumb = AinkradBreadcrumb(items: ["Sources", "SidebarRow.swift"])
        #expect(!crumb.usesTextSeparators)
        #expect(crumb.textSeparators().usesTextSeparators)
    }
}
