import Foundation
import Testing

@testable import AinkradAppKitHome

@Suite("Home URL vending")
struct HomeURLTests {
    private func makeHome() -> Home {
        Home(
            vaultRoot: URL(fileURLWithPath: "/tmp/vault"),
            cacheRoot: URL(fileURLWithPath: "/tmp/cache"))
    }

    @Test func vaultAppDirectoryIsUnderApps() {
        #expect(makeHome().vault(app: AppID("Lore")).path == "/tmp/vault/Apps/Lore")
    }

    @Test func cacheAppDirectoryIsUnderApps() {
        #expect(makeHome().cache(app: AppID("Lore")).path == "/tmp/cache/Apps/Lore")
    }

    @Test func sharedDomainsResolveUnderTheVault() {
        let home = makeHome()
        #expect(home.shared(.config).path == "/tmp/vault/Config")
        // `.agents` is the assistant DOCUMENT ROOT — the published layout has
        // `Assistant/agents.json`, a file, not an `Assistant/agents/` directory.
        #expect(home.shared(.agents).path == "/tmp/vault/Sage")
        #expect(home.shared(.sessions).path == "/tmp/vault/Sage/sessions")
        #expect(home.shared(.media).path == "/tmp/vault/Media")
    }

    /// The vault layout is user-visible and other apps in the family build
    /// against it, so it is pinned here against the published design rather than
    /// left to whatever the enum happens to say.
    @Test func sharedDomainsMatchThePublishedLayout() {
        let home = makeHome()
        let expected: [SharedDomain: String] = [
            .config: "/tmp/vault/Config",
            .agents: "/tmp/vault/Sage",
            .memory: "/tmp/vault/Sage/memory",
            .skills: "/tmp/vault/Sage/skills",
            .commands: "/tmp/vault/Sage/commands",
            .sessions: "/tmp/vault/Sage/sessions",
            .media: "/tmp/vault/Media",
            .sounds: "/tmp/vault/Sounds",
        ]
        #expect(expected.count == SharedDomain.allCases.count)
        for domain in SharedDomain.allCases {
            #expect(home.shared(domain).path == expected[domain])
        }
    }

    @Test func everySharedDomainHasADistinctPath() {
        let home = makeHome()
        let paths = Set(SharedDomain.allCases.map { home.shared($0).path })
        #expect(paths.count == SharedDomain.allCases.count)
    }
}

@Suite("Home resolution")
struct HomeResolutionTests {
    private func sandbox() -> (pointer: URL, cache: URL, vault: URL) {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("home-\(UUID().uuidString)")
        return (
            base.appendingPathComponent("pointer"),
            base.appendingPathComponent("cache"),
            base.appendingPathComponent("vault")
        )
    }

