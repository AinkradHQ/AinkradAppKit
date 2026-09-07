import Foundation

public enum DeliveryChannel: String, Codable, Sendable, Hashable, CaseIterable {
    /// Always delivered. Not rule-controlled: the log is not optional.
    case feed
    case badge
    case toast
    case banner
    case sound
}

/// What the *user's situation* contributes to the decision. Supplied by the
/// host; this is what promotes a toast to a banner when the user looked away.
public struct DeliveryContext: Sendable, Equatable {
    public let hostIsFrontmost: Bool
    public let visibleAppIDs: Set<String>
    public let systemDoNotDisturb: Bool
    public let hostFocusMode: Bool

    public init(hostIsFrontmost: Bool, visibleAppIDs: Set<String>,
                systemDoNotDisturb: Bool, hostFocusMode: Bool) {
        self.hostIsFrontmost = hostIsFrontmost
        self.visibleAppIDs = visibleAppIDs
        self.systemDoNotDisturb = systemDoNotDisturb
        self.hostFocusMode = hostFocusMode
    }
}

/// Key for a `(source, kind)` override.
public struct SourceKind: Codable, Sendable, Hashable {
    public let source: SignalSource
    public let kind: String
    public init(source: SignalSource, kind: String) {
        self.source = source
        self.kind = kind
    }
}

/// Which cue a source's notifications use.
///
/// Deliberately NOT the host's `UISound`: that type lives in the app, names
/// assets in the app's bundle, and cannot be referenced from the SDK. A string
/// case keeps the choice storable here while the host stays the only thing that
/// has to know what a cue name maps to.
public enum SignalSoundChoice: Codable, Sendable, Equatable, Hashable {
    /// Follow the severity, as an unconfigured source does.
    case bySeverity
    /// This source never makes a sound, though it may still toast and banner.
    case silent
    /// A specific cue, by the host's own name for it.
    case named(String)
}

public struct RoutingRules: Codable, Sendable, Equatable {
    /// Sources the user silenced. They still reach `.feed`, nothing else.
    public var mutedSources: Set<SignalSource>
    public var sourceOverrides: [SignalSource: Set<DeliveryChannel>]
    public var sourceKindOverrides: [SourceKind: Set<DeliveryChannel>]

    /// Sources allowed to interrupt through Focus, and ONLY for `.urgent`
    /// events. An agent blocked on the user is the one case where silence costs
    /// the whole wait; everything else the user silenced stays silent.
    public var urgentBypass: Set<SignalSource> = []

    /// The least severity a source is allowed to interrupt with. Anything below
    /// it is recorded and nothing more.
    public var interruptFloor: [SignalSource: SignalSeverity] = [:]

    /// Per-source cue choice. Carried, never interpreted here — `route` decides
    /// channels, and the host decides what a cue name plays.
    public var soundOverride: [SignalSource: SignalSoundChoice] = [:]

    /// Quiet hours and snooze. See `SuppressionWindow`.
    public var suppression = SuppressionWindow()

    public init(mutedSources: Set<SignalSource> = [],
                sourceOverrides: [SignalSource: Set<DeliveryChannel>] = [:],
                sourceKindOverrides: [SourceKind: Set<DeliveryChannel>] = [:]) {
        self.mutedSources = mutedSources
        self.sourceOverrides = sourceOverrides
        self.sourceKindOverrides = sourceKindOverrides
    }

    /// A SEPARATE initialiser rather than a fourth defaulted parameter on the
    /// one above. This module builds with `-enable-library-evolution`: adding a
    /// default changes the existing init's mangled symbol, so anything already
    /// linked against it fails at `Bundle.load()` rather than at compile time.
    /// That is the `AinkradFormRow` failure recorded in AinkradQuest's
    /// project.yml, and the pattern `SignalDeepLink.init(appID:payload:locator:)`
    /// established.
    public init(mutedSources: Set<SignalSource>,
                sourceOverrides: [SignalSource: Set<DeliveryChannel>],
                sourceKindOverrides: [SourceKind: Set<DeliveryChannel>],
                urgentBypass: Set<SignalSource>) {
        self.mutedSources = mutedSources
        self.sourceOverrides = sourceOverrides
        self.sourceKindOverrides = sourceKindOverrides
        self.urgentBypass = urgentBypass
    }

