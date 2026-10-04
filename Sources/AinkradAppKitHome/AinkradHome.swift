import Foundation

public enum HomeError: Error, Sendable, Equatable {
    case notWritable(URL)
    case nestedHome(URL)
    case systemLocation(URL)
    case doesNotExist(URL)
    /// The directory already holds someone else's files. Claiming it would put
    /// the vault on top of a folder another tool owns.
    case notEmpty(URL)
}

/// Outcome of looking for a configured Ainkrad Home.
///
/// `missing` is deliberately distinct from `unset`: falling back to a default
/// root when a configured vault is unreachable creates a second authoritative
/// home, and once the user has worked in both the divergence is unrecoverable.
public enum Resolution: Sendable {
    case unset
    case ready(Home)
    case missing(path: String)
    case foreign(url: URL)
}

public enum AinkradHome {
    /// Shared across the whole app family — note `Ainkrad`, not a bundle id.
    public static func defaultPointerDirectory() -> URL {
        let base =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Ainkrad", isDirectory: true)
    }

    public static func defaultCacheRoot(bundleID: String) -> URL {
        let base =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("Cache", isDirectory: true)
    }

    public static func resolve(
        pointerDirectory: URL = AinkradHome.defaultPointerDirectory(),
        cacheRoot: URL = AinkradHome.defaultCacheRoot(
            bundleID: Bundle.main.bundleIdentifier ?? "com.ainkrad.app")
    ) -> Resolution {
        guard let pointer = HomePointer.read(in: pointerDirectory) else { return .unset }
        let vault = URL(fileURLWithPath: pointer.path, isDirectory: true)

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: vault.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            return .missing(path: pointer.path)
        }
        guard let marker = (try? HomeMarker.read(in: vault)) ?? nil else {
            return .foreign(url: vault)
        }
        guard marker.homeID == pointer.homeID else { return .foreign(url: vault) }

        return .ready(Home(vaultRoot: vault, cacheRoot: cacheRoot))
    }

    /// Claim `url` as the Ainkrad Home: validate, ensure a marker, write the pointer.
    ///
    /// Adopting a directory that is already a home preserves its `homeID` — that
    /// is the reinstall-and-restore path, and it must not mint a new identity.
    @discardableResult
    public static func adopt(
        _ url: URL,
        pointerDirectory: URL = AinkradHome.defaultPointerDirectory(),
        cacheRoot: URL = AinkradHome.defaultCacheRoot(
            bundleID: Bundle.main.bundleIdentifier ?? "com.ainkrad.app")
    ) throws -> Home {
        try validate(url)

        let marker = try HomeMarker.read(in: url) ?? HomeMarker()
        try marker.write(to: url)

        let bookmark = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil)
        try HomePointer(path: url.path, homeID: marker.homeID, bookmark: bookmark)
            .write(to: pointerDirectory)

        try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
        return Home(vaultRoot: url, cacheRoot: cacheRoot)
    }

    /// Whether `url` may be claimed as a Home, without claiming it.
    ///
    /// Public because a folder picker has to be able to reject a choice BEFORE
    /// anything is written into it: the alternative is discovering the folder is
    /// unusable only from a failing `adopt`, after a migration has already copied
    /// data in. `adopt` calls this itself, so the check is never merely advisory.
    public static func validate(_ url: URL) throws {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw HomeError.doesNotExist(url)
        }
        guard fm.isWritableFile(atPath: url.path) else {
            throw HomeError.notWritable(url)
        }
        for forbidden in ["/System", "/Library", "/private", "/usr", "/bin", "/sbin", "/Applications"]
        where url.standardizedFileURL.path.hasPrefix(forbidden + "/")
            || url.standardizedFileURL.path == forbidden
        {
            throw HomeError.systemLocation(url)
        }
        // A directory may be claimed only when it is EMPTY, or when it is already
        // an Ainkrad Home (reinstall-and-restore, which must keep working however
        // full the vault is).
        //
        // Deliberately NOT a check for `.obsidian`/`.git`/`package.json`/…: an
        // allowlist of "markers that mean another tool owns this" can never be
        // complete, and the one time it is incomplete the app plants itself in
        // the middle of the user's data. Emptiness is the only property that is
        // decidable without enumerating every tool that could ever own a folder.
        //
        // `.DS_Store` is ignored: Finder writes it into any directory the user
        // merely opened, so counting it as content would refuse folders the user
        // just created for this purpose. Nothing else is ignored.
        if !fm.fileExists(atPath: HomeMarker.url(in: url).path) {
            let entries = (try? fm.contentsOfDirectory(atPath: url.path)) ?? []
            guard entries.allSatisfy({ $0 == ".DS_Store" }) else {
                throw HomeError.notEmpty(url)
            }
        }

        // Nested homes are never valid: two markers on one path make identity ambiguous.
        var parent = url.standardizedFileURL.deletingLastPathComponent()
        while parent.path != "/" && parent.path != parent.deletingLastPathComponent().path {
            if fm.fileExists(atPath: HomeMarker.url(in: parent).path) {
                throw HomeError.nestedHome(url)
            }
            parent = parent.deletingLastPathComponent()
        }
    }
}
