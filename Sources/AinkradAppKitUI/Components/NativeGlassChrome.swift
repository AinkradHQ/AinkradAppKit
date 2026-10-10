// design-lint: allow-file radius-literal,frame-literal,opacity-literal,raw-color native macOS field metrics and system colours under Glass Native
import AppKit
import SwiftUI

/// The bezel a native macOS editor wears under Glass Native: the system text
/// background, a hairline, and the accent focus ring. Fields are content, not
/// controls, so they stay opaque rather than glass (Apple's layering rule).
struct NativeFieldChrome: ViewModifier {
    let focused: Bool
    let accent: Color

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        content
            .background(Color(nsColor: .textBackgroundColor), in: shape)
            .overlay(
                shape.strokeBorder(
                    focused ? accent.opacity(0.7) : Color(nsColor: .separatorColor), lineWidth: focused ? 2 : 1))
    }
}

extension View {
    func nativeFieldChrome(focused: Bool, accent: Color) -> some View {
        modifier(NativeFieldChrome(focused: focused, accent: accent))
    }
}
