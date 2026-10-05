import Foundation
import SQLite3

extension SignalStore {
    // MARK: - read state

    public func markRead(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        let list = ids.map { "'\(Self.escape($0.uuidString))'" }.joined(separator: ",")
        try? exec("UPDATE events SET read_at = \(Self.sqlTime(Date())) WHERE id IN (\(list));")
    }

    /// Clears the read stamp, so a row can be put back on the pile.
    ///
    /// The counterpart `markRead` never had. Without it the feed can only be
    /// triaged in one direction: a row read by accident — or read, then found
    /// to matter — cannot be restored, and the unread count is a number the
    /// user can only ever push down.
    public func markUnread(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        let list = ids.map { "'\(Self.escape($0.uuidString))'" }.joined(separator: ",")
        try? exec("UPDATE events SET read_at = NULL WHERE id IN (\(list));")
    }

    /// Removes rows outright, index included.
    ///
    /// Deliberately not soft-deleted: the feed already has retention for
    /// "old enough to forget" and pinning for "never forget". A third state
    /// would be a filing system, and the row the user dismissed is one they
    /// have said they are done with.
    public func delete(ids: [UUID]) {
        guard !ids.isEmpty else { return }
        let list = ids.map { "'\(Self.escape($0.uuidString))'" }.joined(separator: ",")
        try? exec("BEGIN IMMEDIATE;")
        // FTS first, while the source rows still exist to supply the values —
        // and EVERY indexed column, because FTS5 reconstructs the row's terms
        // from what is given. External content does not cascade: skip this and
        // a deleted event keeps matching searches, which the user cannot fix
        // because the thing they would delete is already gone.
        try? exec(
            """
            INSERT INTO events_fts (events_fts, rowid, title, body, kind)
            SELECT 'delete', rowid, title, body, kind FROM events WHERE id IN (\(list));
            """)
        try? exec("DELETE FROM events WHERE id IN (\(list));")
        try? exec("COMMIT;")
    }

    public func markAllRead(filter: SignalFilter) {
        var clauses: [String] = ["read_at IS NULL"]
        var binder: [(OpaquePointer?, Int32) -> Void] = []
        appendFilterClauses(filter, into: &clauses, binder: &binder)
        try? exec(
            "UPDATE events SET read_at = \(Self.sqlTime(Date())) WHERE "
                + clauses.joined(separator: " AND ") + ";")
    }

