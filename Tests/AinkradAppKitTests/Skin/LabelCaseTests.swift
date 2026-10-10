import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// E5.3: `type.labelCase` makes Neon's uppercase kit labels a token.
@Suite("LabelCaseTests")
@MainActor
struct LabelCaseTests {
    @Test("standard uppercases, as before")
    func standardIsUpper() {
        #expect(AinkradSkin.standard.type.labelCase == "upper")
        #expect(AinkradSkin.standard.labelCased("Deny") == "DENY")
        #expect(AinkradSkin.standard.labelTextCase == .uppercase)
    }

    @Test("a theme file with labelCase none leaves labels as written")
    func noneLoads() throws {
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        let json = #"{"schemaVersion":1,"id":"calm","name":"C","base":"neonBlue","type":{"labelCase":"none"}}"#
        let result = ainkradLoadThemes([base, Data(json.utf8)])
        let skin = try #require(result.themes["calm"]).skin
        #expect(result.issues.isEmpty)
        #expect(skin.labelCased("Deny") == "Deny")
        #expect(skin.labelTextCase == nil)
    }

    @Test("a file written before the token keeps the caps")
    func olderFileIsUpper() throws {
        var dict = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(AinkradSkin.standard)) as? [String: Any])
        var type = try #require(dict["type"] as? [String: Any])
        #expect(type.removeValue(forKey: "labelCase") != nil)
        dict["type"] = type
        let skin = try AinkradThemeFile(decoding: JSONSerialization.data(withJSONObject: dict)).skin
        #expect(skin.labelCased("Deny") == "DENY")
    }
}
