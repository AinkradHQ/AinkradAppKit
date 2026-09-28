import Foundation

/// One shape for "open this, in that app" — so Hoard, Rune and anything added
/// later all speak the same thing.
///
/// Rides the existing opaque-string payload on `PluginAppLauncher`, which needs
/// no change: the payload was always "apps agree on their own encoding", and
/// this is that agreement written down once instead of per sender.
///
/// `kind` is checked BEFORE decoding the rest. Rune's launch seam learned this
/// the hard way: it was typed as `SSHLaunchPayload?`, so a second payload kind
/// was silently eaten by a decoder that could not represent it.
public struct AinkradLaunchIntent: Codable, Equatable, Sendable {
    /// Open a document at `path`. The only kind so far; the field exists so a
    /// second one can be added without the first's readers mis-decoding it.
    public static let openDocumentKind = "openDocument"

    public let kind: String
    public let path: String
    /// Which mode the target should open in, when it has one. `nil` leaves the
    /// app's own default alone — a sender that does not care must not override
    /// the user's setting by accident.
    public let mode: PluginMode?

    public init(kind: String = AinkradLaunchIntent.openDocumentKind,
                path: String,
                mode: PluginMode? = nil) {
        self.kind = kind
        self.path = path
        self.mode = mode
    }

    public var isOpenDocument: Bool { kind == Self.openDocumentKind }

    /// JSON for the launcher's payload, or nil if it cannot be encoded.
    public var json: String? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    /// Decodes a payload, returning nil for anything that is not one of these.
    ///
    /// Deliberately tolerant: a payload of another kind is NOT an error, it is
    /// simply not ours, and a receiver that treats "not mine" as a failure is
    /// how one app's launch breaks another's.
    public static func decode(_ payload: String?) -> AinkradLaunchIntent? {
        guard let payload, let data = payload.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AinkradLaunchIntent.self, from: data)
    }
}