    /// Hand-written, because the synthesized decoder REQUIRES every key. A
    /// `signal.json` written before `urgentBypass` existed has no such key, so
    /// a synthesized decoder would reject the file and silently reset every
    /// notification preference the user had set.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        mutedSources = try container.decodeIfPresent(
            Set<SignalSource>.self, forKey: .mutedSources) ?? []
        sourceOverrides = try container.decodeIfPresent(
            [SignalSource: Set<DeliveryChannel>].self, forKey: .sourceOverrides) ?? [:]
        sourceKindOverrides = try container.decodeIfPresent(
            [SourceKind: Set<DeliveryChannel>].self, forKey: .sourceKindOverrides) ?? [:]
        urgentBypass = try container.decodeIfPresent(
            Set<SignalSource>.self, forKey: .urgentBypass) ?? []
        interruptFloor = try container.decodeIfPresent(
            [SignalSource: SignalSeverity].self, forKey: .interruptFloor) ?? [:]
        soundOverride = try container.decodeIfPresent(
            [SignalSource: SignalSoundChoice].self, forKey: .soundOverride) ?? [:]
        suppression = try container.decodeIfPresent(
            SuppressionWindow.self, forKey: .suppression) ?? SuppressionWindow()
    }

    public static let `default` = RoutingRules()
}

/// Pure. Given an event, the user's rules and the user's situation, which
/// channels deliver it. No I/O, no clock, no globals — every branch is a table
/// row in `SignalRoutingTests`.
/// The pre-suppression signature, kept because it is public API in a
/// library-evolution module: changing it would break anything already linked
/// against the old mangled symbol at load time, not at compile time.
public func route(_ event: SignalEvent,
                  rules: RoutingRules,
                  context: DeliveryContext) -> Set<DeliveryChannel> {
    route(event, rules: rules, context: context, now: Date())
}

/// Pure. Given an event, the user's rules, their situation and the time, which
/// channels deliver it. The clock is a PARAMETER — a suppression window that
/// read `Date()` internally could not be tested at 3am.
public func route(_ event: SignalEvent,
                  rules: RoutingRules,
                  context: DeliveryContext,
                  now: Date,
                  calendar: Calendar = .current) -> Set<DeliveryChannel> {
    var channels: Set<DeliveryChannel> = [.feed]

    // Urgency from a source the user explicitly exempted. Computed once: it
    // clears the floor, the suppression window AND Focus, and three separate
    // computations of the same thing is three places for them to disagree.
    let bypasses = event.proposedImportance == .urgent
        && rules.urgentBypass.contains(event.source)

    // A muted source logs and stops. Checked before overrides so muting is
    // absolute — including against an `.urgent` proposal.
    if rules.mutedSources.contains(event.source) { return channels }

    // The floor comes BEFORE the overrides on purpose. A floor is the user
    // saying "never below this"; an override they set earlier must not
    // resurrect what the floor has just excluded.
    if let floor = rules.interruptFloor[event.source],
       severityRank(event.severity) < severityRank(floor), !bypasses {
        return channels
    }

    if let explicit = rules.sourceKindOverrides[SourceKind(source: event.source, kind: event.kind)] {
        channels = explicit.union([.feed])
    } else if let explicit = rules.sourceOverrides[event.source] {
        channels = explicit.union([.feed])
    } else {
        channels.formUnion(defaultChannels(for: event, context: context))
    }

    // Toast and sound are played by the HOST, not by the system, so nothing
    // else suppresses them. The earlier version removed only `.banner` on the
    // grounds that `UNUserNotificationCenter` enforces Focus itself — true for
    // banners, and true for nothing else, which left Ainkrad chiming and
    // throwing toasts at a user who had explicitly asked for quiet.
    if (context.systemDoNotDisturb || context.hostFocusMode) && !bypasses {
        channels.remove(.banner)
        channels.remove(.toast)
        channels.remove(.sound)
    }

    // Quiet hours and snooze. Separate from Focus because the user's own
    // schedule can mean something narrower than the system's: `.soundOnly`
    // keeps things visible while dropping the chime.
    if rules.suppression.isSuppressing(at: now, calendar: calendar), !bypasses {
        channels.remove(.sound)
        if rules.suppression.mode == .everything {
            channels.remove(.banner)
            channels.remove(.toast)
        }
    }
    return channels
}

