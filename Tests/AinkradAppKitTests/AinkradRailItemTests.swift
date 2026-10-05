import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradRailItem")
struct AinkradRailItemTests {
    @Test("badge text: none for 0, the count up to 99, then 99+")
    func badgeText() {
        #expect(ainkradRailBadgeText(0) == nil)
        #expect(ainkradRailBadgeText(7) == "7")
        #expect(ainkradRailBadgeText(99) == "99")
        #expect(ainkradRailBadgeText(100) == "99+")
    }

    @Test("both call shapes construct, with and without an action")
    @MainActor
    func constructs() {
        @Namespace var ns
        _ = AinkradRailItem(systemName: "bolt", help: "Bolt", isSelected: false, action: nil)
        _ = AinkradRailItem(systemName: "bolt", help: "Bolt", isSelected: true, unread: 3, action: {})
        _ = AinkradRailItem(
            systemName: "bolt", help: "Bolt", isSelected: false, isDimmed: true, cornerSymbol: "bell.slash.fill",
            selectionNamespace: ns, action: {})
    }

    @Test("the tile is one token-sized square tall")
    @MainActor
    func frameSize() {
        let size = AinkradSkin.standard.components.railItem.size
        let host = NSHostingView(
            rootView: AinkradRailItem(systemName: "bolt", help: "Bolt", isSelected: false, action: nil)
                .frame(width: 60))
        #expect(host.fittingSize.height == CGFloat(size))
    }

    @Test("standard tokens equal the Whisper tile's values")
    func standardTokens() {
        let tile = AinkradSkin.standard.components.railItem
        #expect(tile.size == 42)
        #expect(tile.shape == AinkradShapeToken(style: "chamfer", cut: 7))
        #expect(tile.fill.resolve([.selected]) == .palette("accentPrimary", 0.18))
        #expect(tile.fill.resolve([.hover]) == .palette("surfaceElevated", 0.6))
        #expect(tile.fill.resolve([]) == .clear)
        #expect(tile.glyphColor.resolve([]) == .palette("foreground", 0.65))
        #expect(tile.glyphColor.resolve([.hover]) == .palette("foreground", 0.9))
        #expect(tile.glyphDimmedColor == .palette("foreground", 0.45))
        #expect(tile.glyphColor.resolve([.selected, .hover]) == .palette("accentSecondary", 1.0))
        #expect(tile.hoverScale == 1.06)
        #expect(tile.badgeOpacity.resolve([.hover]) == 0.45)
        #expect(tile.edgeHeight.resolve([.selected]) == 22)
        #expect(tile.edgeHeight.resolve([.hover]) == 10)
        #expect(tile.edgeHeight.resolve([]) == 0)
    }

    @Test("the tokens survive a JSON round trip")
    func tokensRoundTrip() throws {
        let tokens = AinkradSkin.standard.components
        let decoded = try JSONDecoder().decode(AinkradComponentTokens.self, from: JSONEncoder().encode(tokens))
        #expect(decoded.railItem == tokens.railItem)
    }
}
