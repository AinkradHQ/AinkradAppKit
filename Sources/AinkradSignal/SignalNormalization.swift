import Foundation

public enum SignalLimits {
    public static let maxTitle = 120
    public static let maxBody = 2000
    public static let maxActions = 3
    public static let maxKind = 64
}

public enum SignalKind {
    /// Lowercase, dot-separated, 1...64 of `[a-z0-9._-]`. Rejected kinds never
    /// reach the store: the feed's filters and the user's routing rules both
    /// key on `kind`, so an unconstrained value makes rules unwritable.
    ///
    /// `-` and `_` are allowed because the first realistic vocabulary written
    /// against this rule broke it: `session.needsInput` is the natural name for
    /// "the agent is waiting for you", and camelCase made it invalid, so the
    /// single most valuable notification in the product was silently dropped at
    /// ingest. Uppercase stays out - one spelling per kind is what keeps a
    /// user's routing rules writable - but a word separator is not a luxury.
    public static func isValid(_ kind: String) -> Bool {
        guard !kind.isEmpty, kind.count <= SignalLimits.maxKind else { return false }
        return kind.allSatisfy { character in
            guard character.isASCII else { return false }
            return (character.isLetter && character.isLowercase)
                || character.isNumber
                || character == "."
                || character == "-"
                || character == "_"
        }
    }
}

public extension SignalEvent {
    /// Returns a copy with `source` stamped by the host and over-long fields
    /// truncated. Never rejects — validation of `kind` is the caller's job
    /// (see `SignalKind.isValid`), because a rejection needs to be reported.
    func normalized(source stamped: SignalSource) -> SignalEvent {
        SignalEvent(
            id: id,
            timestamp: timestamp,
            source: stamped,
            kind: kind,
            severity: severity,
            title: String(title.prefix(SignalLimits.maxTitle)),
            body: body.map { String($0.prefix(SignalLimits.maxBody)) },
            proposedImportance: proposedImportance,
            deepLink: deepLink,
            actions: Array(actions.prefix(SignalLimits.maxActions)),
            dedupeKey: dedupeKey)
    }
}
