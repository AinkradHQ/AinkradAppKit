import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Off-screen Neon renders of the parity batch 6 styles, for comparing by eye
/// against `Designs/forge`. Each one must render; the PNGs are written only
/// when AINKRAD_KIT6_SHOTS names a directory. Glass cannot be drawn
/// off-screen (see `NativeGlassSweepTests`): the same `fixtures` can be shot
/// on real glass with `LiveGlassCapture`.
@Suite("Kit parity batch 6 renders")
@MainActor
struct KitParityBatch6RenderTests {
    typealias Fixture = KitParityBatch3RenderTests.Fixture

    static func fixture(_ name: String, _ width: CGFloat, _ height: CGFloat, @ViewBuilder _ view: () -> some View)
        -> Fixture
    {
        KitParityBatch3RenderTests.fixture(name, width, height, view)
    }

    static var fixtures: [Fixture] {
        [
            fixture("button-height", 300, 190) {
                VStack(alignment: .leading, spacing: 8) {
                    replaceField { KitParityBatch6Tests.replaceAll.buttonHeight(30) }.fieldHeight(42)
                    replaceField { KitParityBatch6Tests.replaceAll.buttonHeight(30) }
                    replaceField { KitParityBatch6Tests.replaceAll }
                }
                .frame(width: 256)
            },
            fixture("text-field-monospaced", 360, 110) {
                VStack(alignment: .leading, spacing: 8) {
                    KitParityBatch6Tests.renameField.fieldHeight(28).chamfered().monospaced()
                    KitParityBatch6Tests.renameField.fieldHeight(28).chamfered()
                }
                .frame(width: 314)
            },
        ]
    }

    /// Mockup 08's replace field round `button` (42 pt tall there).
    static func replaceField(@ViewBuilder _ button: () -> some View) -> AinkradSearchField {
        let button = button()
        return AinkradSearchField(text: .constant("isActive"), placeholder: "Replace").codeQuery().chamfered()
            .trailingAccessory {
                AinkradFieldToggle("AB", isOn: .constant(false), help: "Preserve case")
                button.fixedSize()
            }
    }

    @Test func rendersEveryFixture() {
        let dir = ProcessInfo.processInfo.environment["AINKRAD_KIT6_SHOTS"]
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
