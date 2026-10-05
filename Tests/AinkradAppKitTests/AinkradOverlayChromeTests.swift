import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradOverlayChrome")
struct AinkradOverlayChromeTests {
    @Test("the standard skin carries the host overlay values")
    func tokens() {
        let o = AinkradSkin.standard.chrome.overlay
        #expect(o.backgroundOpacity == 0.94)
        #expect(o.edgeWidth == 1)
        #expect(AinkradSkin.standard.material.blurEnabled)
    }

    @Test("the tokenless overload renders as the explicit one with the token values")
    @MainActor
    func tokenlessMatchesExplicit() throws {
        let c = Text("Overlay").padding(40)
        let a = SkinParityRenderer.render(c.ainkradOverlayChrome(blending: .withinWindow))?
            .representation(using: .png, properties: [:])
        let b = SkinParityRenderer.render(
            c.ainkradOverlayChrome(backgroundOpacity: 0.94, blurEnabled: true, blending: .withinWindow))?
            .representation(using: .png, properties: [:])
        #expect(a != nil)
        #expect(a == b)
    }
}
