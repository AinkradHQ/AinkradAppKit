import Foundation

/// One line of an app's declared interest in other sources' events.
///
/// Written as `<source>/<kindPattern>` in the app's Info.plist under
/// `AinkradSignalSubscriptions`, where source is `host`, `sage` or
/// `app:<appID>`, and the kind pattern is an exact kind or a `prefix.*`
/// wildcard.
///
/// ## Why a wildcard source is rejected
///
/// The user approves a NAMED LIST at install. `*/build.failed` would make that
/// approval a blank cheque — "this app may read notifications from anything you
/// ever install, including apps that do not exist yet". A list the user cannot
/// evaluate is not consent, so the parser refuses it outright rather than
/// showing an approval prompt nobody can reason about.
///
/// A wildcard KIND is fine, because the source is still named: "Raven's build
/// events" is a claim the user can weigh.
public struct SignalSubscription: Sendable, Equatable, Hashable {
    public let source: SignalSource
    /// The exact kind, or the prefix before `.*` for a wildcard.
    public let kindPattern: String
    public let isWildcard: Bool

    public init(source: SignalSource, kindPattern: String, isWildcard: Bool) {
        self.source = source
        self.kindPattern = kindPattern
        self.isWildcard = isWildcard
    }

    public func matches(_ event: SignalEvent) -> Bool {
        guard event.source == source else { return false }
        guard isWildcard else { return event.kind == kindPattern }
        // `*` alone subscribes to every kind from that named source.
        guard !kindPattern.isEmpty else { return true }
        // The separator is required, so `build.*` matches `build.failed` and
        // NOT `buildings.started`. A bare `hasPrefix("build")` would hand the
        // subscriber a namespace it never asked for.
        return event.kind.hasPrefix(kindPattern + ".")
    }

    /// One line for the install-time approval prompt.
    ///
    /// The user is being asked to allow one app to read another's
    /// notifications, so the sentence names both the source and the shape of
    /// what will be read — never the raw pattern on its own, which reads as
    /// configuration rather than as a permission.
    /// Just the kind half — "build.* notifications", "all notifications".
    ///
    /// Exists so the HOST can compose the sentence with a real display name.
    /// `approvalDescription` can only name an app by its id, because nothing
    /// in this module knows that "raven" is called "Raven" — and a consent
    /// prompt reading "raven: build.* notifications" next to "Sage: all
    /// notifications" tells the user that one of these is a program and the
    /// other is a product, which is not a distinction they should have to
    /// decode while deciding.
    public var kindDescription: String {
        if isWildcard {
            return kindPattern.isEmpty ? "all notifications" : "\(kindPattern).* notifications"
        }
        return "\(kindPattern) notifications"
    }

    /// The source's own name, when it is not an app: nil for `.app`, whose
    /// display name only the host can resolve.
    public var builtInSourceName: String? {
        switch source {
        case .host: return "Ainkrad"
        case .sage: return "Sage"
        case .app: return nil
        @unknown default: return nil
        }
    }

    public var approvalDescription: String {
        let name: String
        switch source {
        case .host: name = "Ainkrad"
        case .sage: name = "Sage"
        case .app(let appID): name = appID
        @unknown default: name = "another app"
        }
        if isWildcard {
            return kindPattern.isEmpty
                ? "\(name): all notifications"
                : "\(name): \(kindPattern).* notifications"
        }
        return "\(name): \(kindPattern) notifications"
    }

    /// What `parseReportingInvalid` found.
    public struct ParseResult: Sendable, Equatable {
        public let subscriptions: [SignalSubscription]
        /// The patterns that were dropped, verbatim, so the host can name them
        /// in a warning.
        public let invalid: [String]
        public init(subscriptions: [SignalSubscription], invalid: [String]) {
            self.subscriptions = subscriptions
            self.invalid = invalid
        }
    }

    /// Parses declared patterns, dropping anything malformed.
    ///
    /// `excluding` is the declaring app's own id: an app already sees its own
    /// events through `own(limit:)`, and a self-subscription would feed a
    /// delivery back to the source that produced it.
    ///
    /// **Drops rather than throws**, because a bad manifest entry must not stop
    /// an app from loading — a typo in one subscription line is not a reason
    /// for the user's app to disappear. The host surfaces the dropped entries
    /// as a `.host` warning at install, so a silent typo does not become a
    /// subscription that simply never fires.
    public static func parse(_ patterns: [String], excluding ownAppID: String? = nil)
    -> [SignalSubscription] {
        parseReportingInvalid(patterns, excluding: ownAppID).subscriptions
    }

    public static func parseReportingInvalid(_ patterns: [String],
                                            excluding ownAppID: String?) -> ParseResult {
        var subscriptions: [SignalSubscription] = []
        var invalid: [String] = []
        for pattern in patterns {
            if let parsed = parseOne(pattern, excluding: ownAppID) {
                subscriptions.append(parsed)
            } else {
                invalid.append(pattern)
            }
        }
        return ParseResult(subscriptions: subscriptions, invalid: invalid)
    }

    private static func parseOne(_ pattern: String, excluding ownAppID: String?)
    -> SignalSubscription? {
        // Split on the FIRST slash only: an app id cannot contain one (see
        // PluginValidation.isValidAppID) but a kind pattern is checked below,
        // and splitting on every slash would silently accept "a/b/c".
        guard let slash = pattern.firstIndex(of: "/") else { return nil }
        let sourceText = String(pattern[pattern.startIndex..<slash])
        let kindText = String(pattern[pattern.index(after: slash)...])
        guard !sourceText.isEmpty, !kindText.isEmpty, !kindText.contains("/") else { return nil }

        let source: SignalSource
        switch sourceText {
        case "host": source = .host
        case "sage": source = .sage
        case "*": return nil     // a blank cheque; see the type's documentation
        default:
            guard sourceText.hasPrefix("app:") else { return nil }
            let appID = String(sourceText.dropFirst("app:".count))
            guard !appID.isEmpty, appID != "*" else { return nil }
            guard appID != ownAppID else { return nil }
            source = .app(appID: appID)
        }

        if kindText == "*" {
            return SignalSubscription(source: source, kindPattern: "", isWildcard: true)
        }
        if kindText.hasSuffix(".*") {
            let prefix = String(kindText.dropLast(2))
            guard SignalKind.isValid(prefix) else { return nil }
            return SignalSubscription(source: source, kindPattern: prefix, isWildcard: true)
        }
        guard SignalKind.isValid(kindText) else { return nil }
        return SignalSubscription(source: source, kindPattern: kindText, isWildcard: false)
    }
}
