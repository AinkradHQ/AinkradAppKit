import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Off-screen Neon renders of the parity batch 5 styles, for comparing by eye
/// against `Designs/forge`. Each one must render; the PNGs are written only
/// when AINKRAD_KIT5_SHOTS names a directory. Glass cannot be drawn
/// off-screen (see `NativeGlassSweepTests`): the same `fixtures` can be shot
/// on real glass with `LiveGlassCapture`.
@Suite("Kit parity batch 5 renders")
@MainActor
struct KitParityBatch5RenderTests {
    typealias Fixture = KitParityBatch3RenderTests.Fixture

    static func fixture(_ name: String, _ width: CGFloat, _ height: CGFloat, @ViewBuilder _ view: () -> some View)
        -> Fixture
    {
        KitParityBatch3RenderTests.fixture(name, width, height, view)
    }

    /// Mockup 08's preview with its second hunk unticked.
    static func preview(rejected: Set<Int>) -> AinkradDiffReview {
        AinkradDiffReview(fileDiff: KitParityBatch3RenderTests.replacePreview, rejectedHunkIDs: .constant(rejected))
            .hidesHeader().editorLines().syntaxColoured().lineNumberGutter().unchangedLineFolds()
    }

    static var fixtures: [Fixture] {
        [
            fixture("diff-bare-hunks-untickable", 640, 300) {
                preview(rejected: [1]).bareHunks(untickable: true)
            },
            fixture("diff-line-metrics", 640, 260) {
                preview(rejected: [1]).bareHunks(untickable: true).lineMetrics(fontSize: 12.5, rowHeight: 20)
            },
            fixture("text-area-font-size", 480, 170) {
                VStack(spacing: 12) {
                    AinkradTextArea(text: .constant(Self.askText), placeholder: "", minHeight: 54).fontSize(12.5)
                    AinkradTextArea(text: .constant(Self.askText), placeholder: "", minHeight: 54)
                }
                .frame(width: 440)
            },
            fixture("fields-height-chamfer", 300, 230) {
                VStack(spacing: 8) {
                    sidebarFields.chamfered()
                    AinkradSearchField(text: .constant("isActive"), placeholder: "Replace").codeQuery()
                        .fieldHeight(28).chamfered()
                    AinkradTextField(text: .constant("Sources/**, Tests/**"), placeholder: "")
                        .leadingLabel("include").compact().fieldHeight(24).chamfered()
                    AinkradTextField(text: .constant("isActive"), placeholder: "").fieldHeight(28).chamfered()
                    sidebarFields
                }
                .frame(width: 260)
            },
            fixture("empty-state-compact", 600, 300) {
                HStack(spacing: 0) {
                    folderEmpty.compact().frame(width: 280)
                    folderEmpty.frame(width: 280)
                }
            },
            fixture("kbd-command-first", 560, 150) {
                VStack(alignment: .leading, spacing: 8) {
                    palette(shortcut: "⇧⌘P").ainkradCommandFirstKeys()
                    palette(shortcut: "⇧⌘P")
                }
            },
            fixture("command-menu-glyph-size", 560, 150) {
                VStack(alignment: .leading, spacing: 8) {
                    quickOpen.iconGlyphs(tint: { _ in .orange }, size: 15)
                    quickOpen.iconGlyphs { _ in .orange }
                }
            },
        ]
    }

    /// Mockup 02's quick-open row.
    static var quickOpen: AinkradCommandMenu<String> {
        AinkradCommandMenu(
            items: ["SidebarRow.swift"], selection: .constant(nil), icon: { _ in "◆" }, label: { $0 },
            detail: { _ in "Sources/Ainkrad/Features/Sidebar" }, uppercased: false
        )
        .paletteRows()
    }

    /// A command palette row with `shortcut` as its keycaps (mockup 03).
    static func palette(shortcut: String) -> some View {
        AinkradCommandMenu(
            items: ["Show All Commands"], selection: .constant(nil), icon: { _ in "" }, label: { $0 },
            value: { _ in shortcut }, uppercased: false
        )
        .paletteRows()
        .frame(width: 520)
    }

    /// Mockup 19 A's empty Files tab.
    static var folderEmpty: AinkradEmptyState {
        AinkradEmptyState(
            icon: "folder", title: "This folder is empty",
            message: "Create a file, or drop files here to copy them in.", actionTitle: "New File ⌘N", action: {}
        )
        .secondaryAction("New Folder") {}
        .glyph("▤")
        .iconTint(AinkradSkin.standard.color(AinkradSkin.standard.palette.accentSecondary).opacity(0.7))
    }

    /// Mockup 07's search field with its toggles, 28 pt tall.
    static var sidebarFields: AinkradSearchField {
        AinkradSearchField(text: .constant("isSelected"), placeholder: "Search").codeQuery().fieldHeight(28)
            .trailingAccessory {
                AinkradFieldToggle("Aa", isOn: .constant(true), help: "Match case")
                AinkradFieldToggle("⌶", isOn: .constant(false), help: "Whole word")
                AinkradFieldToggle("✱", isOn: .constant(false), help: "Regular expression")
            }
    }

    /// Mockup 17's Ask card request.
    static let askText = "Make the selection capsule animate in with the motion budget"

    static func render(_ view: some View, width: CGFloat, height: CGFloat) -> NSBitmapImageRep? {
        KitParityBatch4RenderTests.render(view, width: width, height: height)
    }

    static func differs(_ lhs: NSBitmapImageRep, _ rhs: NSBitmapImageRep, rows: Range<Int>) -> Bool {
        KitParityBatch4RenderTests.differs(lhs, rhs, rows: rows)
    }

