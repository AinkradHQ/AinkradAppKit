import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// Decision #62: `palette.accentViolet` (subscription spend, the Lead role).
@Suite("AccentVioletTests")
@MainActor
struct AccentVioletTests {
    @Test("standard writes the key out, so a theme file may set it")
    func standardEncodesIt() throws {
        let dict = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(AinkradSkin.standard)) as? [String: Any])
        let palette = try #require(dict["palette"] as? [String: Any])
        #expect(palette["accentViolet"] as? String == "#A78BFA")
    }

    @Test("a scheme sets it and a palette reference resolves it")
    func themeSetsIt() throws {
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        let json = ##"{"schemaVersion":1,"id":"v","name":"V","base":"neonBlue","palette":{"accentViolet":"#BF5AF2"}}"##
        let result = ainkradLoadThemes([base, Data(json.utf8)])
        #expect(result.issues.isEmpty)
        let skin = try #require(result.themes["v"]).skin
        let glassViolet = AinkradColorToken.hex(0xBF / 255.0, 0x5A / 255.0, 0xF2 / 255.0, 1.0)
        #expect(skin.palette.accentViolet == glassViolet)
        #expect(skin.color(.palette("accentViolet", 1)) == skin.color(skin.palette.accentViolet))
        #expect(AinkradChartTone.accentViolet.color(skin) == skin.color(skin.palette.accentViolet))
    }

    @Test("a file written before the key gets Neon's violet")
    func olderFileBackfills() throws {
        var dict = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(AinkradSkin.standard)) as? [String: Any])
        var palette = try #require(dict["palette"] as? [String: Any])
        #expect(palette.removeValue(forKey: "accentViolet") != nil)
        dict["palette"] = palette
        let skin = try AinkradThemeFile(decoding: JSONSerialization.data(withJSONObject: dict)).skin
        #expect(skin.palette.accentViolet == AinkradSkin.standard.palette.accentViolet)
    }
}
