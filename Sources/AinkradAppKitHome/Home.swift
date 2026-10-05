import Foundation

/// Identifier for one app in the Ainkrad family (`"Lore"`, `"Quest"`, …).
public struct AppID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// Directories shared by the host and every app. Vault-resident by definition:
/// each holds authored or otherwise irreplaceable content.
public enum SharedDomain: String, CaseIterable, Sendable {
    case config, agents, memory, skills, commands, sessions, media, sounds

    var relativePath: String {
        switch self {
        case .config: return "Config"
        // `Sage/`, not `Sage/agents/`: the published layout puts `agents.json`
        // and `connections.json` as FILES directly under it, alongside the
        // `memory/`, `skills/`, `commands/` and `sessions/` subdirectories.
        // This domain is therefore Sage's document root, and `Sage/agents` was
        // never a location the layout contained.
        //
        // Named `Assistant/` until v0.16.2, when the app became Sage.
        // `HomeLayoutMigration` moves an existing tree; all five domains nest
        // under the one directory, so one move carries every one of them.
        case .agents: return "Sage"
        case .memory: return "Sage/memory"
        case .skills: return "Sage/skills"
        case .commands: return "Sage/commands"
        case .sessions: return "Sage/sessions"
        case .media: return "Media"
        case .sounds: return "Sounds"
        }
    }
}

/// A resolved Ainkrad Home: one user-chosen vault plus one machine-local cache.
///
/// The split rule is *authored or irreplaceable → vault; derivable → cache*, and
/// the invariant it exists to guarantee is that deleting `cacheRoot` entirely
/// loses nothing the user cannot get back.
public struct Home: Sendable, Hashable {
    public let vaultRoot: URL
    public let cacheRoot: URL

    public init(vaultRoot: URL, cacheRoot: URL) {
        self.vaultRoot = vaultRoot
        self.cacheRoot = cacheRoot
    }

    /// Authored data owned by one app.
    public func vault(app: AppID) -> URL {
        vaultRoot.appendingPathComponent("Apps", isDirectory: true)
            .appendingPathComponent(app.rawValue, isDirectory: true)
    }

    /// Disposable, machine-local data owned by one app.
    public func cache(app: AppID) -> URL {
        cacheRoot.appendingPathComponent("Apps", isDirectory: true)
            .appendingPathComponent(app.rawValue, isDirectory: true)
    }

    /// A directory shared across the family.
    public func shared(_ domain: SharedDomain) -> URL {
        domain.relativePath.split(separator: "/").reduce(vaultRoot) {
            $0.appendingPathComponent(String($1), isDirectory: true)
        }
    }
}
