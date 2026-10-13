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
                    .secondaryAccent()
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
            fixture("segmented-disabled-options", 460, 110) {
                VStack(alignment: .leading, spacing: 12) {
                    AinkradSegmentedPicker(
                        items: ["Claude Code", "Codex", "OpenCode", "agy"], selection: .constant("Claude Code")
                    ) { $0 }
                    .disabledOptions { $0 != "Claude Code" }
                    AinkradSegmentedPicker(items: ["Ask", "Accept edits", "Plan"], selection: .constant("Ask")) { $0 }
                }
            },
            fixture("search-field-accessory", 320, 150) {
                VStack(spacing: 8) {
                    AinkradSearchField(text: .constant("isSelected"), placeholder: "Search")
                        .codeQuery()
                        .trailingAccessory {
                            Text("Aa").padding(.horizontal, 5).background(
                                .blue.opacity(0.4), in: .rect(cornerRadius: 4))
                            Text("⌶").foregroundStyle(.secondary)
                            Text("✱").foregroundStyle(.secondary)
                        }
                    AinkradSearchField(text: .constant("isActive"), placeholder: "Replace")
                        .codeQuery()
                        .trailingAccessory {
                            Text("AB").foregroundStyle(.secondary)
                            AinkradButton(title: "Replace All", style: .primary) {}.compact().fixedSize()
                        }
                    AinkradSearchField(text: .constant("thread"), placeholder: "Search threads")
                }
            },
            fixture("text-field-compact", 320, 160) {
                VStack(spacing: 6) {
                    AinkradTextField(text: .constant("Sources/**, Tests/**"), placeholder: "Sources/**, *.swift")
                        .leadingLabel("include").compact()
                    AinkradTextField(text: .constant(""), placeholder: ".build/**")
                        .leadingLabel("exclude").compact()
                    AinkradTextField(text: .constant("Sources/**"), placeholder: "").leadingLabel("include")
                    AinkradTextField(text: .constant("SidebarRow.swift"), placeholder: "")
                }
            },
            fixture("diff-bare-hunks", 640, 300) {
                AinkradDiffReview(fileDiff: replacePreview, rejectedHunkIDs: .constant([]))
                    .hidesHeader().editorLines().syntaxColoured().lineNumberGutter().unchangedLineFolds()
                    .bareHunks()
            },
            fixture("command-menu-glyph-icons", 560, 210) {
                AinkradCommandMenu(
                    items: ["SidebarRow.swift", "release.yml", "README.md", "Makefile"], selection: .constant(nil),
                    icon: { name in
                        name.hasSuffix(".swift") ? "◆" : name.hasSuffix(".yml") ? "≡" : name.hasSuffix(".md") ? "#" : ""
                    },
                    label: { $0 }, detail: { _ in "Sources/Ainkrad/Features/Sidebar" }, uppercased: false,
                    highlight: .constant(0)
                )
                .paletteRows()
                .iconGlyphs { name in
                    name.hasSuffix(".swift")
                        ? .orange : name.hasSuffix(".yml") ? .pink : name.hasSuffix(".md") ? .blue : nil
                }
            },
            fixture("breadcrumb-segment-colors", 620, 90) {
                VStack(alignment: .leading, spacing: 12) {
                    AinkradBreadcrumb(items: [
                        "Sources", "Ainkrad", "Features", "Sidebar", "SidebarRow.swift", "SidebarRow", "body",
                    ])
                    .preservesCase()
                    .icon(at: 4) { Text("◆").foregroundStyle(.orange) }
                    .segmentColors { index in
                        switch index {
                        case 4: AinkradSkin.standard.color(AinkradSkin.standard.palette.foreground)
                        case 5: .cyan
                        default: nil
                        }
                    }
                    AinkradBreadcrumb(items: ["Sources", "SidebarRow.swift"]).preservesCase()
                }
            },
            fixture("breadcrumb-text-separators", 620, 60) {
                AinkradBreadcrumb(
                    items: ["Sources", "Ainkrad", "Features", "Sidebar", "SidebarRow.swift", "SidebarRow", "body"]
                )
                .preservesCase()
                .textSeparators()
                .icon(at: 4) { Text("◆").foregroundStyle(.orange) }
                .segmentColors { index in
                    switch index {
                    case 4: AinkradSkin.standard.color(AinkradSkin.standard.palette.foreground)
                    case 5: .cyan
                    default: nil
                    }
                }
            },
            fixture("tabs-text", 330, 110) {
                VStack(alignment: .leading, spacing: 12) {
                    AinkradTabs(tabs: ["Files", "Changes 2", "Search", "Issues 5"], selection: .constant("Files")) {
                        $0
                    }
                    .textTabs()
                    AinkradTabs(tabs: ["Files", "Changes"], selection: .constant("Files")) { $0 }
                }
            },
            fixture("menu-item-tint", 320, 190) {
                AinkradContextMenuList(
                    items: [
                        AinkradMenuItem(title: "● sourcekit-lsp — ready") {},
                        AinkradMenuItem(title: "● ruby-lsp — not installed") {}
                            .tint(AinkradSkin.standard.color(AinkradSkin.standard.palette.warning)),
                        AinkradMenuItem(title: "Language servers settings…") {}.startingGroup(),
                        AinkradMenuItem(title: "Restart", isDestructive: true) {},
                    ], dismiss: {}
                )
                .frame(width: 260)
            },
            fixture("field-toggle", 320, 110) {
                VStack(spacing: 8) {
                    AinkradSearchField(text: .constant("isSelected"), placeholder: "Search")
                        .codeQuery()
                        .trailingAccessory {
                            AinkradFieldToggle("Aa", isOn: .constant(true), help: "Match case")
                            AinkradFieldToggle("⌶", isOn: .constant(false), help: "Whole word")
                            AinkradFieldToggle("✱", isOn: .constant(false), help: "Regular expression")
                        }
                    AinkradSearchField(text: .constant("isActive"), placeholder: "Replace")
                        .codeQuery()
                        .trailingAccessory {
                            AinkradFieldToggle("AB", isOn: .constant(false), help: "Preserve case")
                            AinkradButton(title: "Replace All", style: .primary) {}.compact().fixedSize()
                        }
                }
            },
        ]
    }

    /// Mockup 08's replace preview: lines 6–9 and 18–20, nine unchanged between.
    static var replacePreview: AinkradFileDiff {
        var old = (1...22).map { "    let line\($0) = \($0)" }
        old[5] = "    @Environment(\\.skin) private var skin"
        old[6] = "    let thread: ThreadSummary"
        old[7] = "    let isSelected: Bool"
        old[17] = "        .background {"
        old[18] = "            if isSelected { Capsule().glassEffect(.regular) }"
        old[19] = "        }"
        var new = old
        new[7] = "    let isActive: Bool"
        new[18] = "            if isActive { Capsule().glassEffect(.regular) }"
        return AinkradDiffEngine.compute(
            old: old.joined(separator: "\n"), new: new.joined(separator: "\n"), path: "SidebarRow.swift", context: 1)
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
