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
}
