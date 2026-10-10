import Foundation
import Testing

@testable import AinkradAppKitUI

/// Glass Native E0.1: the one switch every kit component reads.
@Suite("NativeGlassSwitchTests")
@MainActor
struct NativeGlassSwitchTests {
    @Test("only the glass material goes native")
    func kinds() {
        #expect(ainkradUsesNativeGlass(materialKind: "glass"))
        #expect(!ainkradUsesNativeGlass(materialKind: "blur"))
        #expect(!ainkradUsesNativeGlass(materialKind: "solid"))
        #expect(!ainkradUsesNativeGlass(materialKind: "unknown"))
    }

    @Test("Neon's standard skin stays on the kit's own rendering")
    func standardIsNotNative() {
        #expect(!AinkradSkin.standard.usesNativeGlass)
    }

    @Test("a theme file with glass material goes native")
    func glassThemeIsNative() throws {
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        let json = #"{"schemaVersion":1,"id":"g","name":"G","base":"neonBlue","material":{"kind":"glass"}}"#
        let result = ainkradLoadThemes([base, Data(json.utf8)])
        let skin = try #require(result.themes["g"]).skin
        #expect(result.issues.isEmpty)
        #expect(skin.usesNativeGlass)
    }
}
