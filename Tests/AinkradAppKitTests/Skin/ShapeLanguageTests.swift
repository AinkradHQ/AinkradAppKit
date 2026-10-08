import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// E1.2: one top-level `shape.style` rounds every kit shape.
/// `@MainActor`: decoding the giant `AinkradSkin` overflows a 512 KiB worker stack in Debug.
@Suite("ShapeLanguageTests")
@MainActor
struct ShapeLanguageTests {
    @Test("a default.theme (standard, no base) decodes to an identical skin")
    func standardIsNoOp() throws {
        let file = try AinkradThemeFile(decoding: JSONEncoder().encode(AinkradSkin.standard))
        #expect(file.skin == AinkradSkin.standard)
    }

    @Test("shape.style continuous rewrites every shape token under components and roles")
    func continuousRewritesEveryToken() throws {
        let standardStyles = try Self.shapeStyles(of: AinkradSkin.standard)
        #expect(standardStyles.filter { $0 == "chamfer" }.count >= 50)
        #expect(standardStyles.filter { $0 == "continuous" }.count == 2)

        let skin = try Self.load(style: "continuous").skin
        let styles = try Self.shapeStyles(of: skin)
        #expect(styles.count == standardStyles.count)
        #expect(styles.allSatisfy { $0 == "continuous" })
        #expect(skin.shape.style == "continuous")
    }

    @Test("circular rewrites only chamfer tokens; the two continuous ones stay")
    func circularKeepsContinuous() throws {
        let styles = try Self.shapeStyles(of: Self.load(style: "circular").skin)
        #expect(styles.filter { $0 == "continuous" }.count == 2)
        #expect(styles.filter { $0 == "circular" }.count == styles.count - 2)
    }

    @Test("an unknown style loads as chamfer, rewrites nothing, and raises one issue")
    func unknownStyleDegrades() throws {
        let (file, issues) = try Self.loadWithIssues(style: "blobby")
        #expect(file.skin.shape.style == "chamfer")
        #expect(file.skin.components == AinkradSkin.standard.components)
        #expect(file.skin.roles == AinkradSkin.standard.roles)
        #expect(
            issues == [
                AinkradThemeIssue(
                    fileId: "lang", error: .unknownValue(path: "$.shape.style", value: "blobby", fallback: "chamfer"))
            ])
    }

    @Test("skin.shape(cut:corners:) is ChamferShape under Neon and a rounded rect under continuous")
    func helperGeometry() throws {
        let rect = CGRect(x: 0, y: 0, width: 120, height: 40)
        let neon = AinkradSkin.standard.shape(cut: 7, corners: [.topLeft])
        #expect(neon.path(in: rect) == ChamferShape(cut: 7, corners: [.topLeft]).path(in: rect))
        #expect(
            neon.inset(by: 1.5).path(in: rect)
                == ChamferShape(cut: 7, corners: [.topLeft]).inset(by: 1.5).path(in: rect))
        #expect(AinkradSkin.standard.shape(cut: 7).path(in: rect) == ChamferShape(cut: 7).path(in: rect))

        let continuous = try Self.load(style: "continuous").skin.shape(cut: 7, corners: [.topLeft])
        #expect(continuous.path(in: rect) == RoundedRectangle(cornerRadius: 7, style: .continuous).path(in: rect))
    }

    // MARK: - Helpers

    static func load(style: String) throws -> AinkradThemeFile {
        try loadWithIssues(style: style).file
    }

    static func loadWithIssues(style: String) throws -> (file: AinkradThemeFile, issues: [AinkradThemeIssue]) {
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        let json = #"{"schemaVersion":1,"id":"lang","name":"L","base":"neonBlue","shape":{"style":"\#(style)"}}"#
        let result = ainkradLoadThemes([base, Data(json.utf8)])
        return (try #require(result.themes["lang"]), result.issues)
    }

    /// The `style` of every shape token under `components` and `roles`, read from the encoded JSON.
    static func shapeStyles(of skin: AinkradSkin) throws -> [String] {
        let dict = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(skin)) as? [String: Any])
        let shapeKeys: Set<String> = ["style", "cut", "cutRatio", "minCut", "corners"]
        var styles: [String] = []
        func walk(_ node: Any) {
            if let d = node as? [String: Any] {
                if let style = d["style"] as? String, Set(d.keys).isSubset(of: shapeKeys) { styles.append(style) }
                d.values.forEach(walk)
            } else if let a = node as? [Any] {
                a.forEach(walk)
            }
        }
        walk(try #require(dict["components"]))
        walk(try #require(dict["roles"]))
        return styles
    }
}
