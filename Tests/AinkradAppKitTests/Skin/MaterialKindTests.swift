import AppKit
import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKitUI

/// E1.1: `material.kind` picks blur, glass or solid for every kit surface.
@Suite("MaterialKindTests")
@MainActor
struct MaterialKindTests {
    @Test("standard is blur, and the original init keeps meaning blur")
    func standardIsBlur() {
        #expect(AinkradSkin.standard.material.kind == "blur")
        #expect(AinkradMaterialTokens().kind == "blur")
        #expect(AinkradMaterialTokens(panel: "sidebar").kind == "blur")
        let glass = AinkradMaterialTokens(kind: "glass")
        #expect(glass.kind == "glass")
        #expect(glass.panel == "hudWindow" && glass.hud == "fullScreenUI" && glass.panelOpacity == 0.94)
    }

    @Test("a theme file written before material.kind decodes to standard (backfill)")
    func olderFileDecodes() throws {
        var dict = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(AinkradSkin.standard)) as? [String: Any])
        var material = try #require(dict["material"] as? [String: Any])
        #expect(material.removeValue(forKey: "kind") != nil)
        dict["material"] = material
        let file = try AinkradThemeFile(decoding: JSONSerialization.data(withJSONObject: dict))
        #expect(file.skin == AinkradSkin.standard)
    }

    @Test("an unknown kind loads as blur with exactly one issue")
    func unknownKindDegrades() throws {
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        let json = #"{"schemaVersion":1,"id":"future","name":"F","base":"neonBlue","material":{"kind":"plasma"}}"#
        let result = ainkradLoadThemes([base, Data(json.utf8)])
        let theme = try #require(result.themes["future"])
        #expect(theme.skin.material.kind == "blur")
        #expect(
            result.issues == [
                AinkradThemeIssue(
                    fileId: "future",
                    error: .unknownValue(path: "$.material.kind", value: "plasma", fallback: "blur"))
            ])
    }

    @Test("known kinds load untouched and raise no issue")
    func knownKindsLoad() throws {
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        for kind in ["blur", "glass", "solid"] {
            let json = #"{"schemaVersion":1,"id":"k","name":"K","base":"neonBlue","material":{"kind":"\#(kind)"}}"#
            let result = ainkradLoadThemes([base, Data(json.utf8)])
            #expect(result.themes["k"]?.skin.material.kind == kind)
            #expect(result.issues.isEmpty)
        }
    }

    @Test("VisualEffectBlur maps the skin's material names, falling back to today's mapping")
    func materialNames() {
        #expect(ainkradVisualEffectMaterial(.panel, AinkradMaterialTokens()) == .hudWindow)
        #expect(ainkradVisualEffectMaterial(.hud, AinkradMaterialTokens()) == .fullScreenUI)
        let custom = AinkradMaterialTokens(panel: "sidebar", hud: "popover")
        #expect(ainkradVisualEffectMaterial(.panel, custom) == .sidebar)
        #expect(ainkradVisualEffectMaterial(.hud, custom) == .popover)
        let unknown = AinkradMaterialTokens(panel: "nope", hud: "")
        #expect(ainkradVisualEffectMaterial(.panel, unknown) == .hudWindow)
        #expect(ainkradVisualEffectMaterial(.hud, unknown) == .fullScreenUI)
    }

    @Test("AinkradPanel hosts the material its kind names")
    func panelHostsMaterial() {
        let blur = Self.views(inPanelWithKind: "blur")
        #expect(blur.contains { $0 is NSVisualEffectView })

        let solid = Self.views(inPanelWithKind: "solid")
        #expect(!solid.contains { $0 is NSVisualEffectView })

        let glass = Self.views(inPanelWithKind: "glass")
        if #available(macOS 26, *) {
            #expect(glass.contains { $0 is NSGlassEffectView })
            #expect(!glass.contains { $0 is NSVisualEffectView })
        } else {
            #expect(glass.contains { $0 is NSVisualEffectView })
        }
    }

    // MARK: - Helpers

    /// Every AppKit view an off-screen `AinkradPanel` builds under `kind`.
    static func views(inPanelWithKind kind: String) -> [NSView] {
        var skin = AinkradSkin.standard
        skin.material.kind = kind
        let panel = AinkradPanel { Text("Panel") }.frame(width: 200, height: 120)
        let host = NSHostingView(rootView: panel.ainkradSkin(skin))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 120), styleMask: [.borderless], backing: .buffered,
            defer: false)
        window.contentView = host
        window.layoutIfNeeded()
        host.displayIfNeeded()
        var all: [NSView] = []
        func walk(_ v: NSView) {
            all.append(v)
            v.subviews.forEach(walk)
        }
        walk(host)
        return all
    }
}