    @Test("an untickable bare hunk draws its tick on its first row only")
    func untickableTick() throws {
        let plain = try #require(Self.render(Self.preview(rejected: []).bareHunks(), width: 640, height: 300))
        let ticked = try #require(
            Self.render(Self.preview(rejected: []).bareHunks(untickable: true), width: 640, height: 300))
        // From y 16: the first hunk's first row, then its second row.
        #expect(Self.differs(plain, ticked, rows: 16..<30))
        #expect(!Self.differs(plain, ticked, rows: 34..<46))
    }

    /// The fitting height of `view` at 600 pt wide, in the Neon skin.
    static func fittingHeight(_ view: some View) -> CGFloat {
        let host = NSHostingView(rootView: view.frame(width: 600).ainkradSkin(.standard))
        return host.fittingSize.height
    }

    @Test("line metrics give every preview row the mockup's 20 pt")
    func lineMetricsRows() {
        // Mockup 08's preview: two hunks of four rows and a fold row between.
        let sized = Self.fittingHeight(Self.preview(rejected: []).bareHunks().lineMetrics(fontSize: 12, rowHeight: 20))
        #expect(abs(sized - 9 * 20) < 0.5)
        #expect(Self.fittingHeight(Self.preview(rejected: []).bareHunks()) < 9 * 20)
    }

    @Test("a text area's font size changes its text")
    func textAreaFontSize() throws {
        func shot(_ area: AinkradTextArea) throws -> NSBitmapImageRep {
            try #require(Self.render(area.frame(width: 440), width: 480, height: 90))
        }
        let area = AinkradTextArea(text: .constant(Self.askText), placeholder: "", minHeight: 54)
        #expect(Self.differs(try shot(area), try shot(area.fontSize(12.5)), rows: 16..<70))
    }

    @Test("a field height replaces the padding; the default stays 33")
    func fieldHeights() {
        let text = AinkradTextField(text: .constant("isActive"), placeholder: "")
        #expect(Self.fittingHeight(text) == 33)
        #expect(Self.fittingHeight(text.fieldHeight(28)) == 28)
        #expect(Self.fittingHeight(Self.sidebarFields) == 28)
    }

    @Test("a chamfered field changes only its chrome")
    func chamferedField() throws {
        func shot(_ field: AinkradTextField) throws -> NSBitmapImageRep {
            try #require(Self.render(field.frame(width: 260), width: 300, height: 70))
        }
        let field = AinkradTextField(text: .constant("isActive"), placeholder: "")
        #expect(Self.differs(try shot(field), try shot(field.chamfered()), rows: 16..<49))
        #expect(!Self.differs(try shot(field), try shot(field.chamfered()), rows: 52..<70))
    }

    @Test("a compact empty state is shorter")
    func compactEmptyState() {
        func height(_ state: AinkradEmptyState) -> CGFloat {
            NSHostingView(
                rootView: state.fixedSize(horizontal: false, vertical: true).frame(width: 280)
                    .ainkradSkin(.standard)
            ).fittingSize.height
        }
        #expect(height(Self.folderEmpty.compact()) < height(Self.folderEmpty))
    }

    @Test("command-first keycaps draw as the mockup's ⌘⇧P")
    func commandFirstKeycaps() throws {
        let apple = try #require(Self.render(Self.palette(shortcut: "⇧⌘P"), width: 560, height: 70))
        let mockup = try #require(Self.render(Self.palette(shortcut: "⌘⇧P"), width: 560, height: 70))
        let swapped = try #require(
            Self.render(Self.palette(shortcut: "⇧⌘P").ainkradCommandFirstKeys(), width: 560, height: 70))
        #expect(Self.differs(apple, mockup, rows: 0..<70))
        #expect(!Self.differs(swapped, mockup, rows: 0..<70))
    }

    @Test("a palette glyph size changes only the glyph")
    func paletteGlyphSize() throws {
        let plain = try #require(
            Self.render(Self.quickOpen.iconGlyphs { _ in .orange }.frame(width: 520), width: 560, height: 70))
        let sized = try #require(
            Self.render(
                Self.quickOpen.iconGlyphs(tint: { _ in .orange }, size: 15).frame(width: 520), width: 560, height: 70))
        #expect(Self.differs(plain, sized, rows: 16..<50))
        // The row keeps its height and the title its place: nothing differs right of the glyph column.
        #expect(!Self.differs(plain, sized, rows: 0..<70, fromX: 50))
    }

    /// Whether any pixel differs in rows `rows`, right of `fromX` (points).
    static func differs(_ lhs: NSBitmapImageRep, _ rhs: NSBitmapImageRep, rows: Range<Int>, fromX: Int) -> Bool {
        let scale = lhs.pixelsHigh / Int(lhs.size.height)
        for y in (rows.lowerBound * scale)..<(rows.upperBound * scale) {
            for x in (fromX * scale)..<lhs.pixelsWide where lhs.colorAt(x: x, y: y) != rhs.colorAt(x: x, y: y) {
                return true
            }
        }
        return false
    }

    @Test func rendersEveryFixture() {
        let dir = ProcessInfo.processInfo.environment["AINKRAD_KIT5_SHOTS"]
        for fixture in Self.fixtures {
            let rep = SkinParityRenderer.render(
                KitParityBatch3RenderTests.framed(fixture, skin: .standard), width: fixture.size.width,
                height: fixture.size.height)
            #expect(rep != nil, "\(fixture.name) did not render")
            guard let dir, let rep, let png = rep.representation(using: .png, properties: [:]) else { continue }
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(fixture.name).png"))
        }
    }
}
