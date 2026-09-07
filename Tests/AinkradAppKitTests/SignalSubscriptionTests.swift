import Testing
import Foundation
@testable import AinkradSignal

@Suite("Signal subscriptions")
struct SignalSubscriptionTests {
    private func event(source: SignalSource, kind: String) -> SignalEvent {
        SignalEvent(source: source, kind: kind, severity: .info, title: "t")
    }

    @Test("a source/kind pattern matches exactly what it names")
    func exactMatch() throws {
        let sub = try #require(SignalSubscription.parse(["app:raven/build.failed"]).first)
        #expect(sub.matches(event(source: .app(appID: "raven"), kind: "build.failed")))
        #expect(!sub.matches(event(source: .app(appID: "raven"), kind: "build.succeeded")))
        #expect(!sub.matches(event(source: .app(appID: "quest"), kind: "build.failed")))
    }

    @Test("a trailing wildcard matches a kind prefix")
    func kindWildcard() throws {
        let sub = try #require(SignalSubscription.parse(["app:raven/build.*"]).first)
        #expect(sub.matches(event(source: .app(appID: "raven"), kind: "build.failed")))
        #expect(sub.matches(event(source: .app(appID: "raven"), kind: "build.succeeded")))
        #expect(!sub.matches(event(source: .app(appID: "raven"), kind: "session.done")))
    }

    @Test("a prefix wildcard does not match the bare prefix without its dot")
    func wildcardDoesNotOvermatch() throws {
        // `build.*` must not match `buildings.started`. Matching on the raw
        // string prefix "build" would, and that is a subscription quietly
        // receiving more than the user approved.
        let sub = try #require(SignalSubscription.parse(["app:raven/build.*"]).first)
        #expect(!sub.matches(event(source: .app(appID: "raven"), kind: "buildings.started")))
        #expect(sub.matches(event(source: .app(appID: "raven"), kind: "build.failed")))
    }

    @Test("host and sage sources are nameable")
    func hostAndSage() throws {
        #expect(try #require(SignalSubscription.parse(["host/run.*"]).first)
            .matches(event(source: .host, kind: "run.finished")))
        #expect(try #require(SignalSubscription.parse(["sage/*"]).first)
            .matches(event(source: .sage, kind: "anything.at.all")))
    }

    @Test("a wildcard source is NOT allowed — subscriptions must be reviewable")
    func noWildcardSource() {
        #expect(SignalSubscription.parse(["*/build.failed"]).isEmpty,
                "the user approves a named list; '*' would make approval meaningless")
        #expect(SignalSubscription.parse(["app:*/build.failed"]).isEmpty)
    }

    @Test("malformed patterns are dropped, not fatal")
    func malformedDropped() {
        let subs = SignalSubscription.parse(["garbage", "app:raven/build.*", "", "///"])
        #expect(subs.count == 1)
    }

    @Test("an app cannot subscribe to itself into a loop")
    func selfSubscriptionIsDropped() {
        #expect(SignalSubscription.parse(["app:raven/build.*"], excluding: "raven").isEmpty,
                "an app already sees its own events via own(limit:)")
    }

    @Test("a human-readable description exists for the approval prompt")
    func description() throws {
        let sub = try #require(SignalSubscription.parse(["app:raven/build.*"]).first)
        #expect(sub.approvalDescription.contains("raven"))
        #expect(sub.approvalDescription.contains("build."))
    }

    @Test("parse reports what it dropped, so the host can warn about it")
    func reportsDropped() {
        // Dropping silently means a developer's typo makes a subscription
        // simply not happen, with nothing anywhere to say why. The host turns
        // this list into a .host warning at install.
        let result = SignalSubscription.parseReportingInvalid(
            ["app:raven/build.*", "*/everything", "nonsense"], excluding: nil)
        #expect(result.subscriptions.count == 1)
        #expect(result.invalid.sorted() == ["*/everything", "nonsense"])
    }
}

@Suite("Subscription descriptions")
struct SignalSubscriptionDescriptionTests {
    @Test("kindDescription carries only the kind half, for the host to compose")
    func kindDescriptions() throws {
        func kind(_ pattern: String) throws -> String {
            try #require(SignalSubscription.parse([pattern]).first).kindDescription
        }
        #expect(try kind("app:raven/build.*") == "build.* notifications")
        #expect(try kind("app:raven/build.failed") == "build.failed notifications")
        #expect(try kind("sage/*") == "all notifications")
    }

    @Test("only an app source needs the host to name it")
    func builtInNames() throws {
        func name(_ pattern: String) throws -> String? {
            try #require(SignalSubscription.parse([pattern]).first).builtInSourceName
        }
        #expect(try name("host/run.*") == "Ainkrad")
        #expect(try name("sage/*") == "Sage")
        #expect(try name("app:raven/build.*") == nil,
                "nothing here knows raven is called Raven")
    }
}
