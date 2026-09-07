import Foundation

/// Who produced an event. Stamped by the host at ingest — never supplied by
/// the emitter, which is what makes forgery inexpressible in the API.
public enum SignalSource: Codable, Sendable, Hashable {
    case host
    case sage
    case app(appID: String)
}

public enum SignalSeverity: String, Codable, Sendable, CaseIterable, Hashable {
    case info, success, warning, failure
}

/// What the emitter *proposes*. An input to routing, never an override:
/// an `.urgent` proposal from a muted source stays muted.
public enum SignalImportance: String, Codable, Sendable, CaseIterable, Hashable {
    case background, normal, urgent
}

/// Where activating an event takes the user. `payload` is opaque to Signal and
/// is handed to the target app by the host's existing cross-app launch path.
public struct SignalDeepLink: Codable, Sendable, Equatable {
    public let appID: String
    public let payload: Data

    /// Which of the app's own panes produced this, if the app can say
    /// (generation 10).
    ///
    /// **Why the host needs this when `payload` already carries it.** `payload`
    /// is opaque by design — the host hands it over without reading it, which
    /// is what lets apps agree on their own encodings. But to focus the RIGHT
    /// pane the host has to match, and matching means reading. So the app
    /// states the one field the host is allowed to compare, and the payload
    /// stays opaque.
    ///
    /// The value means nothing to the host: it compares it to what a pane
    /// reported through `ainkradPaneLocator` and does nothing else with it. A
    /// session id, a document path, a tab id — whatever the app already uses
    /// to tell its own panes apart.
    ///
    /// Nil is the ordinary case and always valid: the host then focuses any
    /// pane of that app, which is the generation-9 behaviour.
    public let locator: String?

    public init(appID: String, payload: Data) {
        self.appID = appID
        self.payload = payload
        self.locator = nil
    }

    /// Kept as a separate initialiser rather than adding a defaulted parameter
    /// to the one above: a defaulted parameter would be ambiguous at every
    /// existing call site, and the two-argument form is already compiled into
    /// shipped plugin bundles.
    public init(appID: String, payload: Data, locator: String?) {
        self.appID = appID
        self.payload = payload
        self.locator = locator
    }

    private enum CodingKeys: String, CodingKey {
        case appID, payload, locator
    }

    /// Hand-written so `locator` is optional on the wire. Events stored before
    /// generation 10 have no such key, and a synthesised decoder would make
    /// every one of them fail to load — a feature addition silently emptying
    /// the user's history.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        appID = try c.decode(String.self, forKey: .appID)
        payload = try c.decode(Data.self, forKey: .payload)
        locator = try c.decodeIfPresent(String.self, forKey: .locator)
    }
}

public struct SignalAction: Codable, Sendable, Equatable {
    public let id: String
    public let label: String
    public let isDestructive: Bool
    public init(id: String, label: String, isDestructive: Bool = false) {
        self.id = id
        self.label = label
        self.isDestructive = isDestructive
    }

    /// Hand-written so `isDestructive` defaults the same way it does in the
    /// memberwise init above. The synthesised decoder REQUIRED the key, which
    /// only surfaced once actions could arrive over the wire (M3): a payload
    /// carrying `{"id":"rerun","label":"Re-run"}` — valid JSON, and exactly
    /// what a first attempt looks like — failed to decode, and because a
    /// payload is rejected whole the entire notification was reported as
    /// `malformed`. Two initialisers disagreeing about a default is the kind
    /// of thing nobody finds by reading.
    ///
    /// Defaulting to `false` is the safe direction: an action is non-destructive
    /// unless it says so, so a missing key can never silently skip the
    /// confirmation step a destructive action requires.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        label = try c.decode(String.self, forKey: .label)
        isDestructive = try c.decodeIfPresent(Bool.self, forKey: .isDestructive) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id, label, isDestructive
    }
}

public struct SignalEvent: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let source: SignalSource
    public let kind: String
    public let severity: SignalSeverity
    public let title: String
    public let body: String?
    public let proposedImportance: SignalImportance
    public let deepLink: SignalDeepLink?
    public let actions: [SignalAction]
    public let dedupeKey: String?

    public init(id: UUID = UUID(),
                timestamp: Date = Date(),
                source: SignalSource,
                kind: String,
                severity: SignalSeverity,
                title: String,
                body: String? = nil,
                proposedImportance: SignalImportance = .normal,
                deepLink: SignalDeepLink? = nil,
                actions: [SignalAction] = [],
                dedupeKey: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.kind = kind
        self.severity = severity
        self.title = title
        self.body = body
        self.proposedImportance = proposedImportance
        self.deepLink = deepLink
        self.actions = actions
        self.dedupeKey = dedupeKey
    }
}
