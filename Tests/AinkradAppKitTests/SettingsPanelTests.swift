import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradSettingsPanel")
@MainActor
struct SettingsPanelTests {
    private var source: String {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // AinkradAppKitTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // package root
            .appendingPathComponent("Sources/AinkradAppKitUI/Components/AinkradSettingsPanel.swift")
        return (try? String(contentsOf: path, encoding: .utf8)) ?? ""
    }

    @Test("hint is capped at a reading measure")
    func readingWidth() {
        #expect(AinkradSettingsPanel<EmptyView>.hintReadingWidth == 560)
    }

    @Test("panel draws the recessed surface at the agreed opacity")
    func surface() {
        #expect(source.contains("surfaceElevated.opacity(0.32)"))
        #expect(source.contains("ChamferShape(cut: AinkradRadius.md)"))
    }

    /// The design language forbids separator lines and borders on this
    /// surface; the recess is what divides. A `strokeBorder` here would put
    /// the panel back into `AinkradSectionFrame`'s idiom.
    @Test("panel draws no border and no divider")
    func noBorder() {
        #expect(!source.contains("strokeBorder"))
        #expect(!source.contains("Divider"))
    }

    /// Sentence case is the whole point of the component. `.uppercased()` or
    /// tracking would make it a second copy of AinkradSectionFrame.
    @Test("title is sentence case, not HUD caps")
    func sentenceCase() {
        #expect(!source.contains(".uppercased()"))
        #expect(!source.contains(".tracking("))
    }

    /// Hardcoded point sizes ignore the user's font scale — the exact setting
    /// the Appearance page this component renders is used to change.
    @Test("type comes from the role scale, not hardcoded points")
    func usesTypeRoles() {
        #expect(source.contains("AinkradFontResolver.font(.headline"))
        #expect(source.contains("AinkradFontResolver.font(.caption"))
    }
}

@Suite("AinkradCaptionedRow")
@MainActor
struct CaptionedRowTests {
    private var source: String {
        let path = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/AinkradAppKitUI/Components/AinkradCaptionedRow.swift")
        return (try? String(contentsOf: path, encoding: .utf8)) ?? ""
    }

    /// The fixed column is the entire reason this type exists: it is what makes
    /// stacked controls align into a form instead of reading as one flat list
    /// of loose pills.
    @Test("caption sits in a fixed column")
    func fixedColumn() {
        #expect(AinkradCaptionedRow<EmptyView>.captionColumnWidth == 86)
        #expect(source.contains("width: Self.captionColumnWidth"))
    }

    /// The control carries its own accessibility label; a visible caption
    /// repeated to VoiceOver is noise.
    @Test("caption is hidden from accessibility")
    func captionHidden() {
        #expect(source.contains(".accessibilityHidden(true)"))
    }
}
