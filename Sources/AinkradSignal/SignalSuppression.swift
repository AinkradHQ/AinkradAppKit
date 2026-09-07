import Foundation

/// When notifications should stay quiet: a recurring schedule and an ad-hoc
/// snooze, in one type.
///
/// One type rather than two, because they are one concept. "Quiet hours",
/// "mute for an hour" and "mute until tomorrow" all answer the same question at
/// the same point in routing — *is now a quiet moment?* — and the moment they
/// live in separate types, `route` needs two checks that can disagree.
///
/// This answers WHETHER, never WHICH channels. Channel selection belongs to
/// `route`, where every branch is a table row a test can pin.
public struct SuppressionWindow: Codable, Sendable, Equatable {
    /// What a quiet moment means.
    public enum Mode: String, Codable, Sendable {
        /// Nothing but the feed. The log is never optional.
        case everything
        /// Keep the toast and the banner, drop the chime — for a user who wants
        /// to see things land without being audibly interrupted.
        case soundOnly
    }

    /// Minutes from local midnight. Both ends are needed for a schedule to
    /// exist: a start with no end is a half-finished setting, and applying half
    /// of it would silence the user until they worked out why.
    public var quietStartMinute: Int?
    public var quietEndMinute: Int?
    public var mode: Mode
    /// An absolute deadline, so a snooze survives a relaunch rather than
    /// quietly expiring when the app restarts.
    public var snoozedUntil: Date?

    public init(quietStartMinute: Int? = nil,
                quietEndMinute: Int? = nil,
                mode: Mode = .everything,
                snoozedUntil: Date? = nil) {
        self.quietStartMinute = quietStartMinute
        self.quietEndMinute = quietEndMinute
        self.mode = mode
        self.snoozedUntil = snoozedUntil
    }

    /// Hand-written, so a preferences file from before this type existed
    /// decodes to "never suppressing" rather than being rejected outright and
    /// resetting every notification preference the user had set.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        quietStartMinute = try c.decodeIfPresent(Int.self, forKey: .quietStartMinute)
        quietEndMinute = try c.decodeIfPresent(Int.self, forKey: .quietEndMinute)
        mode = try c.decodeIfPresent(Mode.self, forKey: .mode) ?? .everything
        snoozedUntil = try c.decodeIfPresent(Date.self, forKey: .snoozedUntil)
    }

    public func isSuppressing(at now: Date, calendar: Calendar = .current) -> Bool {
        if let snoozedUntil, now < snoozedUntil { return true }
        return isInQuietHours(at: now, calendar: calendar)
    }

    private func isInQuietHours(at now: Date, calendar: Calendar) -> Bool {
        guard let start = quietStartMinute, let end = quietEndMinute,
              start != end else { return false }
        let components = calendar.dateComponents([.hour, .minute], from: now)
        guard let hour = components.hour, let minute = components.minute else { return false }
        let current = hour * 60 + minute
        // Minute arithmetic rather than comparing dates, because the interesting
        // case is a window that WRAPS midnight (22:00 → 07:00). Comparing
        // "after start and before end" is false for every instant of such a
        // window, which is the naive bug this shape exists to avoid.
        return start < end
            ? (current >= start && current < end)
            : (current >= start || current < end)
    }
}
