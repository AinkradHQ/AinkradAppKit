import Foundation

/// Moves a vault laid out by an older Ainkrad onto the current
/// `SharedDomain` paths.
///
/// One entry so far: the v0.16.2 rename of `<vault>/Assistant/` to
/// `<vault>/Sage/`, following the app itself. All five assistant-owned domains
/// (`agents`, `memory`, `skills`, `commands`, `sessions`) nest under that one
/// directory, so a single move carries every one of them.
///
/// **This moves authored, irreplaceable content** — connections, memory,
/// skills, custom commands and session history. It is therefore deliberately
/// conservative, and copies the rules the vault-adoption work arrived at the
/// hard way:
///
/// - it moves only when the source exists AND the destination does not, so it
///   can never merge two trees or overwrite newer state;
/// - it never deletes: a move that cannot complete leaves the original exactly
///   where it was, and the app starts empty — visible and recoverable — rather
///   than destroying data on a path it could not reason about;
/// - it is idempotent, so running it on every launch costs one `fileExists`.
public enum HomeLayoutMigration {
    /// The renames applied to a vault root, oldest first.
    static let directoryRenames: [(old: String, new: String)] = [
        ("Assistant", "Sage")
    ]

    /// Result of one run, so a caller can log or test what happened without
    /// reaching into the filesystem itself.
    public enum Outcome: Equatable, Sendable {
        case moved(from: String, to: String)
        case blocked(from: String, to: String)
        case failed(from: String, to: String)
    }

    @discardableResult
    public static func run(vaultRoot: URL, fileManager: FileManager = .default) -> [Outcome] {
        var outcomes: [Outcome] = []
        guard fileManager.fileExists(atPath: vaultRoot.path) else { return outcomes }

        for rename in directoryRenames {
            let source = vaultRoot.appendingPathComponent(rename.old, isDirectory: true)
            let destination = vaultRoot.appendingPathComponent(rename.new, isDirectory: true)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            guard !fileManager.fileExists(atPath: destination.path) else {
                outcomes.append(.blocked(from: rename.old, to: rename.new))
                continue
            }
            do {
                try fileManager.moveItem(at: source, to: destination)
                outcomes.append(.moved(from: rename.old, to: rename.new))
            } catch {
                outcomes.append(.failed(from: rename.old, to: rename.new))
            }
        }
        return outcomes
    }
}
