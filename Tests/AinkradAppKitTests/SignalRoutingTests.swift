import Testing
import Foundation
@testable import AinkradSignal

@Suite("Signal routing")
struct SignalRoutingTests {
    private func event(_ severity: SignalSeverity,
                       source: SignalSource = .host,
                       kind: String = "test.event",
                       importance: SignalImportance = .normal) -> SignalEvent {
        SignalEvent(source: source, kind: kind, severity: severity,
                    title: "t", proposedImportance: importance)
    }

    private let frontmost = DeliveryContext(hostIsFrontmost: true, visibleAppIDs: ["raven"],
                                            systemDoNotDisturb: false, hostFocusMode: false)
    private let away = DeliveryContext(hostIsFrontmost: false, visibleAppIDs: [],
                                       systemDoNotDisturb: false, hostFocusMode: false)

    @Test("the feed always receives the event, whatever the rules say")
    func feedIsUnconditional() {
        var rules = RoutingRules.default
        rules.mutedSources.insert(.host)
        let channels = route(event(.failure), rules: rules, context: away)
        #expect(channels.contains(.feed))
    }

    @Test("a muted source still logs but never interrupts")
    func mutedSourceCannotInterrupt() {
        var rules = RoutingRules.default
        rules.mutedSources.insert(.app(appID: "raven"))
        let channels = route(event(.failure, source: .app(appID: "raven"), importance: .urgent),
                             rules: rules, context: away)
        #expect(channels == [.feed])
    }

    @Test("looking away promotes a toast to a banner")
    func awayPromotesToBanner() {
        let here = route(event(.success), rules: .default, context: frontmost)
        let gone = route(event(.success), rules: .default, context: away)
        #expect(here.contains(.toast))
        #expect(!here.contains(.banner))
        #expect(gone.contains(.banner))
        #expect(!gone.contains(.toast))
    }

    @Test("do not disturb strips banner and sound but never feed or badge")
    func doNotDisturb() {
        let dnd = DeliveryContext(hostIsFrontmost: false, visibleAppIDs: [],
                                  systemDoNotDisturb: true, hostFocusMode: false)
        let channels = route(event(.failure), rules: .default, context: dnd)
        #expect(!channels.contains(.banner))
        #expect(!channels.contains(.sound))
        #expect(channels.contains(.feed))
        #expect(channels.contains(.badge))
    }

    @Test("an event below the source's interrupt floor reaches the feed only")
    func belowInterruptFloor() {
        var rules = RoutingRules.default
        rules.interruptFloor[.app(appID: "raven")] = .failure
        let warning = event(.warning, source: .app(appID: "raven"))
        #expect(route(warning, rules: rules, context: away, now: .now) == [.feed])
    }

    @Test("an event at the floor is untouched by it")
    func atInterruptFloor() {
        var rules = RoutingRules.default
        rules.interruptFloor[.app(appID: "raven")] = .warning
        let warning = event(.warning, source: .app(appID: "raven"))
        #expect(route(warning, rules: rules, context: away, now: .now).contains(.banner))
    }

