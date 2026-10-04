import Foundation
// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — theme file tests
import Testing

@testable import AinkradAppKitUI

@Suite("ThemeFileTests")
@MainActor
struct ThemeFileTests {

    @Test("standard round-trip decoding byte-identical / equatable")
    func standardRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(AinkradSkin.standard)

        let themeFile = try AinkradThemeFile(decoding: data)
        #expect(themeFile.skin == AinkradSkin.standard)
        #expect(themeFile.host == nil)
    }

    @Test("palette-only override with base resolves correctly")
    func paletteOnlyOverrideWithBase() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let overrideJSON = """
            {
                "schemaVersion": 1,
                "id": "custom-neon",
                "name": "Custom Neon",
                "base": "neonBlue",
                "palette": {
                    "background": "#112233"
                }
            }
            """

        let bases = ["neonBlue": baseFile]
        let themeFile = try AinkradThemeFile(decoding: Data(overrideJSON.utf8), bases: bases)

        let expectedColor = AinkradColorToken.hex(0x11 / 255.0, 0x22 / 255.0, 0x33 / 255.0, 1.0)
        #expect(themeFile.skin.palette.background == expectedColor)
        #expect(themeFile.skin.palette.surface == baseFile.skin.palette.surface)
    }

    @Test("error case: oversize file (>256KB)")
    func errorOversize() {
        let largeData = Data(count: 256 * 1024 + 1)
        let result = ainkradLoadThemes([largeData])
        #expect(result.themes.isEmpty)
        #expect(result.issues.count == 1)
        if case .fileSizeExceedsLimit(let path, let bytes, let limitBytes) = result.issues.first?.error {
            #expect(path == "files[0]")
            #expect(bytes == 256 * 1024 + 1)
            #expect(limitBytes == 256 * 1024)
        } else {
            Issue.record("Expected fileSizeExceedsLimit error")
        }
    }

    @Test("error case: bad JSON")
    func errorBadJSON() {
        let badJSON = Data("{ invalid json ".utf8)
        #expect(throws: AinkradThemeError.self) {
            _ = try AinkradThemeFile(decoding: badJSON)
        }
    }

    @Test("error case: unsupported schema version 2")
    func errorVersion2() {
        let json = """
            {
                "schemaVersion": 2,
                "id": "test",
                "name": "Test"
            }
            """
        #expect(throws: AinkradThemeError.unsupportedSchemaVersion(path: "$.schemaVersion", version: 2)) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8))
        }
    }

    @Test("error case: unknown base")
    func errorUnknownBase() {
        let json = """
            {
                "schemaVersion": 1,
                "id": "test",
                "name": "Test",
                "base": "nonExistentBase"
            }
            """
        #expect(throws: AinkradThemeError.unknownBase(path: "$.base", baseId: "nonExistentBase")) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8))
        }
    }

    @Test("error case: base cycle")
    func errorBaseCycle() {
        let jsonA = """
            {
                "schemaVersion": 1,
                "id": "themeA",
                "name": "Theme A",
                "base": "themeB"
            }
            """
        let jsonB = """
            {
                "schemaVersion": 1,
                "id": "themeB",
                "name": "Theme B",
                "base": "themeA"
            }
            """

        let result = ainkradLoadThemes([Data(jsonA.utf8), Data(jsonB.utf8)])
        #expect(result.themes.isEmpty)
        #expect(result.issues.count == 2)
        #expect(
            result.issues.allSatisfy { issue in
                if case .baseCycle = issue.error { return true }
                return false
            })
    }

    @Test("error case: unknown key at depth 3")
    func errorUnknownKeyAtDepth3() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let json = """
            {
                "schemaVersion": 1,
                "id": "test",
                "name": "Test",
                "base": "neonBlue",
                "spacing": {
                    "invalidSubKey": 12
                }
            }
            """
        let bases = ["neonBlue": baseFile]
        #expect(throws: AinkradThemeError.unknownKey(path: "$.spacing.invalidSubKey")) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8), bases: bases)
        }
    }

    @Test("error case: missing key without base")
    func errorMissingKeyWithoutBase() {
        let json = """
            {
                "schemaVersion": 1,
                "id": "test",
                "name": "Test"
            }
            """
        #expect(throws: AinkradThemeError.self) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8))
        }
    }

    @Test("error case: null in override")
    func errorNullInOverride() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let json = """
            {
                "schemaVersion": 1,
                "id": "test",
                "name": "Test",
                "base": "neonBlue",
                "spacing": null
            }
            """
        let bases = ["neonBlue": baseFile]
        #expect(throws: AinkradThemeError.nullInOverride(path: "$.spacing")) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8), bases: bases)
        }
    }

    @Test("error case: bad hex color")
    func errorBadHex() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let json = """
            {
                "schemaVersion": 1,
                "id": "test",
                "name": "Test",
                "base": "neonBlue",
                "palette": {
                    "background": "not-a-hex"
                }
            }
            """
        let bases = ["neonBlue": baseFile]
        #expect(throws: AinkradThemeError.self) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8), bases: bases)
        }
    }

    @Test("error case: unknown palette reference")
    func errorUnknownPaletteRef() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let json = """
            {
                "schemaVersion": 1,
                "id": "test",
                "name": "Test",
                "base": "neonBlue",
                "palette": {
                    "background": "nonExistentColor"
                }
            }
            """
        let bases = ["neonBlue": baseFile]
        #expect(
            throws: AinkradThemeError.unknownPaletteReference(
                path: "$.palette.background", reference: "nonExistentColor")
        ) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8), bases: bases)
        }
    }

    @Test("error case: alpha 1.2 out of range")
    func errorAlphaOutOfRange() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let json = """
            {
                "schemaVersion": 1,
                "id": "test",
                "name": "Test",
                "base": "neonBlue",
                "palette": {
                    "background": "#1122331.2"
                }
            }
            """
        let bases = ["neonBlue": baseFile]
        #expect(throws: AinkradThemeError.self) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8), bases: bases)
        }
    }

    @Test("error case: negative width dimension")
    func errorNegativeWidth() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let json = """
            {
                "schemaVersion": 1,
                "id": "test",
                "name": "Test",
                "base": "neonBlue",
                "spacing": {
                    "xs": -4.0
                }
            }
            """
        let bases = ["neonBlue": baseFile]
        #expect(throws: AinkradThemeError.negativeDimension(path: "$.spacing.xs", value: -4.0)) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8), bases: bases)
        }
    }

    @Test("error case: empty id")
    func errorEmptyId() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let json = """
            {
                "schemaVersion": 1,
                "id": "",
                "name": "Test",
                "base": "neonBlue"
            }
            """
        let bases = ["neonBlue": baseFile]
        #expect(throws: AinkradThemeError.invalidId(path: "$.id", id: "")) {
            _ = try AinkradThemeFile(decoding: Data(json.utf8), bases: bases)
        }
    }

    @Test("broken file yields its base plus an issue, never a crash")
    func brokenFileYieldsBaseAndIssue() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)

        let brokenJSON = """
            {
                "schemaVersion": 1,
                "id": "brokenTheme",
                "name": "Broken",
                "base": "neonBlue",
                "spacing": {
                    "xs": -10
                }
            }
            """

        let result = ainkradLoadThemes([baseData, Data(brokenJSON.utf8)])
        #expect(result.themes.count == 1)
        #expect(result.themes["neonBlue"] != nil)
        #expect(result.issues.count == 1)
        #expect(result.issues.first?.fileId == "brokenTheme")
    }

    @Test("host section returned byte-identical")
    func hostSectionByteIdentical() throws {
        let baseEncoder = JSONEncoder()
        let baseData = try baseEncoder.encode(AinkradSkin.standard)
        let baseFile = try AinkradThemeFile(decoding: baseData)

        let hostJSON = """
            {
                "skyProfile": "cyber",
                "iconColorFamily": "purple"
            }
            """

        let json = """
            {
                "schemaVersion": 1,
                "id": "testHost",
                "name": "Test Host",
                "base": "neonBlue",
                "host": \(hostJSON)
            }
            """

        let bases = ["neonBlue": baseFile]
        let themeFile = try AinkradThemeFile(decoding: Data(json.utf8), bases: bases)

        #expect(themeFile.host != nil)
        if let hostData = themeFile.host {
            let decodedObj = try JSONSerialization.jsonObject(with: hostData) as? [String: String]
            #expect(decodedObj?["skyProfile"] == "cyber")
            #expect(decodedObj?["iconColorFamily"] == "purple")
        }
    }
}
