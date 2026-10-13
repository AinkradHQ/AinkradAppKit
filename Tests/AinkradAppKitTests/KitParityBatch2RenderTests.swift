import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Off-screen Neon renders of the parity batch 2 styles, for comparing by eye
/// against `Designs/forge` and `Designs/grimoire`. Each one must render; the
/// PNGs are written only when AINKRAD_KIT2_SHOTS names a directory. Glass
/// cannot be drawn off-screen (see `NativeGlassSweepTests`).
@Suite("Kit parity batch 2 renders")
@MainActor
struct KitParityBatch2RenderTests {
    static func shoot<V: View>(_ name: String, width: CGFloat, height: CGFloat, @ViewBuilder _ view: () -> V) {
        let skin = AinkradSkin.standard
        let content = view()
            .padding(16)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(skin.color(skin.palette.background))
            .ainkradSkin(skin)
            .environment(\.colorScheme, .dark)
        let rep = SkinParityRenderer.render(content, width: width, height: height)
        #expect(rep != nil, "\(name) did not render")
        guard let dir = ProcessInfo.processInfo.environment["AINKRAD_KIT2_SHOTS"], let rep,
            let png = rep.representation(using: .png, properties: [:])
        else { return }
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }

    @Test func keycaps() {
        Self.shoot("kbd-outlined", width: 260, height: 70) {
            HStack(spacing: 6) {
                AinkradKbd("⌘P").outlined()
                AinkradKbd("⌘K").outlined()
                AinkradKbd("⌘\\").outlined()
                AinkradKbd("↵").outlined()
                AinkradKbd("⌘K")
            }
        }
    }

    @Test func breadcrumb() {
        Self.shoot("breadcrumb", width: 520, height: 90) {
            VStack(alignment: .leading, spacing: 12) {
                AinkradBreadcrumb(items: ["Sources", "Ainkrad", "Features", "Sidebar", "SidebarRow.swift"])
                    .preservesCase()
                    .icon(at: 4) { Image(systemName: "swift").foregroundStyle(.orange).imageScale(.small) }
                AinkradBreadcrumb(items: ["deploy-scripts", "release.rb"])
            }
        }
    }

    struct Hit: Hashable {
        let name: String
        let folder: String
        let section: String?
        let keys: String?
        let matched: [Int]
    }

    @Test func quickOpenPalette() {
        let hits = [
            Hit(
                name: "SidebarRow.swift", folder: "Sources/Ainkrad/Features/Sidebar", section: "Recently opened",
                keys: nil, matched: [0, 4, 7, 8, 9]),
            Hit(
                name: "SidebarRowTests.swift", folder: "Tests/AinkradTests/Sidebar", section: "Files", keys: nil,
                matched: [0, 4, 7, 8, 9]),
            Hit(
                name: "SessionBrowserRow.swift", folder: "Sources/Ainkrad/Features/Sessions", section: "Files",
                keys: nil, matched: [0, 13, 14, 15, 16]),
        ]
        Self.shoot("command-menu-quick-open", width: 560, height: 230) {
            AinkradCommandMenu(
                items: hits, selection: .constant(nil), icon: { _ in "swift" }, label: \.name,
                detail: { $0.folder }, value: { $0.keys }, uppercased: false, highlight: .constant(0)
            )
            .paletteRows()
            .matchedCharacters(\.matched)
            .sections(\.section)
        }
    }

    @Test func commandPalette() {
        let hits = [
            Hit(name: "View: Split Editor Right", folder: "", section: nil, keys: "⌘\\", matched: [6, 7, 8, 9, 10]),
            Hit(name: "View: Split Editor Down", folder: "", section: nil, keys: "⌘K ⌘\\", matched: [6, 7, 8, 9, 10]),
            Hit(name: "Git: Open in Git Mage", folder: "", section: "Recently used", keys: "⌘⇧G", matched: []),
            Hit(
                name: "Run Task…", folder: "make build · make test", section: "Recently used", keys: nil,
                matched: []),
        ]
        Self.shoot("command-menu-palette", width: 560, height: 230) {
            AinkradCommandMenu(
                items: hits, selection: .constant(nil), icon: { _ in "" }, label: \.name,
                detail: { $0.folder }, value: { $0.keys }, uppercased: false, highlight: .constant(0)
            )
            .paletteRows()
            .matchedCharacters(\.matched)
            .sections(\.section)
        }
        // The default rows with only matched letters opted in.
        Self.shoot("command-menu-legacy-matched", width: 560, height: 200) {
            AinkradCommandMenu(
                items: Array(hits.prefix(2)), selection: .constant(nil), icon: { _ in "rectangle.split.2x1" },
                label: \.name, value: { $0.keys }, uppercased: false
            )
            .matchedCharacters(\.matched)
        }
    }

    @Test func slashPalette() {
        let rows = [
            AinkradComposerSuggestion(
                id: "review", icon: "chevron.forward", title: "/review", subtitle: "Review the current diff",
                section: "Session", insertText: "/review"),
            AinkradComposerSuggestion(
                id: "compact", icon: "chevron.forward", title: "/compact", subtitle: "Summarise to free context",
                section: "Session", insertText: "/compact"),
            AinkradComposerSuggestion(
                id: "pr-sweep", icon: "sparkle", title: "/pr-sweep", subtitle: "Review and merge open PRs",
                section: "Skills", insertText: "/pr-sweep"),
        ]
        Self.shoot("composer-slash-palette", width: 460, height: 230) {
            AinkradComposerOverlayList(
                trigger: .command(query: "re"), suggestions: rows, selectedIndex: 0, usesPaletteRows: true,
                onSelect: { _ in }
            )
            .frame(width: 420)
        }
    }

    @Test func labelledSend() {
        Self.shoot("composer-labelled-send", width: 460, height: 170) {
            AinkradComposer(
                text: .constant("Make the selection capsule animate in with the motion budget"),
                placeholder: "Ask", isEditable: true, canSend: true, autoFocus: false,
                suggestions: { _ in [] }, onPick: { _, _ in }, onDrop: nil, onSend: {},
                chips: { EmptyView() }, leading: { Text("Grimoire · this workspace").font(.caption) },
                trailing: { Text("Esc").font(.caption) }
            )
            .sendTitle("Ask ⌘↵")
            .frame(width: 420)
        }
    }
}