    @Test("the floor is per source, not global")
    func floorIsPerSource() {
        var rules = RoutingRules.default
        rules.interruptFloor[.app(appID: "raven")] = .failure
        #expect(route(event(.warning, source: .host), rules: rules,
                      context: away, now: .now).contains(.banner))
    }

    @Test("an urgent event from a bypassing source clears the floor")
    func urgentClearsTheFloor() {
        var rules = RoutingRules.default
        rules.interruptFloor[.app(appID: "rune")] = .failure
        rules.urgentBypass = [.app(appID: "rune")]
        let channels = route(event(.info, source: .app(appID: "rune"), importance: .urgent),
                             rules: rules, context: away, now: .now)
        #expect(channels.contains(.banner))
    }

    @Test("the floor beats an override the user set earlier")
    func floorBeatsOverride() {
        var rules = RoutingRules.default
        rules.sourceOverrides[.app(appID: "raven")] = [.banner, .sound]
        rules.interruptFloor[.app(appID: "raven")] = .failure
        // A floor is the user saying "not below this". An override they set
        // before must not resurrect what the floor just excluded.
        #expect(route(event(.info, source: .app(appID: "raven")),
                      rules: rules, context: away, now: .now) == [.feed])
    }

    @Test("inside a suppression window nothing interrupts, but the count still moves")
    func suppressionWindowSilencesEveryInterruption() {
        var rules = RoutingRules.default
        rules.suppression.snoozedUntil = Date().addingTimeInterval(600)
        let channels = route(event(.failure), rules: rules, context: away, now: .now)
        #expect(!channels.contains(.banner))
        #expect(!channels.contains(.toast))
        #expect(!channels.contains(.sound))
        #expect(channels.contains(.feed))
        // The badge survives, exactly as it does under Do Not Disturb. A count
        // is not an interruption — it is what the user looks at when they come
        // back, and hiding it would make quiet hours lose information rather
        // than defer it.
        #expect(channels.contains(.badge))
    }

    @Test("sound-only suppression keeps the banner and drops the chime")
    func soundOnlySuppression() {
        var rules = RoutingRules.default
        rules.suppression.snoozedUntil = Date().addingTimeInterval(600)
        rules.suppression.mode = .soundOnly
        let channels = route(event(.failure), rules: rules, context: away, now: .now)
        #expect(channels.contains(.banner))
        #expect(!channels.contains(.sound))
    }

    @Test("an urgent event from a bypassing source survives suppression")
    func urgentSurvivesSuppression() {
        var rules = RoutingRules.default
        rules.suppression.snoozedUntil = Date().addingTimeInterval(600)
        rules.urgentBypass = [.app(appID: "rune")]
        let channels = route(event(.info, source: .app(appID: "rune"), importance: .urgent),
                             rules: rules, context: away, now: .now)
        #expect(channels.contains(.banner))
    }

    @Test("a suppression window that has expired suppresses nothing")
    func expiredSuppressionIsInert() {
        var rules = RoutingRules.default
        rules.suppression.snoozedUntil = Date().addingTimeInterval(-60)
        #expect(route(event(.failure), rules: rules, context: away, now: .now).contains(.banner))
    }

    @Test("the three-argument route still exists and reads the clock itself")
    func legacyRouteOverloadSurvives() {
        // Public API in a library-evolution module: the old symbol must keep
        // working, or anything already linked against it breaks at load time.
        #expect(route(event(.failure), rules: .default, context: away).contains(.banner))
    }

    @Test("a per-source sound choice is carried through, not decided by route")
    func soundChoiceIsData() {
        var rules = RoutingRules.default
        rules.soundOverride[.app(appID: "raven")] = .silent
        #expect(rules.soundOverride[.app(appID: "raven")] == .silent)
    }

    @Test("rules written before the new fields existed still decode")
    func decodesPreControlFields() throws {
        var object = try #require(try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(RoutingRules.default)) as? [String: Any])
        for key in ["interruptFloor", "soundOverride", "suppression"] {
            #expect(object.removeValue(forKey: key) != nil,
                    "\(key) must be present today, or this test proves nothing")
        }
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let rules = try JSONDecoder().decode(RoutingRules.self, from: legacy)
        #expect(rules.interruptFloor.isEmpty)
        #expect(rules.soundOverride.isEmpty)
        #expect(rules.suppression == SuppressionWindow())
    }

    @Test("rules written before urgentBypass existed still decode")
    func decodesPreBypassJSON() throws {
        // Built by encoding today's rules and DELETING the new key, rather than
        // by hand-writing JSON: `sourceOverrides` is keyed by a non-String
        // enum, so Swift encodes it as a flat array and not an object. A
        // hand-written fixture guessed that wrong and tested nothing.
        var object = try #require(try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(RoutingRules.default)) as? [String: Any])
        #expect(object.removeValue(forKey: "urgentBypass") != nil,
                "the field must be present today, or this test proves nothing")

        let legacy = try JSONSerialization.data(withJSONObject: object)
        let rules = try JSONDecoder().decode(RoutingRules.self, from: legacy)
        #expect(rules.urgentBypass.isEmpty)
        #expect(rules == .default)
    }

    @Test("rules round-trip through Codable with the new field")
    func roundTripsWithBypass() throws {
        var rules = RoutingRules.default
        rules.urgentBypass = [.app(appID: "rune"), .host]
        let decoded = try JSONDecoder().decode(
            RoutingRules.self, from: try JSONEncoder().encode(rules))
        #expect(decoded == rules)
    }

    @Test("focus mode silences the toast and the chime, not only the banner")
    func focusSilencesEveryInterruptingChannel() {
        let focused = DeliveryContext(hostIsFrontmost: true, visibleAppIDs: ["raven"],
                                      systemDoNotDisturb: false, hostFocusMode: true)
        let channels = route(event(.failure, source: .app(appID: "raven")),
                             rules: .default, context: focused)
        #expect(!channels.contains(.toast))
        #expect(!channels.contains(.sound))
        #expect(!channels.contains(.banner))
        #expect(channels.contains(.feed))
    }

    @Test("an urgent event from a bypassing source still interrupts in focus")
    func urgentBypassesFocus() {
        var rules = RoutingRules.default
        rules.urgentBypass = [.app(appID: "rune")]
        let focused = DeliveryContext(hostIsFrontmost: true, visibleAppIDs: [],
                                      systemDoNotDisturb: false, hostFocusMode: true)
        let channels = route(event(.info, source: .app(appID: "rune"), importance: .urgent),
                             rules: rules, context: focused)
        #expect(channels.contains(.toast))
        #expect(channels.contains(.feed))
    }

    @Test("the bypass applies only to urgent events, not to everything from that source")
    func bypassIsUrgentOnly() {
        var rules = RoutingRules.default
        rules.urgentBypass = [.app(appID: "rune")]
        let focused = DeliveryContext(hostIsFrontmost: true, visibleAppIDs: [],
                                      systemDoNotDisturb: false, hostFocusMode: true)
        let channels = route(event(.warning, source: .app(appID: "rune")),
                             rules: rules, context: focused)
        #expect(!channels.contains(.toast))
        #expect(!channels.contains(.sound))
    }

    @Test("a bypass for one source does not let another source through")
    func bypassIsPerSource() {
        var rules = RoutingRules.default
        rules.urgentBypass = [.app(appID: "rune")]
        let focused = DeliveryContext(hostIsFrontmost: true, visibleAppIDs: [],
                                      systemDoNotDisturb: false, hostFocusMode: true)
        let channels = route(event(.info, source: .app(appID: "raven"), importance: .urgent),
                             rules: rules, context: focused)
        #expect(!channels.contains(.toast))
        #expect(channels.contains(.feed))
    }

    @Test("failures make a sound when the user is present")
    func failureSounds() {
        #expect(route(event(.failure), rules: .default, context: frontmost).contains(.sound))
        #expect(!route(event(.info), rules: .default, context: frontmost).contains(.sound))
    }

    @Test("most specific rule wins: source+kind beats source beats severity")
    func specificityOrder() {
        var rules = RoutingRules.default
        rules.sourceOverrides[.host] = [.feed, .banner]
        rules.sourceKindOverrides[SourceKind(source: .host, kind: "quiet.thing")] = [.feed]
        #expect(route(event(.info), rules: rules, context: frontmost) == [.feed, .banner])
        #expect(route(event(.info, kind: "quiet.thing"), rules: rules, context: frontmost) == [.feed])
    }

    @Test("an urgent event interrupts even when it is only informational")
    func urgentInfoStillInterrupts() {
        // The case this was found by: an agent asking for input is `.info`
        // severity — nothing is wrong — but the user must know NOW. Under the
        // severity-only table it produced no channel at all while the user was
        // looking, so the only sign was a silent bell count.
        let event = event(.info, importance: .urgent)
        #expect(route(event, rules: .default, context: frontmost).contains(.toast))
        #expect(route(event, rules: .default, context: away).contains(.banner))
    }

    @Test("a background event never interrupts, whatever its severity")
    func backgroundNeverInterrupts() {
        let noisy = event(.failure, importance: .background)
        let channels = route(noisy, rules: .default, context: frontmost)
        #expect(!channels.contains(.toast))
        #expect(!channels.contains(.banner))
        #expect(!channels.contains(.sound))
        #expect(channels.contains(.feed), "but it is still recorded")
    }

    @Test("importance does not override a user's explicit rule")
    func userRulesStillWin() {
        var rules = RoutingRules.default
        rules.sourceOverrides[.host] = [.feed]
        let channels = route(event(.info, importance: .urgent), rules: rules, context: frontmost)
        #expect(channels == [.feed],
                "the emitter proposes; the user decides — that is the whole design")
    }

    @Test("a muted source stays muted however urgent the emitter claims to be")
    func mutedBeatsUrgent() {
        var rules = RoutingRules.default
        rules.mutedSources.insert(.host)
        #expect(route(event(.info, importance: .urgent), rules: rules, context: away) == [.feed])
    }

    @Test("normal importance leaves the severity table untouched")
    func normalIsUnchanged() {
        #expect(route(event(.info), rules: .default, context: frontmost) == [.feed])
        #expect(route(event(.success), rules: .default, context: frontmost).contains(.toast))
    }

    @Test("host run events route like any other event now that RunNotifier is gone")
    func runEventsAreOrdinary() {
        // The M1 exemption lived here: `run.*` from `.host` never reached
        // `.banner`, because the legacy notifier posted it. With that notifier
        // deleted, a run must route exactly like anything else — if it did not,
        // a finished run would produce no banner at all.
        let run = route(event(.success, kind: "run.finished"), rules: .default, context: away)
        let other = route(event(.success, kind: "install.completed"), rules: .default, context: away)
        #expect(run == other)
        #expect(run.contains(.banner))
    }

    // MARK: - "Never silent" has to mean audible

    @Test("an urgent event makes a sound, even at info severity")
    func urgentIsAudible() {
        // Rune's agent-attention notification exactly: an agent BLOCKED on the
        // user, which the emitter marks `.urgent` while its severity is only
        // `.info` because nothing has gone wrong. The severity table gives
        // sound to `.failure` alone, so without the urgent branch adding it
        // this is a silent interruption -- which is what shipped: the toast
        // appeared and nothing was heard.
        let channels = route(event(.info, source: .app(appID: "rune"),
                                   kind: "terminal.agent-attention", importance: .urgent),
                             rules: RoutingRules(), context: frontmost)
        #expect(channels.contains(.sound))
        #expect(channels.contains(.toast))
    }

    @Test("an urgent event is audible when the user is away, too")
    func urgentIsAudibleWhenAway() {
        let channels = route(event(.info, source: .app(appID: "rune"), importance: .urgent),
                             rules: RoutingRules(), context: away)
        #expect(channels.contains(.sound))
        #expect(channels.contains(.banner))
    }

    @Test("urgent does NOT chime through quiet hours")
    func urgentStaysQuietDuringSuppression() {
        // The whole point of ordering suppression after the default channels:
        // urgency decides what the event deserves, the user's own schedule
        // still gets the last word.
        var rules = RoutingRules()
        let now = Date()
        rules.suppression = SuppressionWindow(mode: .everything,
                                              snoozedUntil: now.addingTimeInterval(3600))
        let channels = route(event(.info, source: .app(appID: "rune"), importance: .urgent),
                             rules: rules, context: frontmost, now: now)
        #expect(!channels.contains(.sound))
    }

    @Test("urgent does NOT chime through Focus")
    func urgentStaysQuietDuringFocus() {
        let focus = DeliveryContext(hostIsFrontmost: true, visibleAppIDs: [],
                                    systemDoNotDisturb: false, hostFocusMode: true)
        let channels = route(event(.info, source: .app(appID: "rune"), importance: .urgent),
                             rules: RoutingRules(), context: focus)
        #expect(!channels.contains(.sound))
    }

    @Test("a background event stays silent no matter what")
    func backgroundStaysSilent() {
        let channels = route(event(.failure, source: .app(appID: "rune"), importance: .background),
                             rules: RoutingRules(), context: frontmost)
        #expect(!channels.contains(.sound))
    }
}
