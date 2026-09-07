import Foundation

/// Why a payload from outside the host was refused.
///
/// Specific by design: the CLI reports these to a human on stderr, and
/// "unknown token" and "malformed JSON" need entirely different fixes. A
/// single `.rejected` would send an operator reading their pipeline when their
/// credential is stale.
///
/// **A rejection never carries the token.** A token is a credential; the peer
/// is identified by a stable hash of it, never by the value. That is why
/// `.unknownToken` has no associated value while `.invalidKind` does.
public enum SignalWireRejection: Error, Equatable, Sendable {
    case tooLarge(bytes: Int)
    case malformed
    case missingToken
    case invalidKind(String)
    case emptyTitle
    case unknownToken
    case throttled
}

/// What an external process may send. Carries a `token` and **no `source`**:
/// the host derives the source from the token, so a peer can no more forge an
/// attribution over the socket than an in-process plugin can through
/// `PluginSignalEmitter`. One rule, two transports.
public struct SignalWirePayload: Codable, Sendable, Equatable {
    public let token: String
    public let kind: String
    public let severity: SignalSeverity
    public let title: String
    public let body: String?
    public let importance: SignalImportance
    public let deepLink: SignalDeepLink?
    public let actions: [SignalAction]
    public let dedupeKey: String?

    private enum CodingKeys: String, CodingKey {
        case token, kind, severity, title, body, importance, deepLink, actions, dedupeKey
    }

    /// Hand-written rather than synthesised so the OPTIONAL fields are actually
    /// optional on the wire. A shell script posting the minimum — token, kind,
    /// severity, title — is the common case, and a synthesised decoder would
    /// demand `importance` and `actions` from it.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        token = try c.decode(String.self, forKey: .token)
        kind = try c.decode(String.self, forKey: .kind)
        severity = try c.decode(SignalSeverity.self, forKey: .severity)
        title = try c.decode(String.self, forKey: .title)
        body = try c.decodeIfPresent(String.self, forKey: .body)
        importance = try c.decodeIfPresent(SignalImportance.self, forKey: .importance) ?? .normal
        deepLink = try c.decodeIfPresent(SignalDeepLink.self, forKey: .deepLink)
        actions = try c.decodeIfPresent([SignalAction].self, forKey: .actions) ?? []
        dedupeKey = try c.decodeIfPresent(String.self, forKey: .dedupeKey)
    }

    public init(token: String, kind: String, severity: SignalSeverity, title: String,
                body: String? = nil, importance: SignalImportance = .normal,
                deepLink: SignalDeepLink? = nil, actions: [SignalAction] = [],
                dedupeKey: String? = nil) {
        self.token = token
        self.kind = kind
        self.severity = severity
        self.title = title
        self.body = body
        self.importance = importance
        self.deepLink = deepLink
        self.actions = actions
        self.dedupeKey = dedupeKey
    }
}

public enum SignalWire {
    public static let maxPayloadBytes = 8 * 1024

    /// Decodes and validates in one pass, rejecting whole payloads only —
    /// nothing is ever partially applied.
    ///
    /// The size check comes FIRST, before any parsing: an 8 MB payload must
    /// cost a length comparison, not a JSON parse. This is the one branch here
    /// that is about the host's own safety rather than the operator's
    /// convenience.
    public static func decode(_ data: Data) -> Result<SignalWirePayload, SignalWireRejection> {
        guard data.count <= maxPayloadBytes else { return .failure(.tooLarge(bytes: data.count)) }
        guard let payload = try? JSONDecoder().decode(SignalWirePayload.self, from: data) else {
            // Distinguish "no token at all" from "not JSON", so the operator
            // knows whether to fix their pipeline or their credentials. Valid
            // JSON that simply lacks a token is the shape a first attempt
            // takes, and calling that "malformed" sends them to reread a
            // document that is already correct.
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               object["token"] == nil {
                return .failure(.missingToken)
            }
            return .failure(.malformed)
        }
        // Validated at the wire rather than left to ingest. Ingest rejects an
        // invalid kind too, but by then the event has a source stamped on it
        // and a rejection reads as the host refusing its own work; here it is
        // still the peer's payload, which is what the CLI has to report.
        guard SignalKind.isValid(payload.kind) else { return .failure(.invalidKind(payload.kind)) }
        guard !payload.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.emptyTitle)
        }
        return .success(payload)
    }
}
