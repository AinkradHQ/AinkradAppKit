import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// E1.3: AppKit's own direct shapes follow `shape.style`. Under `standard` they stay
/// byte-identical (the SkinParity goldens); under `continuous` the outline changes.
/// `@MainActor`: decoding the giant `AinkradSkin` overflows a 512 KiB worker stack in Debug.
@Suite("KitShapesFollowLanguageTests")
@MainActor
struct KitShapesFollowLanguageTests {
    @Test("AinkradPanel, .ainkradOverlayChrome and .ainkradEdgeRing render rounded under continuous")
    func directShapesFollowLanguage() throws {
        let continuous = try ShapeLanguageTests.load(style: "continuous").skin
        let views: [(String, AnyView)] = [
            ("panel", AnyView(AinkradPanel { Text("Panel").padding(40) })),
            (
                "overlayChrome",
                AnyView(
                    Text("Overlay").padding(40)
                        .ainkradOverlayChrome(backgroundOpacity: 0.94, blurEnabled: false, blending: .withinWindow))
            ),
            ("edgeRing", AnyView(Text("Ring").padding(40).ainkradEdgeRing())),
        ]
        for (name, view) in views {
            let standard = try Self.png(view)
            let rounded = try Self.png(view.environment(\.ainkradSkinStorage, continuous))
            #expect(standard != rounded, "\(name) ignores shape.style continuous")
        }
    }

    static func png<V: View>(_ view: V) throws -> Data {
        let rep = try #require(SkinParityRenderer.render(view))
        return try #require(rep.representation(using: .png, properties: [:]))
    }
}
