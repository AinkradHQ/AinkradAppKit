import Testing
import Foundation
@testable import AinkradAppKit

/// The one payload shape Hoard, Rune and Lore agree on.
@Suite("AinkradLaunchIntent")
struct AinkradLaunchIntentTests {

    @Test("An intent round-trips through the launcher's opaque string")
    func roundTrips() {
        let intent = AinkradLaunchIntent(path: "/vault/roadmap.md", mode: .basic)
        let decoded = AinkradLaunchIntent.decode(intent.json)
        #expect(decoded == intent)
        #expect(decoded?.isOpenDocument == true)
    }

    @Test("A nil mode stays nil, so a sender cannot override the user's setting")
    func nilModeIsPreserved() {
        // A sender that does not care about mode must leave the app's own
        // default alone rather than silently forcing one.
        let decoded = AinkradLaunchIntent.decode(AinkradLaunchIntent(path: "/a.md").json)
        #expect(decoded?.mode == nil)
    }

    @Test("A payload of another kind decodes as not-ours, not as a failure")
    func foreignKindIsNotOurs() {
        // Rune's SSH payload travels the same channel. Treating "not mine" as
        // an error is how one app's launch breaks another's.
        let ssh = #"{"host":"example.com","port":22,"username":"a","identityFile":"/k"}"#
        #expect(AinkradLaunchIntent.decode(ssh) == nil)
    }

    @Test("Garbage and nil decode to nil rather than trapping")
    func malformedIsSafe() {
        #expect(AinkradLaunchIntent.decode(nil) == nil)
        #expect(AinkradLaunchIntent.decode("not json") == nil)
        #expect(AinkradLaunchIntent.decode("") == nil)
    }

    @Test("The kind is carried, so a future second kind cannot be mis-read")
    func kindIsExplicit() {
        let other = AinkradLaunchIntent(kind: "openProject", path: "/p", mode: nil)
        let decoded = AinkradLaunchIntent.decode(other.json)
        #expect(decoded?.isOpenDocument == false,
                "a reader must branch on kind BEFORE acting on path")
    }
}
