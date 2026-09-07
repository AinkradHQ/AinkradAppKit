import Testing
import Foundation
@testable import AinkradSignal

@Suite("Signal wire format")
struct SignalWireTests {
    private func json(_ raw: String) -> Data { Data(raw.utf8) }

    @Test("a minimal valid payload decodes")
    func decodesMinimal() throws {
        let result = SignalWire.decode(json("""
        {"token":"abc","kind":"build.failed","severity":"failure","title":"Build failed"}
        """))
        guard case .success(let payload) = result else { Issue.record("expected success"); return }
        #expect(payload.token == "abc")
        #expect(payload.kind == "build.failed")
        #expect(payload.severity == .failure)
        #expect(payload.importance == .normal, "importance defaults rather than failing")
    }

    /// A `source` in the JSON is simply ignored: `SignalWirePayload` has no such
    /// property, so it cannot round-trip into an attribution. This test fails
    /// the day somebody adds one "for convenience".
    ///
    /// Asserted through `Mirror` rather than by comparing decoded values,
    /// because the point is the absence of the STORAGE, not the absence of a
    /// particular value — a `source` property defaulting to `.host` would pass
    /// any value-based check while reintroducing exactly the forgery this
    /// design rules out.
    @Test("the payload has no way to name a source")
    func noSourceField() {
        let claimsHost = SignalWire.decode(json("""
        {"token":"abc","kind":"test.event","severity":"info","title":"t","source":"host"}
        """))
        guard case .success(let payload) = claimsHost else {
            Issue.record("a payload carrying an extra source key should still decode")
            return
        }
        let labels = Mirror(reflecting: payload).children.compactMap(\.label)
        #expect(labels.contains("source") == false)
        #expect(labels.contains("token"), "the mirror must actually see the stored properties")
    }

    @Test("an oversized payload is rejected before parsing")
    func rejectsOversized() {
        let huge = json("{\"token\":\"a\",\"kind\":\"test.event\",\"severity\":\"info\",\"title\":\""
                        + String(repeating: "x", count: 9000) + "\"}")
        guard case .failure(let rejection) = SignalWire.decode(huge) else {
            Issue.record("expected rejection"); return
        }
        #expect(rejection == .tooLarge(bytes: huge.count))
    }

    @Test("malformed JSON is rejected without a partial apply")
    func rejectsMalformed() {
        guard case .failure(let rejection) = SignalWire.decode(json("{not json")) else {
            Issue.record("expected rejection"); return
        }
        #expect(rejection == .malformed)
    }

    @Test("a missing token is rejected as unauthenticated, not as malformed")
    func rejectsMissingToken() {
        guard case .failure(let rejection) = SignalWire.decode(json("""
        {"kind":"test.event","severity":"info","title":"t"}
        """)) else { Issue.record("expected rejection"); return }
        #expect(rejection == .missingToken)
    }

    @Test("an invalid kind is rejected at the wire, before it can reach ingest")
    func rejectsInvalidKind() {
        guard case .failure(let rejection) = SignalWire.decode(json("""
        {"token":"a","kind":"Not A Kind","severity":"info","title":"t"}
        """)) else { Issue.record("expected rejection"); return }
        #expect(rejection == .invalidKind("Not A Kind"))
    }
}

@Suite("Signal wire format — actions")
struct SignalWireActionTests {
    @Test("an action may omit isDestructive, and defaults to false")
    func actionOmitsIsDestructive() {
        // `isDestructive` defaults to false in SignalAction's memberwise init,
        // and must default the same way on the wire. It did not: the
        // synthesised decoder demanded the key, so this payload — which is
        // valid JSON by any reading — came back as `.malformed`, and the whole
        // notification was lost. An operator writing their first action would
        // be sent to reread a document they had already followed.
        let result = SignalWire.decode(Data("""
        {"token":"a","kind":"test.event","severity":"info","title":"t",
         "actions":[{"id":"rerun","label":"Re-run"}]}
        """.utf8))
        guard case .success(let payload) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(payload.actions.count == 1)
        #expect(payload.actions[0].id == "rerun")
        #expect(payload.actions[0].isDestructive == false)
    }

    @Test("an action may still declare itself destructive")
    func actionDeclaresDestructive() {
        let result = SignalWire.decode(Data("""
        {"token":"a","kind":"test.event","severity":"info","title":"t",
         "actions":[{"id":"delete","label":"Delete","isDestructive":true}]}
        """.utf8))
        guard case .success(let payload) = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(payload.actions[0].isDestructive)
    }
}
