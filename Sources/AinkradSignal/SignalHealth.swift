import Foundation
import SQLite3

/// Whether notifications are actually working, derived entirely from columns
/// the feed already has.
///
/// No event log, no new table, nothing that leaves the machine. That
/// constraint is what makes this cheap and also what makes it safe: a metrics
/// feature is exactly where telemetry creeps into a product that has none.
public struct SignalHealth: Sendable, Equatable {
    public let total: Int
    /// 0...1. Zero when nothing has been recorded — not a finding, just no data.
    public let readRate: Double
    /// Median seconds between an event arriving and being read. `nil` when
    /// nothing has been read, which is different from zero.
    public let medianAcknowledgeSeconds: Double?
    /// Loudest first, then least-read. The top row is by definition the next
    /// default worth changing.
    public let noisiest: [SignalKindActivity]

    public init(total: Int, readRate: Double,
                medianAcknowledgeSeconds: Double?, noisiest: [SignalKindActivity]) {
        self.total = total
        self.readRate = readRate
        self.medianAcknowledgeSeconds = medianAcknowledgeSeconds
        self.noisiest = noisiest
    }

    public static let empty = SignalHealth(total: 0, readRate: 0,
                                           medianAcknowledgeSeconds: nil, noisiest: [])
}

extension SignalStore {
    /// Health over a window, optionally for one source.
    public func health(since: Date, source: SignalSource? = nil,
                       noisiestLimit: Int = 3) -> SignalHealth {
        var clauses = ["timestamp >= \(Self.sqlTime(since))"]
        if let source {
            let (kind, appID) = Self.decompose(source)
            clauses.append("source_kind = '\(Self.escape(kind))'")
            // `IS`, not `=`: host and Sage store NULL, and equality against
            // NULL matches nothing.
            clauses.append(appID.map { "source_app_id IS '\(Self.escape($0))'" }
                           ?? "source_app_id IS NULL")
        }
        let whereSQL = "WHERE " + clauses.joined(separator: " AND ")

        var total = 0
        var read = 0
        var stmt: OpaquePointer?
        let counts = "SELECT COUNT(*), COUNT(read_at) FROM events \(whereSQL);"
        if sqlite3_prepare_v2(db, counts, -1, &stmt, nil) == SQLITE_OK,
           sqlite3_step(stmt) == SQLITE_ROW {
            total = Int(sqlite3_column_int(stmt, 0))
            read = Int(sqlite3_column_int(stmt, 1))
        }
        sqlite3_finalize(stmt)
        guard total > 0 else { return .empty }

        return SignalHealth(
            total: total,
            readRate: Double(read) / Double(total),
            medianAcknowledgeSeconds: medianAcknowledge(whereSQL: whereSQL, readCount: read),
            noisiest: noisiestKinds(whereSQL: whereSQL, limit: noisiestLimit))
    }

    /// The middle row of the sorted delays, taken in SQL rather than by
    /// pulling every row into memory — a feed can hold a hundred thousand.
    private func medianAcknowledge(whereSQL: String, readCount: Int) -> Double? {
        guard readCount > 0 else { return nil }
        // For an even count this takes the upper of the two middle values.
        // Averaging them would be more textbook and less useful: the number is
        // read as "about this long", and a spurious half-second of precision
        // implies an accuracy the sample size does not have.
        let offset = readCount / 2
        let sql = """
        SELECT read_at - timestamp FROM events \(whereSQL) AND read_at IS NOT NULL
        ORDER BY read_at - timestamp LIMIT 1 OFFSET \(offset);
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK,
              sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return max(0, sqlite3_column_double(stmt, 0))
    }

    private func noisiestKinds(whereSQL: String, limit: Int) -> [SignalKindActivity] {
        // Grouped by SOURCE and kind, not kind alone. Overrides are keyed by
        // the pair, so a row carrying only the kind cannot be muted without
        // guessing whose it is — and a wrong guess is a button that appears to
        // work and silently does nothing.
        let sql = """
        SELECT kind, COUNT(*) AS n, MAX(timestamp) AS last,
               CAST(COUNT(read_at) AS REAL) / COUNT(*) AS rate,
               source_kind, source_app_id
        FROM events \(whereSQL)
        GROUP BY source_kind, source_app_id, kind
        ORDER BY n DESC, rate ASC
        LIMIT \(limit);
        """
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        var out: [SignalKindActivity] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let kind = Self.text(stmt, 0) else { continue }
            let source = Self.compose(kind: Self.text(stmt, 4) ?? "host",
                                      appID: Self.text(stmt, 5))
            out.append(SignalKindActivity(kind: kind,
                                          count: Int(sqlite3_column_int(stmt, 1)),
                                          lastSeen: Self.date(sqlite3_column_double(stmt, 2)),
                                          source: source))
        }
        return out
    }
}

extension SignalStore {
    /// Sets a read stamp to an exact time. Test-only: `markRead` stamps `now`,
    /// so there is otherwise no way to construct a known acknowledge delay.
    func setReadStampForTesting(id: UUID, at date: Date) throws {
        try exec("UPDATE events SET read_at = \(Self.sqlTime(date)) " +
                 "WHERE id = '\(Self.escape(id.uuidString))';")
    }
}
