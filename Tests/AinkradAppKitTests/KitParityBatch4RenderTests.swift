import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Off-screen Neon renders of the parity batch 4 styles, for comparing by eye
/// against `Designs/forge` and `Designs/grimoire`. Each one must render; the
/// PNGs are written only when AINKRAD_KIT4_SHOTS names a directory. Glass
/// cannot be drawn off-screen (see `NativeGlassSweepTests`): the same
/// `fixtures` can be shot on real glass with `LiveGlassCapture`.
@Suite("Kit parity batch 4 renders")
@MainActor
struct KitParityBatch4RenderTests {
    typealias Fixture = KitParityBatch3RenderTests.Fixture

    static func fixture(_ name: String, _ width: CGFloat, _ height: CGFloat, @ViewBuilder _ view: () -> some View)
        -> Fixture
    {
        KitParityBatch3RenderTests.fixture(name, width, height, view)
    }

    static func composer(text: String) -> AinkradComposer<EmptyView, Text, Text> {
        KitParityBatch3RenderTests.composer(text: text)
    }

    static var fixtures: [Fixture] {
        [
            fixture("composer-text-field-dimmed", 480, 250) {
                VStack(spacing: 12) {
                    composer(text: "Now screenshot both themes and attach them to the PR.").textFieldDimmed(true)
                    composer(text: "Now screenshot both themes and attach them to the PR.")
                }
                .frame(width: 440)
            }
        ]
    }

    static func render(_ view: some View, width: CGFloat, height: CGFloat) -> NSBitmapImageRep? {
        SkinParityRenderer.render(
            KitParityBatch3RenderTests.framed(
                Fixture(name: "", size: CGSize(width: width, height: height), view: AnyView(view)), skin: .standard),
            width: width, height: height)
    }

    /// Whether any pixel differs between `lhs` and `rhs` in rows `rows` (points).
    static func differs(_ lhs: NSBitmapImageRep, _ rhs: NSBitmapImageRep, rows: Range<Int>) -> Bool {
        let scale = lhs.pixelsHigh / Int(lhs.size.height)
        for y in (rows.lowerBound * scale)..<(rows.upperBound * scale) {
            for x in 0..<lhs.pixelsWide where lhs.colorAt(x: x, y: y) != rhs.colorAt(x: x, y: y) { return true }
        }
        return false
    }

    @Test("a dimmed text field leaves the strip untouched")
    func dimmedFieldOnly() throws {
        let text = "Now screenshot both themes and attach them to the PR."
        let plain = try #require(Self.render(Self.composer(text: text).frame(width: 440), width: 480, height: 130))
        let dimmed = try #require(
            Self.render(Self.composer(text: text).textFieldDimmed(true).frame(width: 440), width: 480, height: 130))
        // Composer from y 16: 10 pt padding, the 34 pt field, 8 pt gap, the 30 pt strip.
        #expect(Self.differs(plain, dimmed, rows: 28..<58))
        #expect(!Self.differs(plain, dimmed, rows: 70..<96))
    }

    @Test func rendersEveryFixture() {
        let dir = ProcessInfo.processInfo.environment["AINKRAD_KIT4_SHOTS"]
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
