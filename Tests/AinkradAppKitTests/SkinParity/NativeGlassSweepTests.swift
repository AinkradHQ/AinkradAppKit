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
        // AINKRAD_FONTS_DIR (the host's Resources/Fonts) draws the kit's JetBrains Mono as the app does.
        if let fonts = env["AINKRAD_FONTS_DIR"] {
            for file in try FileManager.default.contentsOfDirectory(atPath: fonts) where file.hasSuffix(".ttf") {
                let url = URL(fileURLWithPath: fonts).appendingPathComponent(file)
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        // AINKRAD_SWEEP_ONLY=button,toggle shoots only fixtures with those name prefixes.
        let only = env["AINKRAD_SWEEP_ONLY"]?.split(separator: ",").map(String.init) ?? []
        for fixture in SkinParityFixtures.allFixtures + Self.panelFixtures
            + SkinParityFixturesCitadelKit.interactionFixtures
        where only.isEmpty || only.contains(where: { fixture.name.hasPrefix($0) }) {
            for (name, skin) in [("neon", AinkradSkin.standard), ("glass", glass)] {
                let size = fixture.sweepSize
                let view = fixture.view
                    .padding(16)
                    .frame(width: size.width, height: size.height)
                    .background(skin.color(skin.palette.background))
                    .ainkradSkin(skin)
                    .environment(\.colorScheme, .dark)
                try LiveGlassCapture.shoot(
                    view, size: size, interaction: fixture.interaction,
                    background: NSColor(skin.color(skin.palette.background)),
                    to: URL(fileURLWithPath: out).appendingPathComponent("\(fixture.name)-\(name).png"))
            }
        }
    }

    /// Open picker panels, which the parity fixtures (closed triggers) never show.
    static var panelFixtures: [SkinParityFixture] {
        let colours = ["Blue", "Green", "Orange", "Purple"]
        let busyBackdrop = ZStack {
            Circle().fill(.orange).frame(width: 120).offset(x: -90, y: -20)
            Circle().fill(.pink).frame(width: 90).offset(x: 80, y: 30)
            Text("Content behind the glass").font(.title2.bold()).foregroundStyle(.white)
        }
        return [
            SkinParityFixture(
                name: "panel-overContent",
                view: AnyView(
                    busyBackdrop.overlay {
                        AinkradPanel { Text("Glass panel").padding(24) }
                    })),
            SkinParityFixture(
                name: "panel-overlayChrome",
                view: AnyView(
                    busyBackdrop.overlay {
                        Text("Overlay chrome").padding(32).ainkradOverlayChrome(blending: .withinWindow)
                    })),
            SkinParityFixture(
                name: "panel-menuButtonRichLabel",
                view: AnyView(
                    AinkradMenuButton(items: [AinkradMenuItem(title: "Docker", action: {})]) {
                        HStack(spacing: 6) {
                            Circle().fill(.green).frame(width: 8, height: 8)
                            Text("Docker")
                            Image(systemName: "chevron.down").imageScale(.small)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.quaternary, in: .capsule)
                    })),
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

    static func shoot(
        _ view: some View, size: CGSize, interaction: SweepInteraction? = nil, background: NSColor? = nil,
        to url: URL
    ) throws {
        let panel = KeyAppearancePanel(
            contentRect: NSRect(origin: CGPoint(x: 200, y: 200), size: size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.hasShadow = false
        // No fade-in: a shot taken mid-fade comes out washed-out grey.
        panel.animationBehavior = .none
        panel.contentView = NSHostingView(
            rootView:
                view
                .environment(\.ainkradMotionBudget, .frozen)
                .environment(\.controlActiveState, .key)
                .frame(width: size.width, height: size.height))
        let before = Set(NSApp.windows.map(\.windowNumber))
        panel.orderFrontRegardless()
        defer { panel.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.35))
        if let interaction {
            perform(interaction, in: panel)
            RunLoop.main.run(until: Date().addingTimeInterval(0.6))
        }

        // `screencapture -l` takes the window with its child windows, so a
        // floating panel the interaction opened is in the same shot.
        // Now and then the window server hands back a washed-out frame (the
        // window mid-composite): its corner is not the fixture's background.
        // Shoot again until it is, at most three times.
        for attempt in 1...3 {
            try capture(panel.windowNumber, to: url)
            guard let background, attempt < 3, !cornerMatches(url, background) else { break }
            RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        }
        for window in NSApp.windows where window.isVisible && !before.contains(window.windowNumber) {
            window.orderOut(nil)
        }
    }

    /// Whether the shot's top-left pixel is `expected`, within a small tolerance.
    private static func cornerMatches(_ url: URL, _ expected: NSColor) -> Bool {
        guard let rep = NSBitmapImageRep(data: (try? Data(contentsOf: url)) ?? Data()),
            let corner = rep.colorAt(x: 2, y: 2)?.usingColorSpace(.sRGB),
            let want = expected.usingColorSpace(.sRGB)
        else { return true }
        let delta =
            [
                corner.redComponent - want.redComponent, corner.greenComponent - want.greenComponent,
                corner.blueComponent - want.blueComponent,
            ].map(abs).max() ?? 0
        return delta < 0.08
    }

    private static func capture(_ windowNumber: Int, to url: URL) throws {
        let capture = Process()
        capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        capture.arguments = ["-x", "-o", "-l", String(windowNumber), url.path]
        try capture.run()
        capture.waitUntilExit()
        #expect(capture.terminationStatus == 0, "screencapture failed for \(url.lastPathComponent)")
    }

    /// Hover: a mouse-moved event, then mouse-entered to every tracking area
    /// under the point, carrying that area (the window server sends those only
    /// for the real cursor, so the user's cursor is never moved). Click: mouse down and up. `point` is in window points, top-left origin.
    private static func perform(_ interaction: SweepInteraction, in window: NSWindow) {
        guard let root = window.contentView else { return }
        let point: CGPoint
        switch interaction {
        case .hover(let p), .click(let p): point = p
        }
        let location = NSPoint(x: point.x, y: root.bounds.height - point.y)
        func event(_ type: NSEvent.EventType) -> NSEvent? {
            NSEvent.mouseEvent(
                with: type, location: location, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
        }
        switch interaction {
        case .hover:
            window.acceptsMouseMovedEvents = true
            if let moved = event(.mouseMoved) { window.sendEvent(moved) }
            var views = [root]
            while let view = views.popLast() {
                views += view.subviews
                for area in view.trackingAreas where area.rect.contains(view.convert(location, from: nil)) {
                    if let entered = NSEvent.enterExitEvent(
                        with: .mouseEntered, location: location, modifierFlags: [],
                        timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                        context: nil, eventNumber: 0, trackingNumber: unsafeBitCast(area, to: Int.self), userData: nil)
                    {
                        (area.owner as? NSResponder)?.mouseEntered(with: entered)
                        if let moved = event(.mouseMoved) { (area.owner as? NSResponder)?.mouseMoved(with: moved) }
                    }
                }
            }
            if let moved = event(.mouseMoved) { window.sendEvent(moved) }
        case .click:
            if let down = event(.leftMouseDown) { window.sendEvent(down) }
            if let up = event(.leftMouseUp) { window.sendEvent(up) }
        }
    }
}
