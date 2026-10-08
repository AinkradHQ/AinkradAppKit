import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// Kit panels fill at the skin's `material.panelOpacity`, so a `solid` theme can be opaque.
/// Precedence: host `ainkradSurfaceOpacity` > caller `backgroundOpacity` > skin.
/// `@MainActor`: decoding the giant `AinkradSkin` overflows a 512 KiB worker stack in Debug.
@Suite("PanelOpacityFromSkinTests")
@MainActor
struct PanelOpacityFromSkinTests {
    /// The panel and the modifier (Modal, ConfirmDialog, Drawer, ContextMenu route through it).
    static func surfaces(_ opacity: Double?) -> [AnyView] {
        guard let opacity else {
            return [
                AnyView(AinkradPanel { Text("Panel").padding(40) }),
                AnyView(Text("Panel").padding(40).ainkradPanel()),
            ]
        }
        return [
            AnyView(AinkradPanel(backgroundOpacity: opacity) { Text("Panel").padding(40) }),
            AnyView(Text("Panel").padding(40).ainkradPanel(backgroundOpacity: opacity)),
        ]
    }

    static func solid(panelOpacity: Double) throws -> AinkradSkin {
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        let json =
            #"{"schemaVersion":1,"id":"s","name":"S","base":"neonBlue","material":{"kind":"solid","panelOpacity":\#(panelOpacity)}}"#
        let result = ainkradLoadThemes([base, Data(json.utf8)])
        #expect(result.issues.isEmpty)
        return try #require(result.themes["s"]).skin
    }

    static func png(_ view: AnyView, skin: AinkradSkin, surface: Double? = nil) throws -> Data {
        try KitShapesFollowLanguageTests.png(
            view.environment(\.ainkradSkinStorage, skin).environment(\.ainkradSurfaceOpacity, surface))
    }

    @Test("standard renders identically to the old explicit 0.94")
    func standardUnchanged() throws {
        for (implicit, explicit) in zip(Self.surfaces(nil), Self.surfaces(0.94)) {
            #expect(try Self.png(implicit, skin: .standard) == Self.png(explicit, skin: .standard))
        }
    }

    @Test("solid + panelOpacity 1 gives an opaque panel")
    func solidIsOpaque() throws {
        let solid = try Self.solid(panelOpacity: 1)
        for (implicit, (opaque, translucent)) in zip(
            Self.surfaces(nil), zip(Self.surfaces(1), Self.surfaces(0.94)))
        {
            let png = try Self.png(implicit, skin: solid)
            #expect(png == (try Self.png(opaque, skin: solid)))
            #expect(png != (try Self.png(translucent, skin: solid)))
        }
    }

    @Test("an explicit backgroundOpacity wins over the skin")
    func explicitWins() throws {
        let solid1 = try Self.solid(panelOpacity: 1)
        let solid094 = try Self.solid(panelOpacity: 0.94)
        for (implicit, explicit) in zip(Self.surfaces(nil), Self.surfaces(0.94)) {
            #expect(try Self.png(explicit, skin: solid1) == Self.png(implicit, skin: solid094))
        }
    }

    @Test("the host surface opacity wins over the caller and the skin")
    func hostWins() throws {
        let solid1 = try Self.solid(panelOpacity: 1)
        let solid094 = try Self.solid(panelOpacity: 0.94)
        for (implicit, explicit) in zip(Self.surfaces(nil), Self.surfaces(0.3)) {
            let reference = try Self.png(implicit, skin: solid094, surface: 0.6)
            #expect(try Self.png(implicit, skin: solid1, surface: 0.6) == reference)
            #expect(try Self.png(explicit, skin: solid1, surface: 0.6) == reference)
        }
    }
}
