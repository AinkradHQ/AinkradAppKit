import Foundation
import Testing

@testable import AinkradSignal

@Suite("SignalDeepLink symbol")
struct SignalDeepLinkSymbolTests {
    @Test("a link's symbol survives the store, and a link stored without one still decodes")
    func roundTrip() throws {
        var link = SignalDeepLink(appID: "whisper", payload: Data("x".utf8))
        link.symbol = "phone.bubble"
        let decoded = try JSONDecoder().decode(SignalDeepLink.self, from: JSONEncoder().encode(link))
        #expect(decoded.symbol == "phone.bubble")
        #expect(decoded == link)

        let old = #"{"appID":"quest","payload":"eA=="}"#
        let legacy = try JSONDecoder().decode(SignalDeepLink.self, from: Data(old.utf8))
        #expect(legacy.symbol == nil)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("signal-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SignalStore(url: url)
        _ = try store.insert(
            SignalEvent(
                source: .app(appID: "whisper"), kind: "whisper.message", severity: .info,
                title: "Islam", deepLink: link))
        #expect(store.page(filter: .all, before: nil, limit: 1).first?.deepLink?.symbol == "phone.bubble")
    }
}
