import Foundation
import SQLite3

public enum SignalStoreError: Error, Equatable {
    case open(String)
    case exec(String)
    /// The file was written by a newer build. Opened read-only rather than
    /// migrated backwards — destroying a user's feed to satisfy an older
    /// binary is never the right trade.
    case futureSchema(found: Int, supported: Int)
}

public enum SignalInsertOutcome: Equatable, Sendable {
    case inserted
    case coalesced(id: UUID)
}

public struct SignalFilter: Sendable, Equatable {
    public var sources: Set<SignalSource>?
    public var severities: Set<SignalSeverity>?
    public var kindPrefix: String?
    public var unreadOnly: Bool

    public init(
        sources: Set<SignalSource>? = nil,
        severities: Set<SignalSeverity>? = nil,
        kindPrefix: String? = nil,
        unreadOnly: Bool = false
    ) {
        self.sources = sources
        self.severities = severities
        self.kindPrefix = kindPrefix
        self.unreadOnly = unreadOnly
    }

    public static let all = SignalFilter()
}

public final class SignalStore {
    public static let schemaVersion = 2
    /// Coalescing window. Outside it, the same `dedupeKey` inserts a new row.
    public static let dedupeWindow: TimeInterval = 60

    var db: OpaquePointer?
    static let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    public private(set) var isReadOnly = false

