import Testing
import Foundation
@testable import AinkradSignal

@Suite("SignalStore")
struct SignalStoreTests {
    /// Real SQLite on a temp file — an in-memory fake would not exercise the
    /// schema, the indexes, or the FTS synchronization, which is where the
    /// bugs live.
    private func makeStore() throws -> (SignalStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("signal-\(UUID().uuidString).sqlite")
        return (try SignalStore(url: url), url)
    }

    private func event(_ title: String,
                       source: SignalSource = .host,
                       kind: String = "test.event",
                       severity: SignalSeverity = .info,
                       at seconds: TimeInterval = 1000,
                       dedupeKey: String? = nil) -> SignalEvent {
        SignalEvent(timestamp: Date(timeIntervalSince1970: seconds), source: source,
                    kind: kind, severity: severity, title: title, dedupeKey: dedupeKey)
    }

    @Test("rowStates reports pinned, so the UI can show what it set")
    func rowStatesReportPinned() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let e = event("a")
        _ = try store.insert(e)
        #expect(store.rowStates(limit: 10)[e.id]?.isPinned == false)

        store.setPinned(true, id: e.id)

        // `setPinned` has been writable since M1 while nothing could read the
        // flag back, so the UI could set a state it could not then display —
        // which is why the pin control was never built.
        #expect(store.rowStates(limit: 10)[e.id]?.isPinned == true)
    }

    @Test("a pinned row survives clearing the feed")
    func pinnedSurvivesClear() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let kept = event("kept", at: 10)
        let dropped = event("dropped", at: 20)
        _ = try store.insert(kept)
        _ = try store.insert(dropped)
        store.setPinned(true, id: kept.id)

        _ = store.enforceRetention(RetentionPolicy(maxAgeDays: 0, maxEvents: 0))

        // The exemption the Settings copy has promised since M1.
        #expect(store.event(id: kept.id) != nil)
        #expect(store.event(id: dropped.id) == nil)
    }

    @Test("markUnread clears the read stamp, so a row can be triaged again")
    func markUnread() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let e = event("a", source: .app(appID: "raven"))
        _ = try store.insert(e)
        store.markRead(ids: [e.id])
        #expect(store.unreadCounts().isEmpty)

        store.markUnread(ids: [e.id])

        #expect(store.unreadCounts()[.app(appID: "raven")] == 1)
        #expect(store.rowStates(limit: 10)[e.id]?.isRead == false)
    }

    @Test("delete removes the row and stops it matching a search")
    func deleteRemovesRowAndIndex() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let keep = event("Keeper", source: .app(appID: "raven"), kind: "build.kept")
        let drop = event("Dropped", source: .app(appID: "raven"), kind: "build.dropped")
        _ = try store.insert(keep)
        _ = try store.insert(drop)

        store.delete(ids: [drop.id])

        #expect(store.event(id: drop.id) == nil)
        #expect(store.event(id: keep.id) != nil)
        // The FTS row must go too. External-content FTS does not cascade, so a
        // stale index row makes a deleted event keep turning up in search —
        // and the user cannot get rid of it because the thing they would
        // delete is already gone.
        #expect(store.search("Dropped", filter: .all, limit: 10).isEmpty)
        #expect(store.search("build.dropped", filter: .all, limit: 10).isEmpty)
        #expect(store.search("Keeper", filter: .all, limit: 10).count == 1)
    }

    @Test("deleting an unread row drops its unread count")
    func deleteUpdatesUnreadCount() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let e = event("a", source: .app(appID: "raven"))
        _ = try store.insert(e)
        store.delete(ids: [e.id])
        #expect(store.unreadCounts().isEmpty)
    }

    @Test("deleting nothing is harmless")
    func deleteEmpty() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("a"))
        store.delete(ids: [])
        #expect(store.page(filter: .all, before: nil, limit: 10).count == 1)
    }

    @Test("kindActivity reports each kind a source emits, with counts")
    func kindActivityPerSource() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let raven = SignalSource.app(appID: "raven")
        _ = try store.insert(event("a", source: raven, kind: "build.failed", at: 100))
        _ = try store.insert(event("b", source: raven, kind: "build.failed", at: 300))
        _ = try store.insert(event("c", source: raven, kind: "build.warning", at: 200))
        _ = try store.insert(event("d", source: .host, kind: "host.thing", at: 400))

        let activity = store.kindActivity(for: raven, since: nil)

        #expect(activity.map(\.kind) == ["build.failed", "build.warning"],
                "newest first, so the thing that just happened is at the top")
        #expect(activity.first?.count == 2)
        #expect(activity.first?.lastSeen == Date(timeIntervalSince1970: 300))
        #expect(!activity.contains { $0.kind == "host.thing" }, "another source's kinds")
    }

    @Test("kindActivity works for host, whose app id column is null")
    func kindActivityForHost() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("a", source: .host, kind: "signal.degraded"))
        _ = try store.insert(event("b", source: .app(appID: "raven"), kind: "build.failed"))

        let activity = store.kindActivity(for: .host, since: nil)

        // The null app id is why this needs `IS` and not `=`: a plain equality
        // test against NULL matches nothing in SQLite, so host would silently
        // report no kinds at all.
        #expect(activity.map(\.kind) == ["signal.degraded"])
    }

    @Test("kindActivity honours a since cutoff")
    func kindActivitySince() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let raven = SignalSource.app(appID: "raven")
        _ = try store.insert(event("old", source: raven, kind: "build.failed", at: 100))
        _ = try store.insert(event("new", source: raven, kind: "build.warning", at: 900))

        let activity = store.kindActivity(for: raven,
                                          since: Date(timeIntervalSince1970: 500))

        #expect(activity.map(\.kind) == ["build.warning"])
    }

    @Test("kindActivity on a source that never spoke is empty, not an error")
    func kindActivityEmpty() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(store.kindActivity(for: .app(appID: "nobody"), since: nil).isEmpty)
    }

    @Test("event(id:) returns a stored event, and nil for an unknown id")
    func eventByID() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let e = event("Build failed", source: .app(appID: "raven"),
                      kind: "build.failed", severity: .failure)
        _ = try store.insert(e)

        let found = try #require(store.event(id: e.id))
        #expect(found.title == "Build failed")
        #expect(found.source == .app(appID: "raven"))
        #expect(found.severity == .failure)
        #expect(store.event(id: UUID()) == nil)
    }

    @Test("inserts an event and reads it back whole")
    func insertAndRead() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let e = SignalEvent(source: .app(appID: "raven"), kind: "build.failed",
                            severity: .failure, title: "Build failed", body: "3 errors",
                            proposedImportance: .urgent,
                            deepLink: SignalDeepLink(appID: "raven", payload: Data([0x07])),
                            actions: [SignalAction(id: "retry", label: "Retry")],
                            dedupeKey: "b:main")
        #expect(try store.insert(e) == .inserted)
        let page = store.page(filter: .all, before: nil, limit: 10)
        #expect(page.count == 1)
        #expect(page[0] == e)
    }

    @Test("pages newest first and honours the limit and cursor")
    func paging() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        for i in 0..<5 { _ = try store.insert(event("e\(i)", at: TimeInterval(1000 + i))) }
        let first = store.page(filter: .all, before: nil, limit: 2)
        #expect(first.map(\.title) == ["e4", "e3"])
        let next = store.page(filter: .all, before: first.last?.timestamp, limit: 2)
        #expect(next.map(\.title) == ["e2", "e1"])
    }

    @Test("filters by source and by severity")
    func filtering() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("h", source: .host, severity: .info, at: 1))
        _ = try store.insert(event("r", source: .app(appID: "raven"), severity: .failure, at: 2))
        _ = try store.insert(event("q", source: .app(appID: "quest"), severity: .failure, at: 3))

        var bySource = SignalFilter.all
        bySource.sources = [.app(appID: "raven")]
        #expect(store.page(filter: bySource, before: nil, limit: 10).map(\.title) == ["r"])

        var bySeverity = SignalFilter.all
        bySeverity.severities = [.failure]
        #expect(store.page(filter: bySeverity, before: nil, limit: 10).map(\.title) == ["q", "r"])
    }

    @Test("reopening the same file keeps the events")
    func durability() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("persisted"))
        _ = store   // close by scope
        let reopened = try SignalStore(url: url)
        #expect(reopened.page(filter: .all, before: nil, limit: 10).map(\.title) == ["persisted"])
    }
}
