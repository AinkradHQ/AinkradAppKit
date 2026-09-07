import SwiftUI
import AinkradAppKitContract
import AinkradSignal

/// What slice of the feed a view shows.
///
/// Only `.own` exists in generation 9 — the aggregated cross-app feed is not
/// readable by apps until M3's declared subscriptions. It is an enum now rather
/// than a `Bool` so adding `.subscribed` later is an addition, not a signature
/// change on a shipped API.
public enum SignalFeedScope: Sendable, Equatable {
    case own
}

@MainActor
@Observable
public final class SignalFeedViewModel {
    public private(set) var events: [SignalEvent] = []
    private let emitter: any PluginSignalEmitter
    private let limit: Int

    public init(emitter: any PluginSignalEmitter, limit: Int = 100) {
        self.emitter = emitter
        self.limit = limit
    }

    public func reload() { events = emitter.own(limit: limit) }
}

/// An app's own slice of the Signal feed, ready to drop into a settings pane or
/// a sidebar.
///
/// Renders through the same `SignalFeedList` the host uses, so an app's feed and
/// the host's are the same surface rather than two that merely resemble each
/// other — which is the entire reason these components moved into the kit.
///
/// Read state and coalesce counts are host bookkeeping and are not exposed to
/// apps, so every row here renders as unread. That is deliberate: an app has no
/// business knowing whether the user has read its notifications in the host's
/// feed.
public struct SignalFeedView: View {
    private let scope: SignalFeedScope
    private let model: SignalFeedViewModel

    @Environment(\.ainkradTheme) private var theme

    public init(scope: SignalFeedScope, emitter: any PluginSignalEmitter, limit: Int = 100) {
        self.scope = scope
        self.model = SignalFeedViewModel(emitter: emitter, limit: limit)
    }

    public var body: some View {
        SignalFeedList(events: model.events)
            .onAppear { model.reload() }
    }
}
