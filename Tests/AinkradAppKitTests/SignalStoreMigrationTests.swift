import Testing
import Foundation
import SQLite3
@testable import AinkradSignal

/// Schema v2 indexes `kind` in the search table. FTS5 external-content tables
/// cannot gain a column, so the migration DROPS and rebuilds — the only
/// destructive step in the notifications work, and the reason this suite is
/// separate and thorough.
@Suite("SignalStore schema migration")
struct SignalStoreMigrationTests {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("signal-migrate-\(UUID().uuidString).sqlite")
    }

    /// Builds a database in the EXACT v1 shape with raw SQL, rather than by
    /// calling `SignalStore` — which now creates v2 and so could never produce
    /// the "before" state this needs to migrate from.
    private func makeV1Database(at url: URL, rows: [(id: String, title: String,
                                                     body: String, kind: String)]) throws {
        var db: OpaquePointer?
        #expect(sqlite3_open(url.path, &db) == SQLITE_OK)
        defer { sqlite3_close(db) }
        let schema = """
        CREATE TABLE schema_meta (version INTEGER NOT NULL);
        INSERT INTO schema_meta (version) VALUES (1);
        CREATE TABLE events (
          id TEXT PRIMARY KEY, timestamp REAL NOT NULL, source_kind TEXT NOT NULL,
          source_app_id TEXT, kind TEXT NOT NULL, severity TEXT NOT NULL,
          title TEXT NOT NULL, body TEXT, importance TEXT NOT NULL,
          deep_link BLOB, actions BLOB, dedupe_key TEXT,
          dedupe_count INTEGER NOT NULL DEFAULT 1, read_at REAL,
          pinned INTEGER NOT NULL DEFAULT 0
        );
        CREATE VIRTUAL TABLE events_fts
          USING fts5(title, body, content='events', content_rowid='rowid');
        """
        #expect(sqlite3_exec(db, schema, nil, nil, nil) == SQLITE_OK)
        for row in rows {
            let insert = """
            INSERT INTO events (id, timestamp, source_kind, source_app_id, kind,
                                severity, title, body, importance)
            VALUES ('\(row.id)', 100.0, 'app', 'raven', '\(row.kind)', 'failure',
                    '\(row.title)', '\(row.body)', 'normal');
            INSERT INTO events_fts (rowid, title, body)
              SELECT rowid, title, body FROM events WHERE id = '\(row.id)';
            """
            #expect(sqlite3_exec(db, insert, nil, nil, nil) == SQLITE_OK)
        }
    }

    @Test("a v1 database migrates in place and keeps every row")
    func migratesWithoutLosingRows() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try makeV1Database(at: url, rows: (1...5).map {
            (id: UUID().uuidString, title: "Nightly \($0)", body: "three errors",
             kind: "build.failed")
        })

        let store = try SignalStore(url: url)     // migration runs in init

        #expect(store.page(filter: .all, before: nil, limit: .max).count == 5)
        #expect(store.search("nightly", filter: .all, limit: 10).count == 5,
                "the rebuild must repopulate title and body, not just add a column")
    }

    @Test("after migrating, an event is findable by its kind alone")
    func searchMatchesKindAfterMigration() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        // Nothing in the title or body says "failed" — only the kind does.
        try makeV1Database(at: url, rows: [
            (id: UUID().uuidString, title: "Nightly", body: "three errors",
             kind: "build.failed")
        ])

        let store = try SignalStore(url: url)

        #expect(store.search("failed", filter: .all, limit: 10).count == 1,
                "this is the whole point of v2: kind was unsearchable")
    }

    @Test("a database created fresh today also indexes kind")
    func freshDatabaseIndexesKind() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SignalStore(url: url)
        _ = try store.insert(SignalEvent(source: .app(appID: "raven"),
                                         kind: "build.failed", severity: .failure,
                                         title: "Nightly"))
        // The trap this guards: if `createV1` recorded the CURRENT schema
        // version, the v2 migration would be skipped on new databases and only
        // upgraded ones would have a searchable kind — a split that would show
        // up months later on one machine and not another.
        #expect(store.search("failed", filter: .all, limit: 10).count == 1)
    }

    @Test("an event inserted AFTER migrating is searchable by kind")
    func insertAfterMigrationIndexesKind() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try makeV1Database(at: url, rows: [
            (id: UUID().uuidString, title: "Old", body: "x", kind: "old.thing")
        ])

        let store = try SignalStore(url: url)
        _ = try store.insert(SignalEvent(source: .app(appID: "raven"),
                                         kind: "deploy.failed", severity: .failure,
                                         title: "New"))

        // Forgetting to update `insertFTS` is the silent half of this change:
        // migration would look fine and every NEW event would quietly stop
        // being searchable by kind, with nothing failing anywhere.
        #expect(store.search("deploy.failed", filter: .all, limit: 10).count == 1)
    }

    @Test("migrating twice is harmless")
    func migrationIsIdempotent() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        try makeV1Database(at: url, rows: [
            (id: UUID().uuidString, title: "Nightly", body: "x", kind: "build.failed")
        ])
        _ = try SignalStore(url: url)
        let reopened = try SignalStore(url: url)
        #expect(reopened.page(filter: .all, before: nil, limit: .max).count == 1)
        #expect(reopened.search("failed", filter: .all, limit: 10).count == 1)
    }

    @Test("an evicted event stops matching a search by its kind")
    func retentionRemovesKindTerms() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SignalStore(url: url)
        _ = try store.insert(SignalEvent(timestamp: Date(timeIntervalSince1970: 0),
                                         source: .app(appID: "raven"),
                                         kind: "build.failed", severity: .failure,
                                         title: "Ancient"))

        #expect(store.enforceRetention(RetentionPolicy(maxAgeDays: 1, maxEvents: 100)) == 1)

        // FTS5's external-content `'delete'` command needs the value of EVERY
        // indexed column to remove that row's terms. Now that `kind` is
        // indexed, a delete that still supplies only title and body leaves the
        // kind terms behind — and the row keeps matching a search after it has
        // been evicted. `enforceRetention` uses `try? exec`, so the malformed
        // statement fails silently and only this assertion catches it.
        #expect(store.search("failed", filter: .all, limit: 10).isEmpty,
                "a ghost: the event is gone but its kind still matches")
        #expect(store.search("Ancient", filter: .all, limit: 10).isEmpty)
    }

    @Test("an event evicted by the count cap also stops matching")
    func countEvictionRemovesKindTerms() throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SignalStore(url: url)
        // Recent timestamps on purpose: with epoch dates the AGE pass evicts
        // everything first and the count cap is never exercised.
        for i in 1...3 {
            _ = try store.insert(SignalEvent(timestamp: Date().addingTimeInterval(Double(i)),
                                             source: .app(appID: "raven"),
                                             kind: "build.evicted\(i)", severity: .info,
                                             title: "E\(i)"))
        }

        #expect(store.search("build.evicted3", filter: .all, limit: 10).count == 1,
                "a dotted kind is searchable in full, not only by its parts")

        _ = store.enforceRetention(RetentionPolicy(maxAgeDays: 3650, maxEvents: 1))

        #expect(store.search("evicted1", filter: .all, limit: 10).isEmpty)
        #expect(store.search("evicted3", filter: .all, limit: 10).count == 1,
                "the survivor must still be findable")
    }
}
