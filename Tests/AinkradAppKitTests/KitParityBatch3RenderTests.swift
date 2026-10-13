import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Off-screen Neon renders of the parity batch 3 styles, for comparing by eye
/// against `Designs/forge` and `Designs/grimoire`. Each one must render; the
/// PNGs are written only when AINKRAD_KIT3_SHOTS names a directory. Glass
/// cannot be drawn off-screen (see `NativeGlassSweepTests`): the same
/// `fixtures` can be shot on real glass with `LiveGlassCapture`.
@Suite("Kit parity batch 3 renders")
@MainActor
struct KitParityBatch3RenderTests {
    struct Fixture {
        let name: String
        let size: CGSize
        let view: AnyView
    }

    static func fixture(_ name: String, _ width: CGFloat, _ height: CGFloat, @ViewBuilder _ view: () -> some View)
        -> Fixture
    {
        Fixture(name: name, size: CGSize(width: width, height: height), view: AnyView(view()))
    }

    static var fixtures: [Fixture] {
        [
            fixture("button-full-width", 360, 110) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        AinkradButton(title: "Revert selected", style: .secondary) {}.fullWidth().secondaryAccent()
                        AinkradButton(title: "Send 1 comment", style: .secondary) {}.fullWidth().secondaryAccent()
                    }
                    HStack(spacing: 8) {
                        AinkradButton(title: "Commit", style: .primary) {}.fullWidth()
                        AinkradButton(title: "Commit & open PR", style: .secondary) {}.fullWidth().secondaryAccent()
                    }
                }
            },
            fixture("button-outlined-danger", 360, 70) {
                HStack(spacing: 8) {
                    AinkradButton(title: "■ Stop", style: .danger) {}.outlined()
                    AinkradButton(title: "Stop", style: .danger) {}
                    AinkradButton(title: "Primary", style: .primary) {}.outlined()
                }
            },
            fixture("button-compact", 420, 70) {
                HStack(spacing: 8) {
                    AinkradButton(title: "Replace All", style: .primary) {}.compact()
                    AinkradButton(title: "Revert", style: .secondary) {}.compact().secondaryAccent()
                    AinkradButton(title: "Stage", style: .secondary) {}.compact().secondaryAccent()
                    AinkradButton(title: "Replace All", style: .primary) {}
                }
            },
            fixture("composer-busy-stop-queue", 480, 250) {
                VStack(spacing: 12) {
                    composer(text: "Run the ABI check again on Xcode beta").sendGlyph("↵").stopButton("■ Stop") {}
                    composer(text: "").stopButton("■ Stop", action: nil)
                }
                .frame(width: 440)
            },
            fixture("empty-state-glyph", 640, 280) {
                HStack(spacing: 0) {
                    AinkradEmptyState(
                        icon: "books.vertical", title: "No threads yet",
                        message: "Open a project folder and start a thread — or keep using the terminal;",
                        actionTitle: "New thread ⌘N", action: {}
                    )
                    .secondaryAction("Open folder…") {}
                    .glyph("❖").iconTint(AinkradSkin.standard.color(AinkradSkin.standard.palette.accentSecondary))
                    AinkradEmptyState(icon: "hammer", title: "No file open", message: "⌘P open a file")
                        .glyph("⚒").iconTint(AinkradSkin.standard.color(AinkradSkin.standard.palette.accentSecondary))
                }
            },
            fixture("decision-bar-detail-glyph", 800, 90) {
                AinkradDecisionBar(
                    icon: "terminal", iconTint: .secondary, caption: "Approval required",
                    title: "Run git push -u origin feat/glass-sidebar",
                    actions: [
                        AinkradDecisionBar.Action(title: "Deny…", style: .ghost) {}.borderless().secondaryAccent(),
                        AinkradDecisionBar.Action(title: "Always allow", style: .secondary) {}.secondaryAccent()
                            .detail("git push *"),
                        AinkradDecisionBar.Action(title: "Allow once ↵", style: .primary) {},
                    ]
                )
                .labelCasedCaption()
                .iconGlyph("⌁")
            },
        ]
    }

    static func composer(text: String) -> AinkradComposer<EmptyView, Text, Text> {
        AinkradComposer(
            text: .constant(text), placeholder: "Message Claude… (/ for commands, @ for files)", isEditable: true,
            canSend: true, autoFocus: false, suggestions: { _ in [] }, onPick: { _, _ in }, onDrop: nil,
            onSend: {}, chips: { EmptyView() }, leading: { Text("MODE Ask") }, trailing: { Text("📎") })
    }

    /// The fixture on the Neon background, as both the off-screen and the
    /// live-glass shots frame it.
    static func framed(_ fixture: Fixture, skin: AinkradSkin) -> some View {
        fixture.view
            .padding(16)
            .frame(width: fixture.size.width, height: fixture.size.height, alignment: .topLeading)
            .background(skin.color(skin.palette.background))
            .ainkradSkin(skin)
            .environment(\.colorScheme, .dark)
    }

    @Test func rendersEveryFixture() {
        let dir = ProcessInfo.processInfo.environment["AINKRAD_KIT3_SHOTS"]
        for fixture in Self.fixtures {
            let rep = SkinParityRenderer.render(
                Self.framed(fixture, skin: .standard), width: fixture.size.width, height: fixture.size.height)
            #expect(rep != nil, "\(fixture.name) did not render")
            guard let dir, let rep, let png = rep.representation(using: .png, properties: [:]) else { continue }
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(fixture.name).png"))
        }
    }
}
