import SwiftUI
import AppKit
import AinkradAppKitContract

/// Computes the live `AinkradMotionBudget` and injects it into the environment.
/// Apply ONCE at the app's root — every nested surface inherits it.
///
/// The three inputs and where each comes from:
/// - app active: `NSApplication.didBecomeActive/didResignActive`
/// - window visible: `NSWindow.didChangeOcclusionStateNotification` plus
///   miniaturise/deminiaturise. `occlusionState.contains(.visible)` is false
///   when the window is fully covered by another window, on another Space, or
///   minimised — exactly the cases where drawing is wasted.
/// - Low Power Mode: `NSProcessInfo.processInfo.isLowPowerModeEnabled`, which
///   posts `.NSProcessInfoPowerStateDidChange` when the user flips it.
private struct MotionBudgetSourceModifier: ViewModifier {
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    @State private var isAppActive = NSApp?.isActive ?? true
    @State private var isWindowVisible = true
    @State private var isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    private var budget: AinkradMotionBudget {
        AinkradMotionBudget(isAppActive: isAppActive, isWindowVisible: isWindowVisible,
                            isLowPower: isLowPower, reduceMotion: reduceMotion)
    }

    func body(content: Content) -> some View {
        content
            .environment(\.ainkradMotionBudget, budget)
            .onReceive(NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification)) { _ in isAppActive = true }
            .onReceive(NotificationCenter.default.publisher(
                for: NSApplication.didResignActiveNotification)) { _ in isAppActive = false }
            .onReceive(NotificationCenter.default.publisher(
                for: NSWindow.didChangeOcclusionStateNotification)) { _ in
                refreshVisibility()
            }
            .onReceive(NotificationCenter.default.publisher(
                for: NSWindow.didMiniaturizeNotification)) { _ in refreshVisibility() }
            .onReceive(NotificationCenter.default.publisher(
                for: NSWindow.didDeminiaturizeNotification)) { _ in refreshVisibility() }
            .onReceive(NotificationCenter.default.publisher(
                for: Notification.Name.NSProcessInfoPowerStateDidChange)) { _ in
                isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
            }
    }

    private func refreshVisibility() {
        isWindowVisible = NSApp?.windows.contains {
            $0.isVisible && $0.occlusionState.contains(.visible)
        } ?? true
    }
}

public extension View {
    /// Installs the live motion-budget source. Apply once, at the app root.
    func ainkradMotionBudgetSource() -> some View {
        modifier(MotionBudgetSourceModifier())
    }
}
