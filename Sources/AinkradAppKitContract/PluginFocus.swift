import SwiftUI

/// Whether the pane this view is in currently has the user's attention.
///
/// ## Why the host has to be the one that says
///
/// A plugin cannot answer this on its own. The audit found Terminal binding the
/// agent's terminal context to whichever pane was *created last*, because
/// `makeNSView` was the only place it could hook — so with two terminals open,
/// asking the assistant about "the terminal" fed it the other pane's buffer,
/// silently. Wave 2 improved that to first-responder tracking, which is real
/// but still a guess: AppKit first-responder answers "which view has the
/// keyboard", not "which pane is the user working in". A pane can be the
/// focused one with keyboard focus sitting in a host overlay.
///
/// Only the host knows. It owns the tile layout, the focused block id, focus
/// mode and workspace switching. So it publishes the answer, and plugins read
/// it instead of inferring it:
///
/// ```swift
/// @Environment(\.ainkradPaneIsFocused) private var isFocused
/// ```
///
/// Delivered through the SwiftUI environment rather than `HostServices`
/// because focus is *per-view*, not per-app: one app can have several panes,
/// and each needs its own answer. `HostServices` is scoped to the app, so it is
/// structurally the wrong place.
extension EnvironmentValues {
    /// True when this pane is the focused one in its workspace. Defaults to
    /// `true` so a plugin rendered outside a host pane (previews, tests, a
    /// generation-7 host that never sets it) behaves as if it has focus rather
    /// than appearing inert.
    @Entry public var ainkradPaneIsFocused: Bool = true
}
