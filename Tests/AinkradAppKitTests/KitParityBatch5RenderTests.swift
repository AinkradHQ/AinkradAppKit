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
        ]
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
