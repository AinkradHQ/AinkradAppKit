import Foundation

/// The file that makes a directory an Ainkrad Home. Identity lives in `homeID`,
/// not in the path, so a moved or renamed vault is still recognisably the same one.
public struct HomeMarker: Codable, Sendable {
    public static let filename = ".ainkrad-home"
    public static let currentSchemaVersion = 1

    public let homeID: String
    public let schemaVersion: Int
    public let createdAt: Date

    public init(
        homeID: String = UUID().uuidString,
        schemaVersion: Int = HomeMarker.currentSchemaVersion,
        createdAt: Date = Date()
    ) {
        self.homeID = homeID
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
    }

    public static func url(in vault: URL) -> URL {
        vault.appendingPathComponent(filename)
    }

    public static func read(in vault: URL) throws -> HomeMarker? {
        let url = self.url(in: vault)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(HomeMarker.self, from: Data(contentsOf: url))
    }

    public func write(to vault: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(self).write(to: HomeMarker.url(in: vault), options: .atomic)
    }
}