    public init(url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            let message = lastError
            if db != nil { sqlite3_close(db) }
            throw SignalStoreError.open(message)
        }
        try exec("PRAGMA journal_mode=WAL;")
        try migrate()
    }

    deinit { if db != nil { sqlite3_close(db) } }

    // MARK: - schema

    private func migrate() throws {
        try exec("CREATE TABLE IF NOT EXISTS schema_meta (version INTEGER NOT NULL);")
        let found = currentVersion()
        if found > Self.schemaVersion {
            isReadOnly = true
            throw SignalStoreError.futureSchema(found: found, supported: Self.schemaVersion)
        }
        if found == 0 {
            try createV1()
            // The literal 1, NOT `Self.schemaVersion`. Recording the current
            // version here would mark a brand-new database as fully migrated
            // while `createV1` had only built the v1 shape — so every later
            // migration would be skipped on new installs and applied on
            // upgraded ones. That split shows up months afterwards, on one
            // machine and not another, and is near-impossible to read back to
            // this line.
            try exec("INSERT INTO schema_meta (version) VALUES (1);")
        }
        if currentVersion() < 2 {
            try migrateToV2()
            try exec("UPDATE schema_meta SET version = 2;")
        }
    }

    /// v2 adds `kind` to the search index.
    ///
    /// An FTS5 external-content table cannot gain a column, so the only
    /// correct move is to DROP and rebuild from `events`. That is why this is
    /// a numbered schema version rather than a quiet fix-up: it is a
    /// destructive step on the table the user's search depends on, and it
    /// belongs in the version history where it can be found.
    ///
    /// The rebuild reads from `events`, which is untouched — so no event is at
    /// risk, only the index over them.
    private func migrateToV2() throws {
        try exec("DROP TABLE IF EXISTS events_fts;")
        try exec(
            """
            CREATE VIRTUAL TABLE events_fts
              USING fts5(title, body, kind, content='events', content_rowid='rowid');
            """)
        try exec("INSERT INTO events_fts(events_fts) VALUES('rebuild');")
    }

    private func currentVersion() -> Int {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT version FROM schema_meta LIMIT 1;", -1, &stmt, nil) == SQLITE_OK
        else { return 0 }
        defer { sqlite3_finalize(stmt) }
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int(stmt, 0)) : 0
    }

    private func createV1() throws {
        try exec(
            """
            CREATE TABLE IF NOT EXISTS events (
              id TEXT PRIMARY KEY,
              timestamp REAL NOT NULL,   -- seconds since the 2001 reference date; see sqlTime
              source_kind TEXT NOT NULL,
              source_app_id TEXT,
              kind TEXT NOT NULL,
              severity TEXT NOT NULL,
              title TEXT NOT NULL,
              body TEXT,
              importance TEXT NOT NULL,
              deep_link BLOB,
              actions BLOB,
              dedupe_key TEXT,
              dedupe_count INTEGER NOT NULL DEFAULT 1,
              read_at REAL,
              pinned INTEGER NOT NULL DEFAULT 0
            );
            """)
        try exec("CREATE INDEX IF NOT EXISTS idx_events_ts ON events(timestamp DESC);")
        try exec(
            """
            CREATE INDEX IF NOT EXISTS idx_events_source
              ON events(source_kind, source_app_id, timestamp DESC);
            """)
        try exec("CREATE INDEX IF NOT EXISTS idx_events_unread ON events(read_at) WHERE read_at IS NULL;")
        // Deliberately NOT unique: coalescing is windowed, so the same key must
        // be reusable once its window has passed. A unique constraint would
        // silently make a key unusable for the rest of the retention period.
        try exec(
            """
            CREATE INDEX IF NOT EXISTS idx_events_dedupe
              ON events(source_kind, source_app_id, dedupe_key, timestamp DESC)
              WHERE dedupe_key IS NOT NULL;
            """)
        // External-content FTS does NOT self-maintain. This class writes both
        // rows in one transaction; there are deliberately no SQL triggers, so
        // the Swift layer stays the single point of truth.
        try exec(
            """
            CREATE VIRTUAL TABLE IF NOT EXISTS events_fts
              USING fts5(title, body, content='events', content_rowid='rowid');
            """)
    }

    // MARK: - insert

    @discardableResult
    public func insert(_ event: SignalEvent) throws -> SignalInsertOutcome {
        guard !isReadOnly else { return .inserted }
        if let key = event.dedupeKey,
            let existing = coalescibleRow(source: event.source, key: key, at: event.timestamp)
        {
            try bumpCoalesced(rowID: existing.rowID, id: existing.id, to: event)
            return .coalesced(id: existing.id)
        }
        try exec("BEGIN IMMEDIATE;")
        do {
            try insertRow(event)
            try insertFTS(for: event)
            try exec("COMMIT;")
        } catch {
            try? exec("ROLLBACK;")
            throw error
        }
        return .inserted
    }

    private func insertRow(_ e: SignalEvent) throws {
        let sql = """
            INSERT INTO events (id, timestamp, source_kind, source_app_id, kind, severity,
                                title, body, importance, deep_link, actions, dedupe_key)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?);
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { throw SignalStoreError.exec(lastError) }
        defer { sqlite3_finalize(stmt) }
        let (kindText, appID) = Self.decompose(e.source)
        bind(stmt, 1, e.id.uuidString)
        sqlite3_bind_double(stmt, 2, Self.sqlTime(e.timestamp))
        bind(stmt, 3, kindText)
        if let appID { bind(stmt, 4, appID) } else { sqlite3_bind_null(stmt, 4) }
        bind(stmt, 5, e.kind)
        bind(stmt, 6, e.severity.rawValue)
        bind(stmt, 7, e.title)
        if let body = e.body { bind(stmt, 8, body) } else { sqlite3_bind_null(stmt, 8) }
        bind(stmt, 9, e.proposedImportance.rawValue)
        try bindJSON(stmt, 10, e.deepLink)
        try bindJSON(stmt, 11, e.actions.isEmpty ? nil : e.actions)
        if let key = e.dedupeKey { bind(stmt, 12, key) } else { sqlite3_bind_null(stmt, 12) }
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw SignalStoreError.exec(lastError) }
    }

    private func insertFTS(for e: SignalEvent) throws {
        let sql = """
            INSERT INTO events_fts (rowid, title, body, kind)
            SELECT rowid, title, body, kind FROM events WHERE id = ?;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { throw SignalStoreError.exec(lastError) }
        defer { sqlite3_finalize(stmt) }
        bind(stmt, 1, e.id.uuidString)
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw SignalStoreError.exec(lastError) }
    }

    // MARK: - read

    public func page(filter: SignalFilter, before: Date?, limit: Int) -> [SignalEvent] {
        var clauses: [String] = []
        var binder: [(OpaquePointer?, Int32) -> Void] = []
        appendFilterClauses(filter, into: &clauses, binder: &binder)
        if let before {
            clauses.append("timestamp < ?")
            binder.append { stmt, i in sqlite3_bind_double(stmt, i, Self.sqlTime(before)) }
        }
        let whereSQL = clauses.isEmpty ? "" : "WHERE " + clauses.joined(separator: " AND ")
        let sql = "SELECT \(Self.columns) FROM events \(whereSQL) ORDER BY timestamp DESC LIMIT ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        var index: Int32 = 1
        for bindOne in binder {
            bindOne(stmt, index)
            index += 1
        }
        sqlite3_bind_int(stmt, index, Int32(max(0, min(limit, Int(Int32.max)))))
        var out: [SignalEvent] = []
        while sqlite3_step(stmt) == SQLITE_ROW { if let e = Self.event(from: stmt) { out.append(e) } }
        return out
    }

    /// Single-row lookup by primary key.
    ///
    /// Separate from `page` because a banner response arrives with an id and
    /// nothing else — no filter, no cursor, no ordering. Uses `Self.columns`
    /// rather than `SELECT *`: `event(from:)` reads its columns positionally,
    /// so the column list IS the contract between the query and the decoder.
    public func event(id: UUID) -> SignalEvent? {
        var stmt: OpaquePointer?
        let sql = "SELECT \(Self.columns) FROM events WHERE id = ? LIMIT 1;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        bind(stmt, 1, id.uuidString)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return Self.event(from: stmt)
    }

    static let columns = """
        id, timestamp, source_kind, source_app_id, kind, severity, title, body,
        importance, deep_link, actions, dedupe_key, dedupe_count, read_at, pinned
        """

    func appendFilterClauses(
        _ filter: SignalFilter,
        into clauses: inout [String],
        binder: inout [(OpaquePointer?, Int32) -> Void]
    ) {
        if let sources = filter.sources, !sources.isEmpty {
            let parts = sources.map { source -> String in
                let (kindText, appID) = Self.decompose(source)
                guard let appID else { return "(source_kind = '\(kindText)')" }
                return "(source_kind = 'app' AND source_app_id = '\(Self.escape(appID))')"
            }
            clauses.append("(" + parts.joined(separator: " OR ") + ")")
        }
        if let severities = filter.severities, !severities.isEmpty {
            let list = severities.map { "'\($0.rawValue)'" }.joined(separator: ",")
            clauses.append("severity IN (\(list))")
        }
        if let prefix = filter.kindPrefix, !prefix.isEmpty {
            clauses.append("kind LIKE '\(Self.escape(prefix))%'")
        }
        if filter.unreadOnly { clauses.append("read_at IS NULL") }
    }

    /// Only ever applied to values this module controls (enum raw values,
    /// caller-supplied app ids and kind prefixes, both already constrained by
    /// `SignalKind.isValid` / the emitter binding). Quotes are doubled anyway
    /// so a future looser caller cannot break the statement.
    static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "''")
    }

    /// Seconds since the REFERENCE date (2001), not the Unix epoch.
    ///
    /// `Date` stores reference-date seconds natively, so this round-trips
    /// bit-exactly. Going through `timeIntervalSince1970` does not: adding and
    /// then subtracting 978307200 costs about 119 nanoseconds of double
    /// precision, so an event read back from the store was not equal to the
    /// event written to it. Ordering was unaffected, which is exactly why this
    /// would have been an unpleasant bug to find later — it only shows up when
    /// something compares a persisted event to its in-memory original.
    static func sqlTime(_ date: Date) -> Double { date.timeIntervalSinceReferenceDate }
    static func date(_ value: Double) -> Date { Date(timeIntervalSinceReferenceDate: value) }

    static func decompose(_ source: SignalSource) -> (String, String?) {
        switch source {
        case .host: return ("host", nil)
        case .sage: return ("sage", nil)
        case .app(let id): return ("app", id)
        }
    }

    static func compose(kind: String, appID: String?) -> SignalSource {
        switch kind {
        case "sage": return .sage
        case "app": return .app(appID: appID ?? "")
        default: return .host
        }
    }

    static func event(from stmt: OpaquePointer?) -> SignalEvent? {
        guard let idText = text(stmt, 0), let id = UUID(uuidString: idText) else { return nil }
        let deepLink: SignalDeepLink? = json(stmt, 9)
        let actions: [SignalAction] = json(stmt, 10) ?? []
        return SignalEvent(
            id: id,
            timestamp: date(sqlite3_column_double(stmt, 1)),
            source: compose(kind: text(stmt, 2) ?? "host", appID: text(stmt, 3)),
            kind: text(stmt, 4) ?? "",
            severity: SignalSeverity(rawValue: text(stmt, 5) ?? "") ?? .info,
            title: text(stmt, 6) ?? "",
            body: text(stmt, 7),
            proposedImportance: SignalImportance(rawValue: text(stmt, 8) ?? "") ?? .normal,
            deepLink: deepLink,
            actions: actions,
            dedupeKey: text(stmt, 11))
    }

    // MARK: - sqlite helpers (mirrors MemoryIndex)

    var lastError: String { String(cString: sqlite3_errmsg(db)) }

    func exec(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw SignalStoreError.exec(lastError)
        }
    }

    func bind(_ stmt: OpaquePointer?, _ index: Int32, _ value: String) {
        sqlite3_bind_text(stmt, index, value, -1, Self.SQLITE_TRANSIENT)
    }

    func bindJSON<T: Encodable>(_ stmt: OpaquePointer?, _ index: Int32, _ value: T?) throws {
        guard let value else {
            sqlite3_bind_null(stmt, index)
            return
        }
        let data = try JSONEncoder().encode(value)
        _ = data.withUnsafeBytes {
            sqlite3_bind_blob(stmt, index, $0.baseAddress, Int32(data.count), Self.SQLITE_TRANSIENT)
        }
    }

    static func text(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        guard let c = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: c)
    }

    static func json<T: Decodable>(_ stmt: OpaquePointer?, _ index: Int32) -> T? {
        guard let bytes = sqlite3_column_blob(stmt, index) else { return nil }
        let count = Int(sqlite3_column_bytes(stmt, index))
        guard count > 0 else { return nil }
        return try? JSONDecoder().decode(T.self, from: Data(bytes: bytes, count: count))
    }
}
