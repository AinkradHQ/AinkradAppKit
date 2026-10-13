import AppKit
import SwiftUI
import XCTest

@testable import AinkradAppKitUI

/// `AinkradTextField(text:placeholder:focus:)`: a caller focuses the field on
/// open. XCTest so the run loop can turn while SwiftUI moves focus.
@MainActor
final class TextFieldFocusBindingTests: XCTestCase {
    /// Sets its focus to `true` on appear, as a sheet focusing its field does.
    private struct Host: View {
        let bound: Bool
        @FocusState private var focused: Bool

        var body: some View {
            Group {
                if bound {
                    AinkradTextField(text: .constant("SidebarRow.swift"), placeholder: "Name", focus: $focused)
                } else {
                    AinkradTextField(text: .constant("SidebarRow.swift"), placeholder: "Name")
                }
            }
            .frame(width: 240)
            .onAppear { focused = true }
        }
    }

    private func editsAfterAppearing(bound: Bool, skin: AinkradSkin = .standard) -> Bool {
        let host = NSHostingView(rootView: Host(bound: bound).ainkradSkin(skin))
        host.frame = NSRect(x: 0, y: 0, width: 260, height: 60)
        let window = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = host
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        return (window.firstResponder as? NSTextView)?.isFieldEditor == true
    }

    func testFocusBindingFocusesTheFieldOnOpen() {
        XCTAssertTrue(editsAfterAppearing(bound: true))
    }

    func testFieldWithoutABindingIsNotFocused() {
        XCTAssertFalse(editsAfterAppearing(bound: false))
    }

    func testBindingIsOptIn() {
        XCTAssertNil(AinkradTextField(text: .constant(""), placeholder: "").externalFocus)
    }
}
