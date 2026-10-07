import AppKit
import Foundation
// design-lint: allow-file raw-color theme layer — compares the graph-lane tokens with the literals GitMage draws today
import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// Epic 6.0 token-gap batch: every added token defaults to the literal its call
/// site uses today, and a theme file written before the batch still loads.
@Suite("TokenGapBatchTests")
@MainActor
struct TokenGapBatchTests {
    /// The key paths the batch added, as a theme file spells them.
    static let addedPaths: [[String]] = [
        ["size", "s13"],
        ["motion", "durations", "d1_4"],
        ["type", "editor"],
        ["syntax", "callout"],
        ["colors"],
    ]

    @Test("standard carries today's literals")
    func standardValues() {
        let skin = AinkradSkin.standard
        #expect(skin.size.s13 == 13)
        #expect(skin.motion.durations.d1_4 == 1.4)
        #expect(skin.type.editor.lineHeight == 1.5)
        #expect(skin.type.editor.headingRatios == [1.80, 1.60, 1.40, 1.25, 1.125, 1.05])
        #expect(skin.type.editor.labelRatio == 0.85)
        let callout = skin.syntax.callout
        #expect(
            [
                callout.note, callout.abstract, callout.todo, callout.success,
                callout.warning, callout.failure, callout.bug, callout.example,
            ] == [210, 175, 45, 140, 30, 0, 350, 275])
        #expect(callout.onDark == AinkradSyntaxTone(saturation: 0.55, brightness: 0.95))
        #expect(callout.onLight == AinkradSyntaxTone(saturation: 0.75, brightness: 0.70))
        let lanes: [AinkradColorToken] = [
            .hex(0x61 / 255.0, 0xCC / 255.0, 0x85 / 255.0, 1.0),
            .hex(0xEB / 255.0, 0x9E / 255.0, 0x52 / 255.0, 1.0),
            .hex(0x99 / 255.0, 0x85 / 255.0, 0xEB / 255.0, 1.0),
        ]
        #expect(skin.colors.graphLanes == lanes)
    }

    @Test("graph lanes resolve to the 8-bit colours GitMage draws today")
    func graphLanesPixelIdentical() {
        let skin = AinkradSkin.standard
        let today: [Color] = [
            Color(red: 0.38, green: 0.80, blue: 0.52),
            Color(red: 0.92, green: 0.62, blue: 0.32),
            Color(red: 0.60, green: 0.52, blue: 0.92),
        ]
        for (token, literal) in zip(skin.colors.graphLanes, today) {
            #expect(Self.rgba(skin.color(token)) == Self.rgba(literal))
        }
    }

    @Test("encoding carries every added key")
    func encodingHasAddedKeys() throws {
        let dict = try Self.standardDict()
        for path in Self.addedPaths {
            #expect(Self.value(at: path, in: dict) != nil, "missing \(path.joined(separator: "."))")
        }
    }

    @Test("a theme file written before the batch decodes, with today's values")
    func preBatchFileDecodes() throws {
        var dict = try Self.standardDict()
        for path in Self.addedPaths { Self.remove(path, from: &dict) }
        for path in Self.addedPaths { #expect(Self.value(at: path, in: dict) == nil) }
        let data = try JSONSerialization.data(withJSONObject: dict)

        let file = try AinkradThemeFile(decoding: data)
        #expect(file.skin == AinkradSkin.standard)
    }

    @Test("round-trip through a theme file keeps the added tokens")
    func roundTrip() throws {
        var skin = AinkradSkin.standard
        skin.size.s13 = 14
        skin.syntax.callout.bug = 345
        skin.type.editor.headingRatios = [2, 1.5]
        skin.colors.graphLanes = [.palette("accentPrimary", 1.0)]
        let data = try JSONEncoder().encode(skin)

        let file = try AinkradThemeFile(decoding: data)
        #expect(file.skin == skin)
    }

    @Test("a based override inherits the added tokens")
    func basedOverrideInherits() throws {
        let base = try AinkradThemeFile(decoding: JSONEncoder().encode(AinkradSkin.standard))
        let json = ##"{"schemaVersion":1,"id":"o","name":"O","base":"neonBlue","palette":{"background":"#112233"}}"##
        let file = try AinkradThemeFile(decoding: Data(json.utf8), bases: ["neonBlue": base])
        #expect(file.skin.size.s13 == 13)
        #expect(file.skin.syntax.callout == AinkradSkin.standard.syntax.callout)
        #expect(file.skin.colors == AinkradSkin.standard.colors)
    }

    @Test("a callout hue outside 0…360 is rejected")
    func calloutHueValidated() throws {
        let base = try AinkradThemeFile(decoding: JSONEncoder().encode(AinkradSkin.standard))
        let json = #"{"schemaVersion":1,"id":"o","name":"O","base":"neonBlue","syntax":{"callout":{"note":400}}}"#
        #expect(throws: AinkradThemeError.syntaxHueOutOfRange(path: "$.syntax.callout.note", hue: 400)) {
            try AinkradThemeFile(decoding: Data(json.utf8), bases: ["neonBlue": base])
        }
    }

    // MARK: - Helpers

    static func standardDict() throws -> [String: Any] {
        let data = try JSONEncoder().encode(AinkradSkin.standard)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    static func value(at path: [String], in dict: [String: Any]) -> Any? {
        var node: Any? = dict
        for key in path { node = (node as? [String: Any])?[key] }
        return node
    }

    static func remove(_ path: [String], from dict: inout [String: Any]) {
        guard let key = path.first else { return }
        if path.count == 1 {
            dict[key] = nil
        } else if var child = dict[key] as? [String: Any] {
            remove(Array(path.dropFirst()), from: &child)
            dict[key] = child
        }
    }

    static func rgba(_ color: Color) -> [Double] {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .clear
        // 8-bit channels: what a theme file stores and an 8-bit render shows.
        return [ns.redComponent, ns.greenComponent, ns.blueComponent, ns.alphaComponent]
            .map { (Double($0) * 255).rounded() }
    }
}
