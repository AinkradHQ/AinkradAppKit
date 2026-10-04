import Foundation
import Testing

@testable import AinkradAppKitHome

@Suite("HomeLayoutMigration")
struct HomeLayoutMigrationTests {
    private func makeVault() throws -> URL {
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func seedAssistantTree(in vault: URL) throws {
        let assistant = vault.appending(path: "Assistant")
        for sub in ["memory", "skills", "commands", "sessions"] {
            try FileManager.default.createDirectory(
                at: assistant.appending(path: sub), withIntermediateDirectories: true)
        }
        try Data("{}".utf8).write(to: assistant.appending(path: "connections.json"))
        try Data("[]".utf8).write(to: assistant.appending(path: "agents.json"))
        try Data("note".utf8).write(to: assistant.appending(path: "memory/USER.md"))
    }

    @Test("carries every assistant-owned domain onto Sage in one move")
    func movesWholeTree() throws {
        let vault = try makeVault()
        try seedAssistantTree(in: vault)

        let outcomes = HomeLayoutMigration.run(vaultRoot: vault)

        #expect(outcomes == [.moved(from: "Assistant", to: "Sage")])
        let fm = FileManager.default
        #expect(!fm.fileExists(atPath: vault.appending(path: "Assistant").path))
        // Every domain, not just the root: SharedDomain nests all five here.
        for path in [
            "Sage/connections.json", "Sage/agents.json", "Sage/memory/USER.md",
            "Sage/skills", "Sage/commands", "Sage/sessions",
        ] {
            #expect(fm.fileExists(atPath: vault.appending(path: path).path), "missing \(path)")
        }
        let kept = try Data(contentsOf: vault.appending(path: "Sage/memory/USER.md"))
        #expect(String(decoding: kept, as: UTF8.self) == "note")
    }

    @Test("refuses to merge when Sage already exists, and destroys nothing")
    func doesNotMerge() throws {
        let vault = try makeVault()
        try seedAssistantTree(in: vault)
        let sage = vault.appending(path: "Sage")
        try FileManager.default.createDirectory(at: sage, withIntermediateDirectories: true)
        try Data("current".utf8).write(to: sage.appending(path: "connections.json"))

        let outcomes = HomeLayoutMigration.run(vaultRoot: vault)

        #expect(outcomes == [.blocked(from: "Assistant", to: "Sage")])
        let kept = try Data(contentsOf: sage.appending(path: "connections.json"))
        #expect(String(decoding: kept, as: UTF8.self) == "current")
        // The old tree is left intact rather than deleted.
        #expect(
            FileManager.default.fileExists(
                atPath: vault.appending(path: "Assistant/connections.json").path))
    }

    @Test("is idempotent")
    func idempotent() throws {
        let vault = try makeVault()
        try seedAssistantTree(in: vault)

        #expect(HomeLayoutMigration.run(vaultRoot: vault) == [.moved(from: "Assistant", to: "Sage")])
        #expect(HomeLayoutMigration.run(vaultRoot: vault) == [])
    }

    @Test("is a no-op on a fresh vault and on a missing root")
    func noOpWhenNothingToDo() throws {
        let fresh = try makeVault()
        #expect(HomeLayoutMigration.run(vaultRoot: fresh) == [])

        let missing = URL.temporaryDirectory.appending(path: UUID().uuidString)
        #expect(HomeLayoutMigration.run(vaultRoot: missing) == [])
        #expect(!FileManager.default.fileExists(atPath: missing.path))
    }

    @Test("the migration targets exactly what SharedDomain now resolves to")
    func agreesWithSharedDomain() throws {
        let vault = try makeVault()
        try seedAssistantTree(in: vault)
        HomeLayoutMigration.run(vaultRoot: vault)

        // The invariant that keeps the two from drifting apart: after
        // migrating, every assistant-owned domain must resolve to a real path.
        let home = Home(vaultRoot: vault, cacheRoot: vault.appending(path: "cache"))
        for domain in [SharedDomain.agents, .memory, .skills, .commands, .sessions] {
            #expect(
                FileManager.default.fileExists(atPath: home.shared(domain).path),
                "\(domain) does not exist after migration")
        }
    }
}
