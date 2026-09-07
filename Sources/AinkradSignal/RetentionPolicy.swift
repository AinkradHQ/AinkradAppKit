import Foundation

/// Rolling retention. Both caps apply; pinned rows are exempt from both and
/// do not consume `maxEvents`.
public struct RetentionPolicy: Codable, Sendable, Equatable {
    public var maxAgeDays: Int
    public var maxEvents: Int

    public init(maxAgeDays: Int = 30, maxEvents: Int = 10_000) {
        self.maxAgeDays = maxAgeDays
        self.maxEvents = maxEvents
    }

    public static let `default` = RetentionPolicy()
}