    public func unreadCounts() -> [SignalSource: Int] {
        let sql = """
            SELECT source_kind, source_app_id, COUNT(*) FROM events
            WHERE read_at IS NULL GROUP BY source_kind, source_app_id;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [:] }
        defer { sqlite3_finalize(stmt) }
        var out: [SignalSource: Int] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            let source = Self.compose(kind: Self.text(stmt, 0) ?? "host", appID: Self.text(stmt, 1))
            out[source] = Int(sqlite3_column_int(stmt, 2))
        }
        return out
    }

    public func setPinned(_ pinned: Bool, id: UUID) {
        try? exec("UPDATE events SET pinned = \(pinned ? 1 : 0) WHERE id = '\(Self.escape(id.uuidString))';")
    }

    /// Per-row presentation state that is NOT part of the event envelope.
    ///
    /// `read_at` and `dedupe_count` are host bookkeeping: `SignalEvent` is the
    /// plugin-facing type and must not grow fields an app has no business
    /// seeing. Returned as a side table keyed by event id so the feed can
    /// render unread dots and `xN` badges without either concern leaking into
    /// the envelope.
    public struct SignalRowState: Sendable, Equatable {
        public let isRead: Bool
        public let repeatCount: Int
        /// Exempt from retention and from clearing the feed. Reported here
        /// because `setPinned` has been writable since M1 while nothing could
        /// READ the flag back — so the UI could set a state it could not then
        /// show, which is why the control was never built.
        public let isPinned: Bool

        public init(isRead: Bool, repeatCount: Int) {
            self.isRead = isRead
            self.repeatCount = repeatCount
            self.isPinned = false
        }

        /// Separate, not a defaulted parameter — library evolution, see
        /// `SignalDeepLink.init(appID:payload:locator:)`.
        public init(isRead: Bool, repeatCount: Int, isPinned: Bool) {
            self.isRead = isRead
            self.repeatCount = repeatCount
            self.isPinned = isPinned
        }
    }

    public func rowStates(limit: Int) -> [UUID: SignalRowState] {
        let sql = """
            SELECT id, read_at, dedupe_count, pinned FROM events
            ORDER BY timestamp DESC LIMIT ?;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [:] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(max(0, min(limit, Int(Int32.max)))))
        var out: [UUID: SignalRowState] = [:]
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let idText = Self.text(stmt, 0), let id = UUID(uuidString: idText) else { continue }
            let isRead = sqlite3_column_type(stmt, 1) != SQLITE_NULL
            out[id] = SignalRowState(
                isRead: isRead,
                repeatCount: Int(sqlite3_column_int(stmt, 2)),
                isPinned: sqlite3_column_int(stmt, 3) != 0)
        }
        return out
    }

    // MARK: - search

    public func search(_ query: String, filter: SignalFilter, limit: Int) -> [SignalEvent] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var clauses: [String] = ["events.rowid IN (SELECT rowid FROM events_fts WHERE events_fts MATCH ?)"]
        var binder: [(OpaquePointer?, Int32) -> Void] = []
        appendFilterClauses(filter, into: &clauses, binder: &binder)
        let sql = """
            SELECT \(Self.columns) FROM events
            WHERE \(clauses.joined(separator: " AND "))
            ORDER BY timestamp DESC LIMIT ?;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        bind(stmt, 1, Self.ftsQuery(trimmed))
        var index: Int32 = 2
        for bindOne in binder {
            bindOne(stmt, index)
            index += 1
        }
        sqlite3_bind_int(stmt, index, Int32(max(0, min(limit, Int(Int32.max)))))
        var out: [SignalEvent] = []
        while sqlite3_step(stmt) == SQLITE_ROW { if let e = Self.event(from: stmt) { out.append(e) } }
        return out
    }

    /// Prefix-match each token, quoted so FTS5 operators in user input are inert.
    /// Same treatment as `MemoryIndex.ftsQuery`.
    static func ftsQuery(_ raw: String) -> String {
        raw.split(separator: " ")
            .map { "\"\($0.replacingOccurrences(of: "\"", with: ""))\"*" }
            .joined(separator: " ")
    }

    // MARK: - retention

    /// Evicts oldest-first past either cap. Returns the number of rows removed.
    /// Pinned rows are never evicted and are excluded from the count cap.
    @discardableResult
    public func enforceRetention(_ policy: RetentionPolicy) -> Int {
        guard !isReadOnly else { return 0 }
        let cutoff = Self.sqlTime(Date()) - Double(policy.maxAgeDays) * 86400
        let before = rowCount()
        try? exec("BEGIN IMMEDIATE;")
        // FTS first, in both passes: external-content FTS needs its rows
        // deleted while the source rows still exist to supply the values.
        //
        // EVERY indexed column must be listed. FTS5's `'delete'` command
        // reconstructs the row's terms from the values given, so omitting one
        // makes the statement wrong — and `try? exec` swallows the failure, so
        // the only symptom is a search index that quietly stops agreeing with
        // the table. Adding a column to `events_fts` means editing here too.
        try? exec(
            """
            INSERT INTO events_fts (events_fts, rowid, title, body, kind)
            SELECT 'delete', rowid, title, body, kind FROM events
            WHERE pinned = 0 AND timestamp < \(cutoff);
            """)
        try? exec("DELETE FROM events WHERE pinned = 0 AND timestamp < \(cutoff);")
        try? exec(
            """
            INSERT INTO events_fts (events_fts, rowid, title, body, kind)
            SELECT 'delete', rowid, title, body, kind FROM events WHERE pinned = 0 AND rowid NOT IN (
              SELECT rowid FROM events WHERE pinned = 0 ORDER BY timestamp DESC LIMIT \(policy.maxEvents)
            );
            """)
        try? exec(
            """
            DELETE FROM events WHERE pinned = 0 AND rowid NOT IN (
              SELECT rowid FROM events WHERE pinned = 0 ORDER BY timestamp DESC LIMIT \(policy.maxEvents)
            );
            """)
        try? exec("COMMIT;")
        return before - rowCount()
    }

    private func rowCount() -> Int {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM events;", -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 0
    }

    // MARK: - dedupe

    struct CoalesceTarget {
        let rowID: Int64
        let id: UUID
    }

    /// The most recent row with this `(source, dedupeKey)` whose timestamp is
    /// inside the window. Windowed, not global — see the non-unique index.
    func coalescibleRow(source: SignalSource, key: String, at date: Date) -> CoalesceTarget? {
        let (kindText, appID) = Self.decompose(source)
        let sql = """
            SELECT rowid, id FROM events
            WHERE source_kind = ? AND (? IS NULL OR source_app_id = ?)
              AND dedupe_key = ? AND timestamp > ?
            ORDER BY timestamp DESC LIMIT 1;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        bind(stmt, 1, kindText)
        if let appID {
            bind(stmt, 2, appID)
            bind(stmt, 3, appID)
        } else {
            sqlite3_bind_null(stmt, 2)
            sqlite3_bind_null(stmt, 3)
        }
        bind(stmt, 4, key)
        sqlite3_bind_double(stmt, 5, Self.sqlTime(date) - Self.dedupeWindow)
        guard sqlite3_step(stmt) == SQLITE_ROW,
            let idText = Self.text(stmt, 1), let id = UUID(uuidString: idText)
        else { return nil }
        return CoalesceTarget(rowID: sqlite3_column_int64(stmt, 0), id: id)
    }

    /// Advances the row to the newest occurrence and increments its count. The
    /// row is also re-marked unread: a repeat is new information.
    /// Folds a repeat into the row it coalesced with. The row takes the
    /// repeat's title, body and deep link as well as its time: a burst of chat
    /// messages is one entry showing the NEWEST message, not the first one
    /// re-announced. The FTS row is rewritten with it (external content does
    /// not follow an UPDATE), inside one transaction.
    func bumpCoalesced(rowID: Int64, id: UUID, to event: SignalEvent) throws {
        try exec("BEGIN IMMEDIATE;")
        do {
            try exec(
                """
                INSERT INTO events_fts (events_fts, rowid, title, body, kind)
                SELECT 'delete', rowid, title, body, kind FROM events WHERE rowid = \(rowID);
                """)
            let sql = """
                UPDATE events SET timestamp = ?, dedupe_count = dedupe_count + 1, read_at = NULL,
                                  title = ?, body = ?, deep_link = ?
                WHERE rowid = ?;
                """
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                throw SignalStoreError.exec(lastError)
            }
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_double(stmt, 1, Self.sqlTime(event.timestamp))
            bind(stmt, 2, event.title)
            if let body = event.body { bind(stmt, 3, body) } else { sqlite3_bind_null(stmt, 3) }
            try bindJSON(stmt, 4, event.deepLink)
            sqlite3_bind_int64(stmt, 5, rowID)
            guard sqlite3_step(stmt) == SQLITE_DONE else { throw SignalStoreError.exec(lastError) }
            try exec(
                """
                INSERT INTO events_fts (rowid, title, body, kind)
                SELECT rowid, title, body, kind FROM events WHERE rowid = \(rowID);
                """)
            try exec("COMMIT;")
        } catch {
            try? exec("ROLLBACK;")
            throw error
        }
    }

    public func dedupeCount(id: UUID) -> Int {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT dedupe_count FROM events WHERE id = ?;", -1, &stmt, nil) == SQLITE_OK
        else { return 1 }
        defer { sqlite3_finalize(stmt) }
        bind(stmt, 1, id.uuidString)
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 1
    }
}
