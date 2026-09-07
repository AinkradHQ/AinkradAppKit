import SwiftUI

/// How a pane tells the host which of the app's own things it is showing, so a
/// notification can focus the pane that produced it.
///
/// ## Why this is an environment value and not a protocol requirement
///
/// `AinkradApp` is ABI-frozen and `makeRootView(host:)` receives one
/// `HostServices` per APP, not per pane — so nothing in the contract can tell
/// two panes of the same app apart. Adding a requirement to carry a pane
/// identity is the one change library evolution does not cover, and it would
/// break every generation-9 bundle.
///
/// The SwiftUI environment is a side channel that needs no contract change at
/// all: the host injects a sink around the view it is already rendering for a
/// known pane, and an app opts in by reading it. An app that never reads it
/// keeps working exactly as before, which is why the default is a sink that
/// does nothing.
///
/// Usage, from inside an app's own pane view:
///
/// ```swift
/// @Environment(\.ainkradPaneLocator) private var paneLocator
/// // ...
/// .onAppear { paneLocator(session.id.uuidString) }
/// ```
///
/// Then emit deep links carrying the same string as
/// `SignalDeepLink(appID:payload:locator:)`.
///
/// ## Why this is `Equatable` by identity
///
/// It is handed to a plugin's pane through the environment, and the host's
/// pane content view deliberately excludes inputs that would rebuild the
/// hosted app — rebuilding re-invokes `updateNSView`, which for a terminal
/// reapplies font, palette, cursor and transparency on a tab switch that
/// changed none of them. A closure can never be compared, so a freshly
/// constructed sink on every render would look like a change every time and
/// reintroduce exactly that cost.
///
/// Comparing the underlying box by identity lets the host hand out ONE sink
/// per pane and have SwiftUI recognise it as unchanged.
public struct SignalPaneLocatorSink: Sendable, Equatable {
    /// Holds the closure so the struct can have identity. `@unchecked` because
    /// the closure is `@MainActor`-isolated and the box is never mutated.
    private final class Box: @unchecked Sendable {
        let report: @MainActor @Sendable (String?) -> Void
        init(_ report: @escaping @MainActor @Sendable (String?) -> Void) {
            self.report = report
        }
    }
    private let box: Box

    public init(report: @escaping @MainActor @Sendable (String?) -> Void) {
        self.box = Box(report)
    }

    public static func == (lhs: SignalPaneLocatorSink, rhs: SignalPaneLocatorSink) -> Bool {
        lhs.box === rhs.box
    }

    /// Reports the locator this pane is currently showing. Pass nil when the
    /// pane no longer shows anything addressable.
    ///
    /// Safe to call repeatedly and on every change — the host keeps the last
    /// value per pane. An app SHOULD call it again when the pane's content
    /// changes, or a notification will focus the pane that used to hold the
    /// session rather than the one that does.
    @MainActor public func callAsFunction(_ locator: String?) { box.report(locator) }
}

private struct SignalPaneLocatorKey: EnvironmentKey {
    /// A sink that discards. An app reading this outside a host pane — in a
    /// preview, in its own tests, in the Dev Host — must not have to special
    /// case its absence.
    static let defaultValue = SignalPaneLocatorSink { _ in }
}

public extension EnvironmentValues {
    var ainkradPaneLocator: SignalPaneLocatorSink {
        get { self[SignalPaneLocatorKey.self] }
        set { self[SignalPaneLocatorKey.self] = newValue }
    }
}
