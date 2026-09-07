import Testing
import Foundation
@testable import AinkradSignal

@Suite("SignalStore read state, search and retention")
struct SignalStoreRetentionTests {
    private func makeStore() throws -> (SignalStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("signal-\(UUID().uuidString).sqlite")
        return (try SignalStore(url: url), url)
    }

    private func event(_ title: String, body: String? = nil,
                       source: SignalSource = .host,
                       at seconds: TimeInterval) -> SignalEvent {
        SignalEvent(timestamp: Date(timeIntervalSince1970: seconds), source: source,
                    kind: "test.event", severity: .info, title: title, body: body)
    }

    @Test("unread counts are per source and drop as rows are read")
    func unreadCounts() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let a = event("a", source: .host, at: 1)
        let b = event("b", source: .app(appID: "raven"), at: 2)
        let c = event("c", source: .app(appID: "raven"), at: 3)
        for e in [a, b, c] { _ = try store.insert(e) }
        #expect(store.unreadCounts()[.app(appID: "raven")] == 2)
        #expect(store.unreadCounts()[.host] == 1)
        store.markRead(ids: [b.id])
        #expect(store.unreadCounts()[.app(appID: "raven")] == 1)
        store.markAllRead(filter: .all)
        #expect(store.unreadCounts().isEmpty)
    }

    @Test("full-text search finds title and body, honouring filters")
    func search() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("Build failed", body: "SignalStore.swift", source: .host, at: 1))
        _ = try store.insert(event("Index completed", body: "vault", source: .app(appID: "lore"), at: 2))
        #expect(store.search("build", filter: .all, limit: 10).map(\.title) == ["Build failed"])
        #expect(store.search("vault", filter: .all, limit: 10).map(\.title) == ["Index completed"])
        var hostOnly = SignalFilter.all
        hostOnly.sources = [.host]
        #expect(store.search("vault", filter: hostOnly, limit: 10).isEmpty)
    }

    @Test("retention evicts oldest first past the count cap")
    func retentionByCount() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        // Recent timestamps on purpose: a 1970 timestamp is older than ANY age
        // cap, so the age pass would evict everything and this test would never
        // reach the count cap it exists to check.
        let now = Date().timeIntervalSince1970
        for i in 0..<10 { _ = try store.insert(event("e\(i)", at: now + TimeInterval(i))) }
        let evicted = store.enforceRetention(RetentionPolicy(maxAgeDays: 3650, maxEvents: 4))
        #expect(evicted == 6)
        #expect(store.page(filter: .all, before: nil, limit: 20).map(\.title) == ["e9", "e8", "e7", "e6"])
    }

    @Test("retention evicts past the age cap")
    func retentionByAge() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let now = Date()
        _ = try store.insert(event("old", at: now.addingTimeInterval(-40 * 86400).timeIntervalSince1970))
        _ = try store.insert(event("new", at: now.timeIntervalSince1970))
        #expect(store.enforceRetention(RetentionPolicy(maxAgeDays: 30, maxEvents: 10_000)) == 1)
        #expect(store.page(filter: .all, before: nil, limit: 10).map(\.title) == ["new"])
    }

    @Test("pinned rows survive both caps and do not count toward the limit")
    func pinnedExempt() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let ancient = event("ancient", at: Date().addingTimeInterval(-400 * 86400).timeIntervalSince1970)
        _ = try store.insert(ancient)
        store.setPinned(true, id: ancient.id)
        for i in 0..<10 { _ = try store.insert(event("e\(i)", at: Date().timeIntervalSince1970 + TimeInterval(i))) }
        _ = store.enforceRetention(RetentionPolicy(maxAgeDays: 30, maxEvents: 4))
        let titles = store.page(filter: .all, before: nil, limit: 20).map(\.title)
        #expect(titles.contains("ancient"), "pinned rows are exempt from age eviction")
        #expect(titles.filter { $0 != "ancient" }.count == 4, "pinned rows do not consume the count cap")
    }

    @Test("eviction removes the FTS row too, so search cannot resurrect it")
    func evictionClearsFTS() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        // Recent, for the same reason as `retentionByCount`: this test is about
        // the count cap taking the FTS row with it, not about the age cap.
        let now = Date().timeIntervalSince1970
        _ = try store.insert(event("doomed", body: "vanishing", at: now))
        _ = try store.insert(event("kept", body: "staying", at: now + 1))
        _ = store.enforceRetention(RetentionPolicy(maxAgeDays: 3650, maxEvents: 1))
        #expect(store.search("vanishing", filter: .all, limit: 10).isEmpty)
        #expect(store.search("staying", filter: .all, limit: 10).count == 1)
    }
}

@Suite("SignalStore row state")
struct SignalStoreRowStateTests {
    private func makeStore() throws -> (SignalStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("signal-\(UUID().uuidString).sqlite")
        return (try SignalStore(url: url), url)
    }

    @Test("row state reports read flags and coalesce counts")
    func rowStates() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let now = Date()
        let repeated = SignalEvent(timestamp: now, source: .host, kind: "build.failed",
                                   severity: .failure, title: "repeated", dedupeKey: "k")
        let plain = SignalEvent(timestamp: now.addingTimeInterval(1), source: .host,
                                kind: "test.event", severity: .info, title: "plain")
        _ = try store.insert(repeated)
        _ = try store.insert(SignalEvent(timestamp: now.addingTimeInterval(2), source: .host,
                                         kind: "build.failed", severity: .failure,
                                         title: "repeated", dedupeKey: "k"))
        _ = try store.insert(plain)
        store.markRead(ids: [plain.id])

        let states = store.rowStates(limit: 50)
        #expect(states[repeated.id]?.repeatCount == 2)
        #expect(states[repeated.id]?.isRead == false)
        #expect(states[plain.id]?.isRead == true)
        #expect(states[plain.id]?.repeatCount == 1)
    }
}
