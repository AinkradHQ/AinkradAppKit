import AppKit
import SwiftUI
import XCTest

@testable import AinkradAppKitUI

/// FP48: a rename field selects the name without its extension. XCTest, not
/// Swift Testing: the selection lands a main-queue turn after focus, which a
/// `@MainActor` Swift Testing test (running ON the main queue) never sees.
@MainActor
final class TextFieldBaseNameSelectionTests: XCTestCase {
    func testBaseNameRange() {
        XCTAssertEqual(ainkradBaseNameRange("SidebarRow.swift"), NSRange(location: 0, length: 10))
        XCTAssertEqual(ainkradBaseNameRange("archive.tar.gz"), NSRange(location: 0, length: 11))
        XCTAssertEqual(ainkradBaseNameRange("Makefile"), NSRange(location: 0, length: 8))
        XCTAssertEqual(ainkradBaseNameRange(".gitignore"), NSRange(location: 0, length: 10))
        XCTAssertEqual(ainkradBaseNameRange("café.md"), NSRange(location: 0, length: 4))
        XCTAssertEqual(ainkradBaseNameRange(""), NSRange(location: 0, length: 0))
    }

    func testOptInIsOffByDefault() {
        XCTAssertFalse(AinkradTextField(text: .constant(""), placeholder: "").selectsBaseName)
        XCTAssertTrue(
            AinkradTextField(text: .constant(""), placeholder: "").selectsNameWithoutExtension().selectsBaseName)
    }

    /// Focuses the field in an off-screen window and reads the field editor's
    /// selection once the main queue has drained.
    private func selection(optIn: Bool) throws -> NSRange {
        var field = AinkradTextField(text: .constant("SidebarRow.swift"), placeholder: "Name")
        if optIn { field = field.selectsNameWithoutExtension() }
        let host = NSHostingView(rootView: field.frame(width: 240).ainkradSkin(.standard))
        host.frame = NSRect(x: 0, y: 0, width: 260, height: 60)
        let window = NSWindow(
            contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.layoutIfNeeded()
        defer { window.close() }
        let textField = try XCTUnwrap(Self.textField(in: host))
        XCTAssertTrue(window.makeFirstResponder(textField))
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let editor = try XCTUnwrap(window.firstResponder as? NSTextView)
        return editor.selectedRange()
    }

    func testRenameSelectsTheNameWithoutItsExtension() throws {
        XCTAssertEqual(try selection(optIn: true), NSRange(location: 0, length: 10))
    }

    func testDefaultFieldStillSelectsEverything() throws {
        XCTAssertEqual(try selection(optIn: false), NSRange(location: 0, length: 16))
    }

    private static func textField(in view: NSView) -> NSTextField? {
        if let field = view as? NSTextField, field.isEditable { return field }
        for sub in view.subviews { if let found = textField(in: sub) { return found } }
        return nil
    }
}