private func defaultChannels(for event: SignalEvent,
                             context: DeliveryContext) -> Set<DeliveryChannel> {
    var channels = severityChannels(for: event, context: context)

    // Importance adjusts the severity table. This is what makes
    // `proposedImportance` an actual input rather than a documented one: it was
    // declared as "an input to routing" and then never read, so an agent
    // blocked on the user — `.info` severity, `.urgent` importance — produced
    // NO channel at all while the user was looking. The only sign was a silent
    // bell count.
    //
    // Applied only on the default path: a user's explicit rule replaces these
    // channels wholesale, and an emitter must not talk over that.
    switch event.proposedImportance {
    case .urgent:
        // Never silent. Interrupt where the user is: on screen if they are
        // here, on the system if they are not.
        channels.insert(context.hostIsFrontmost ? .toast : .banner)
        channels.insert(.badge)
        // The sound is the half of "never silent" that was missing, and it is
        // the half that works when the user is not looking at the screen.
        // Only `.failure` earns a sound from the severity table, and an agent
        // blocked on the user is `.info` severity -- nothing has gone wrong,
        // it just cannot continue. So Rune's agent-attention notification
        // raised a toast and made no sound at all, which is precisely the
        // interruption that needed to be heard.
        //
        // Safe to add unconditionally here: Focus, Do Not Disturb and quiet
        // hours all strip `.sound` AFTER this runs, so urgency decides what
        // the event deserves and the user's own schedule still has the last
        // word.
        channels.insert(.sound)
    case .background:
        // Recorded, never interrupting — for the chatter an app wants kept but
        // does not want the user pulled away for.
        channels.remove(.toast)
        channels.remove(.banner)
        channels.remove(.sound)
    case .normal:
        break
    }
    return channels
}

private func severityChannels(for event: SignalEvent,
                              context: DeliveryContext) -> Set<DeliveryChannel> {
    let appIsVisible: Bool = {
        guard case .app(let id) = event.source else { return context.hostIsFrontmost }
        return context.hostIsFrontmost && context.visibleAppIDs.contains(id)
    }()
    let present = context.hostIsFrontmost

    switch (event.severity, present, appIsVisible) {
    case (.info, true, _):            return []
    case (.info, false, _):           return [.badge]
    case (.success, true, true):      return [.toast]
    case (.success, true, false):     return [.badge]
    case (.success, false, _):        return [.badge, .banner]
    case (.warning, true, true):      return [.toast]
    case (.warning, true, false):     return [.badge, .toast]
    case (.warning, false, _):        return [.badge, .banner]
    case (.failure, true, true):      return [.toast, .sound]
    case (.failure, true, false):     return [.badge, .toast, .sound]
    case (.failure, false, _):        return [.badge, .banner, .sound]
    }
}

/// Severity as an order. Not `CaseIterable`'s index: that is a declaration
/// detail, and letting it become behaviour means reordering the enum silently
/// changes what every interrupt floor means.
private func severityRank(_ severity: SignalSeverity) -> Int {
    switch severity {
    case .info: return 0
    case .success: return 1
    case .warning: return 2
    case .failure: return 3
    @unknown default: return 0
    }
}
