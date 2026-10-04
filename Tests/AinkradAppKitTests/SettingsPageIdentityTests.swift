import AinkradAppKitContract
import Foundation
import Testing

@testable import AinkradAppKit

/// The tabbed branch of `SettingsPageView` renders ONE `SettingsGroupView` at a
/// fixed structural position. Without a per-group `.id` SwiftUI gives every
/// tab's group the same view identity, so `SettingsGroupView`'s `@State
/// isExpanded` persists across tab switches and the `mustExpand` seeding in
/// its `init` never runs again — a collapsed group on a later tab renders as a
/// bare header and deep-links into it scroll to nothing.
///
/// `deepLinkTarget` models that semantics, but nothing else stops the modifier
/// itself from being deleted, and this exact shape has regressed three times.
/// So this checks the source: the `.id` must be there, and it must be the same
/// value `deepLinkTarget` reasons about.
@Suite("SettingsPageView tab identity")
@MainActor
struct SettingsPageIdentityTests {
    private var source: String {
        let here = URL(fileURLWithPath: #filePath)
        let root = here.deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent()
        let file = root.appendingPathComponent("Sources/AinkradAppKit/SettingsPageView.swift")
        return (try? String(contentsOf: file, encoding: .utf8)) ?? ""
    }

    @Test("the tabbed group view carries a per-group identity")
    func tabbedGroupHasIdentity() {
        let text = source
        #expect(!text.isEmpty, "could not read SettingsPageView.swift")
        #expect(
            text.contains(".id(Self.groupViewIdentity(page: page, index: index))"),
            "the tabbed SettingsGroupView lost its per-group .id — tab state will bleed between groups")
    }

    @Test("group identity varies per group")
    func identityVariesPerGroup() {
        let root = SettingsPath(["test", "page"])
        let page = SettingsPage(
            path: root, title: "Test", icon: "gear", group: .workspace, order: 0,
            groups: (0..<3).map { i in
                SettingsGroup(
                    path: root.appending("g\(i)"), title: "G\(i)",
                    fields: [
                        SettingsField(
                            path: root.appending("g\(i)").appending("f"),
                            label: "F", kind: .toggle(.constant(false)))
                    ])
            })
        let ids = page.groups.indices.map { SettingsPageView.groupViewIdentity(page: page, index: $0) }
        #expect(Set(ids).count == ids.count)
    }
}

@Suite("Settings page shape")
@MainActor
struct SettingsPageShapeTests {
    private func page(groups: Int) -> SettingsPage {
        SettingsPage(
            path: SettingsPath(["p"]), title: "P", icon: "gear", group: .installedApps, order: 0,
            groups: (0..<groups).map { SettingsGroup(path: SettingsPath(["p", "\($0)"]), title: "\($0)", fields: []) })
    }

    @Test("two groups are tabs; one is a plain column")
    func twoGroupsAreTabbed() {
        #expect(!SettingsPageView.usesTabs(page: page(groups: 1)))
        #expect(SettingsPageView.usesTabs(page: page(groups: 2)))
    }

    @Test("a long select is a menu, a short one a segmented control")
    func longSelectsAreMenus() {
        #expect(!SettingsRow.usesMenu(optionCount: 4))
        #expect(SettingsRow.usesMenu(optionCount: 5))
    }
}
