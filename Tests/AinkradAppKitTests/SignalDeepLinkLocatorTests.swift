import Testing
import Foundation
@testable import AinkradSignal

@Suite("Deep link locators")
struct SignalDeepLinkLocatorTests {
    @Test("the two-argument initialiser still exists and leaves no locator")
    func legacyInitHasNoLocator() {
        let link = SignalDeepLink(appID: "rune", payload: Data("x".utf8))
        #expect(link.locator == nil)
    }

    @Test("a locator round-trips through Codable")
    func roundTrips() throws {
        let link = SignalDeepLink(appID: "rune", payload: Data("x".utf8), locator: "session-7")
        let decoded = try JSONDecoder().decode(
            SignalDeepLink.self, from: try JSONEncoder().encode(link))
        #expect(decoded == link)
        #expect(decoded.locator == "session-7")
    }

    @Test("a pre-generation-10 deep link with no locator key still decodes")
    func decodesWithoutLocatorKey() throws {
        // Every event already in the user's store was encoded without this
        // key. A synthesised decoder would refuse all of them, and adding a
        // feature would have emptied the notification history.
        let json = Data("""
        {"appID":"rune","payload":"eA=="}
        """.utf8)
        let decoded = try JSONDecoder().decode(SignalDeepLink.self, from: json)
        #expect(decoded.appID == "rune")
        #expect(decoded.locator == nil)
    }

    @Test("an explicit null locator decodes as nil rather than failing")
    func decodesNullLocator() throws {
        let json = Data("""
        {"appID":"rune","payload":"eA==","locator":null}
        """.utf8)
        #expect(try JSONDecoder().decode(SignalDeepLink.self, from: json).locator == nil)
    }

    @Test("a whole event carrying a locator survives an encode/decode cycle")
    func eventRoundTrip() throws {
        let event = SignalEvent(
            source: .app(appID: "rune"), kind: "terminal.agent-attention",
            severity: .info, title: "Claude needs input",
            deepLink: SignalDeepLink(appID: "rune", payload: Data(), locator: "abc-123"))
        let decoded = try JSONDecoder().decode(
            SignalEvent.self, from: try JSONEncoder().encode(event))
        #expect(decoded.deepLink?.locator == "abc-123")
    }
}