    @Test func noPointerResolvesToUnset() {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        guard case .unset = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("expected .unset")
            return
        }
    }

    @Test func adoptCreatesMarkerAndPointerThenResolvesReady() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)

        let home = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        #expect(home.vaultRoot.standardizedFileURL == s.vault.standardizedFileURL)
        #expect(
            FileManager.default.fileExists(
                atPath: s.vault.appendingPathComponent(".ainkrad-home").path))

        guard case .ready(let resolved) = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("expected .ready")
            return
        }
        #expect(resolved.vaultRoot.standardizedFileURL == s.vault.standardizedFileURL)
    }

    @Test func adoptingAnExistingHomePreservesItsIdentity() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)

        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        let firstID = try HomeMarker.read(in: s.vault)?.homeID
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        let secondID = try HomeMarker.read(in: s.vault)?.homeID

        #expect(firstID != nil)
        #expect(firstID == secondID, "re-adopting must not mint a new homeID")
    }

    @Test func vanishedVaultResolvesToMissingNotUnset() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)

        try FileManager.default.removeItem(at: s.vault)

        guard case .missing(let path) = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("expected .missing — a silent fallback is the bug this guards")
            return
        }
        #expect(path == s.vault.path)
    }

    @Test func folderWithoutAMarkerResolvesToForeign() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)

        try FileManager.default.removeItem(at: s.vault.appendingPathComponent(".ainkrad-home"))

        guard case .foreign = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("expected .foreign")
            return
        }
    }

    @Test func nestedHomeIsRejected() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)

        let inner = s.vault.appendingPathComponent("Inner")
        try FileManager.default.createDirectory(at: inner, withIntermediateDirectories: true)

        #expect(throws: HomeError.self) {
            _ = try AinkradHome.adopt(inner, pointerDirectory: s.pointer, cacheRoot: s.cache)
        }
    }

    // MARK: - Emptiness

    @Test func anEmptyDirectoryAdopts() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)

        let home = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        #expect(home.vaultRoot.standardizedFileURL == s.vault.standardizedFileURL)
    }

    /// Reinstall-and-restore: an existing Home is still adoptable however full it
    /// is, and keeps its identity.
    @Test func aDirectoryThatIsAlreadyAHomeAdoptsAndKeepsItsIdentity() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        let firstID = try HomeMarker.read(in: s.vault)?.homeID

        // Now it is populated — as a real vault in use would be.
        try FileManager.default.createDirectory(
            at: s.vault.appendingPathComponent("Config"),
            withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: s.vault.appendingPathComponent("Config/agents.json"))

        _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        #expect(firstID != nil)
        #expect(try HomeMarker.read(in: s.vault)?.homeID == firstID)
    }

    /// The incident this guards: a populated folder is somebody else's — an
    /// Obsidian vault, a git checkout, a Downloads directory. No allowlist of
    /// "owned by another tool" markers can ever be complete, so emptiness is the
    /// only property that is actually decidable here.
    @Test func aPopulatedDirectoryIsRefused() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        try Data("# notes".utf8).write(to: s.vault.appendingPathComponent("README.md"))

        #expect(throws: HomeError.notEmpty(s.vault)) {
            _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        }
        // And it must leave nothing behind in a folder it refused.
        #expect(
            !FileManager.default.fileExists(
                atPath: s.vault.appendingPathComponent(".ainkrad-home").path))
        guard case .unset = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("a refused adoption must leave no pointer")
            return
        }
    }

    /// Finder litters `.DS_Store` into any folder the user merely LOOKED at, so
    /// treating it as content would refuse most freshly created directories.
    @Test func aDirectoryContainingOnlyDSStoreCountsAsEmpty() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(at: s.vault, withIntermediateDirectories: true)
        try Data().write(to: s.vault.appendingPathComponent(".DS_Store"))

        let home = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        #expect(home.vaultRoot.standardizedFileURL == s.vault.standardizedFileURL)
    }

    /// A hidden entry is still content — `.git`/`.obsidian` reach this path, and
    /// they must be refused by the general rule rather than by being named.
    @Test func aHiddenEntryOtherThanDSStoreCountsAsContent() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        try FileManager.default.createDirectory(
            at: s.vault.appendingPathComponent(".obsidian"), withIntermediateDirectories: true)

        #expect(throws: HomeError.notEmpty(s.vault)) {
            _ = try AinkradHome.adopt(s.vault, pointerDirectory: s.pointer, cacheRoot: s.cache)
        }
    }

    @Test func failedAdoptionWritesNoPointer() throws {
        let s = sandbox()
        defer { try? FileManager.default.removeItem(at: s.pointer.deletingLastPathComponent()) }
        let missing = s.vault.appendingPathComponent("does-not-exist")

        _ = try? AinkradHome.adopt(missing, pointerDirectory: s.pointer, cacheRoot: s.cache)

        guard case .unset = AinkradHome.resolve(pointerDirectory: s.pointer, cacheRoot: s.cache) else {
            Issue.record("a failed adoption must leave no pointer")
            return
        }
    }
}
