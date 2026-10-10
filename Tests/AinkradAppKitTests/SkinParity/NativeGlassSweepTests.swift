import AppKit
import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Glass Native sweep: every skin-parity fixture rendered under the standard
/// skin and under the catalog's Glass theme + scheme, written as
/// `<dir>/<fixture>-neon.png` / `-glass.png`. A tool, not a check: it runs only
/// with AINKRAD_SWEEP_DIR and AINKRAD_THEMES_DIR (the catalog's `themes/`) set;
/// AINKRAD_SWEEP_ONLY narrows it to fixture-name prefixes.
@Suite("NativeGlassSweepTests")
@MainActor
struct NativeGlassSweepTests {
    @Test("shoot every fixture under Neon and Glass")
    func shoot() throws {
        let env = ProcessInfo.processInfo.environment
        guard let out = env["AINKRAD_SWEEP_DIR"], let themes = env["AINKRAD_THEMES_DIR"] else {
            print("SKIPPED: set AINKRAD_SWEEP_DIR and AINKRAD_THEMES_DIR — no native Glass sweep")
            return
        }
        let glass = try Self.glassSkin(themes: URL(fileURLWithPath: themes))
        #expect(glass.usesNativeGlass)
        try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
        // AINKRAD_SWEEP_ONLY=button,toggle shoots only fixtures with those name prefixes.
        let only = env["AINKRAD_SWEEP_ONLY"]?.split(separator: ",").map(String.init) ?? []
        for fixture in SkinParityFixtures.allFixtures + Self.panelFixtures
        where only.isEmpty || only.contains(where: { fixture.name.hasPrefix($0) }) {
            for (name, skin) in [("neon", AinkradSkin.standard), ("glass", glass)] {
                let view = fixture.view
                    .padding(16)
                    .frame(width: 400, height: 200)
                    .background(skin.color(skin.palette.background))
                    .ainkradSkin(skin)
                    .environment(\.colorScheme, .dark)
                try LiveGlassCapture.shoot(
                    view, size: CGSize(width: 400, height: 200),
                    to: URL(fileURLWithPath: out).appendingPathComponent("\(fixture.name)-\(name).png"))
            }
        }
    }

    /// Open picker panels, which the parity fixtures (closed triggers) never show.
    static var panelFixtures: [SkinParityFixture] {
        let colours = ["Blue", "Green", "Orange", "Purple"]
        return [
            SkinParityFixture(
                name: "panel-select",
                view: AnyView(
                    SearchableSelectPanelView(
                        items: colours, selection: .constant("Green"), label: { $0 }, placeholder: "Search…",
                        onClose: {}))),
            SkinParityFixture(
                name: "panel-multiSelect",
                view: AnyView(
                    MultiSelectPanelView(items: colours, selection: .constant(["Blue", "Orange"]), label: { $0 }))),
            SkinParityFixture(
                name: "panel-groupedSelect",
                view: AnyView(
                    GroupedSelectPanelView(
                        sections: [
                            AinkradGroupedSection(
                                header: "Models",
                                rows: [
                                    AinkradGroupedRow(value: "a", title: "Opus", detail: "1M", icon: "sparkles"),
                                    AinkradGroupedRow(value: "b", title: "Sonnet", detail: "200K"),
                                    AinkradGroupedRow(value: "c", title: "Offline", isEnabled: false),
                                ])
                        ], selection: .constant("b"), placeholder: "Search…", onClose: {}))),
        ]
    }

    /// `glass-dark.theme` on the standard skin, coloured by `glass-dark.scheme`,
    /// composed the way the host's `ThemeCatalog.compose` does.
    static func glassSkin(themes: URL) throws -> AinkradSkin {
        let dir = themes.appendingPathComponent("glass")
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        let theme = try Data(contentsOf: dir.appendingPathComponent("glass-dark.theme"))
        let loaded = ainkradLoadThemes([base, theme])
        let variant = try #require(loaded.themes["glass.dark"])
        var scheme = try #require(
            JSONSerialization.jsonObject(with: Data(contentsOf: dir.appendingPathComponent("glass-dark.scheme")))
                as? [String: Any])
        scheme.removeValue(forKey: "appearance")
        scheme.removeValue(forKey: "host")
        scheme["base"] = "glass.dark"
        let data = try JSONSerialization.data(withJSONObject: scheme)
        return try AinkradThemeFile(decoding: data, bases: ["glass.dark": variant]).skin
    }
}

/// Off-screen `cacheDisplay` cannot draw Liquid Glass (the window server
/// composites it), so the sweep shows each fixture in a real window at desktop
/// level, behind every other window: nothing flashes and no focus is taken.
/// `screencapture -l` grabs that window alone. The window claims key/active
/// appearance so controls and glass tints render as in a focused app.
@MainActor
enum LiveGlassCapture {
    private final class KeyAppearancePanel: NSPanel {
        override var isKeyWindow: Bool { true }
        override var isMainWindow: Bool { true }
        override var canBecomeKey: Bool { false }
        @objc var hasKeyAppearance: Bool { true }
        @objc var hasMainAppearance: Bool { true }
        @objc var _hasActiveAppearance: Bool { true }
        @objc var _hasActiveAppearanceIgnoringKeyFocus: Bool { true }
    }

    static func shoot(_ view: some View, size: CGSize, to url: URL) throws {
        let panel = KeyAppearancePanel(
            contentRect: NSRect(origin: CGPoint(x: 200, y: 200), size: size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.hasShadow = false
        panel.contentView = NSHostingView(
            rootView:
                view
                .environment(\.ainkradMotionBudget, .frozen)
                .environment(\.controlActiveState, .key)
                .frame(width: size.width, height: size.height))
        panel.orderFrontRegardless()
        defer { panel.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.35))

        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        capture.arguments = ["-x", "-o", "-l", String(panel.windowNumber), url.path]
        try capture.run()
        capture.waitUntilExit()
        #expect(capture.terminationStatus == 0, "screencapture failed for \(url.lastPathComponent)")
    }
}
