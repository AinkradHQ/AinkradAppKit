import Foundation
import SQLite3

/// What a source has actually been emitting, so a settings sheet can list its
/// kinds without anyone maintaining that list by hand.
public struct SignalKindActivity: Sendable, Equatable, Identifiable {
    public let kind: String
    public let count: Int
    public let lastSeen: Date
    /// Which source emitted it. Nil when the list is already scoped to one
    /// source and saying so again would be noise.
    ///
    /// Not optional decoration: a kind name alone cannot be muted. Overrides
    /// are keyed by (source, kind), so a control that had only the kind would
    /// have to guess the source — and a guess that is wrong produces a mute
    /// button which appears to work and silently does nothing.
    public let source: SignalSource?

    public var id: String {
        source.map { "\($0):\(kind)" } ?? kind
    }

    public init(kind: String, count: Int, lastSeen: Date) {
        self.kind = kind
        self.count = count
        self.lastSeen = lastSeen
        self.source = nil
    }

    /// Separate, not a defaulted parameter — library evolution.
    public init(kind: String, count: Int, lastSeen: Date, source: SignalSource?) {
        self.kind = kind
        self.count = count
        self.lastSeen = lastSeen
        self.source = source
    }
}

extension SignalStore {
    /// The kinds this source has emitted, newest first.
    ///
    /// Discovered from the feed rather than declared anywhere. A per-kind
    /// control list that someone has to remember to update is a list that goes
    /// stale the first time an app adds a kind — and the user then cannot
    /// silence the one thing that is actually bothering them.
    ///
    /// Served by the existing `idx_events_source` index; no schema change.
    public func kindActivity(for source: SignalSource, since: Date?) -> [SignalKindActivity] {
        let (sourceKind, appID) = Self.decompose(source)
        var sql = """
        SELECT kind, COUNT(*) AS n, MAX(timestamp) AS last FROM events
        WHERE source_kind = ? AND source_app_id IS ?
        """
        if since != nil { sql += " AND timestamp >= ?" }
        sql += " GROUP BY kind ORDER BY last DESC;"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        bind(stmt, 1, sourceKind)
        // `IS`, not `=`. Host and Sage store a NULL app id, and SQLite's
        // equality against NULL matches nothing — so `=` would report that
        // those two sources have never emitted a single kind.
        if let appID { bind(stmt, 2, appID) } else { sqlite3_bind_null(stmt, 2) }
        if let since { sqlite3_bind_double(stmt, 3, Self.sqlTime(since)) }

        var out: [SignalKindActivity] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let kindText = Self.text(stmt, 0) else { continue }
            out.append(SignalKindActivity(
                kind: kindText,
                count: Int(sqlite3_column_int(stmt, 1)),
                lastSeen: Self.date(sqlite3_column_double(stmt, 2))))
        }
        return out
    }
}
