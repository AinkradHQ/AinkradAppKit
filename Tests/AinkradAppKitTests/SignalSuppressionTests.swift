import Testing
import Foundation
@testable import AinkradSignal

@Suite("Signal suppression window")
struct SignalSuppressionTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    /// A date at a given hour and minute on a fixed day, in UTC.
    private func at(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(timeZone: TimeZone(identifier: "UTC"),
                                           year: 2026, month: 9, day: 3,
                                           hour: hour, minute: minute))!
    }

    @Test("with no schedule and no snooze, nothing is ever suppressed")
    func idleWindowSuppressesNothing() {
        let window = SuppressionWindow()
        #expect(!window.isSuppressing(at: at(3), calendar: calendar))
        #expect(!window.isSuppressing(at: at(14), calendar: calendar))
    }

    @Test("a same-day window suppresses inside it and not outside")
    func sameDayWindow() {
        var window = SuppressionWindow()
        window.quietStartMinute = 9 * 60      // 09:00
        window.quietEndMinute = 17 * 60       // 17:00
        #expect(window.isSuppressing(at: at(12), calendar: calendar))
        #expect(window.isSuppressing(at: at(9), calendar: calendar), "start is inclusive")
        #expect(!window.isSuppressing(at: at(17), calendar: calendar), "end is exclusive")
        #expect(!window.isSuppressing(at: at(8, 59), calendar: calendar))
        #expect(!window.isSuppressing(at: at(23), calendar: calendar))
    }

    @Test("a window that wraps midnight suppresses across the boundary")
    func wrappingWindow() {
        var window = SuppressionWindow()
        window.quietStartMinute = 22 * 60     // 22:00
        window.quietEndMinute = 7 * 60        // 07:00
        #expect(window.isSuppressing(at: at(23, 30), calendar: calendar), "before midnight")
        #expect(window.isSuppressing(at: at(3), calendar: calendar), "after midnight")
        #expect(window.isSuppressing(at: at(22), calendar: calendar), "start is inclusive")
        #expect(!window.isSuppressing(at: at(7), calendar: calendar), "end is exclusive")
        #expect(!window.isSuppressing(at: at(12), calendar: calendar), "the middle of the day")
    }

    @Test("start equal to end means NO window, not a silent day")
    func degenerateWindowIsNoWindow() {
        var window = SuppressionWindow()
        window.quietStartMinute = 9 * 60
        window.quietEndMinute = 9 * 60
        // A user who sets both ends to the same time meant nothing. Reading it
        // as a 24-hour window would silence them for a day and they would never
        // guess why.
        #expect(!window.isSuppressing(at: at(9), calendar: calendar))
        #expect(!window.isSuppressing(at: at(21), calendar: calendar))
    }

    @Test("a half-configured schedule is ignored rather than half-applied")
    func halfConfiguredIsIgnored() {
        var window = SuppressionWindow()
        window.quietStartMinute = 22 * 60
        #expect(!window.isSuppressing(at: at(23), calendar: calendar))
    }

    @Test("a snooze in the future suppresses, and one in the past does not")
    func snooze() {
        var window = SuppressionWindow()
        window.snoozedUntil = at(15)
        #expect(window.isSuppressing(at: at(14, 59), calendar: calendar))
        #expect(!window.isSuppressing(at: at(15), calendar: calendar), "the deadline has passed")
        #expect(!window.isSuppressing(at: at(16), calendar: calendar))
    }

    @Test("a snooze suppresses even outside the quiet-hours schedule")
    func snoozeIsIndependentOfSchedule() {
        var window = SuppressionWindow()
        window.quietStartMinute = 22 * 60
        window.quietEndMinute = 7 * 60
        window.snoozedUntil = at(13)
        #expect(window.isSuppressing(at: at(12), calendar: calendar))
    }

    @Test("sound-only mode is carried on the window, not decided by it")
    func modeIsData() {
        var window = SuppressionWindow()
        window.mode = .soundOnly
        // `isSuppressing` answers WHETHER, never WHICH channels — that belongs
        // to `route`, where every branch is a table row.
        #expect(window.mode == .soundOnly)
    }

    @Test("a window written before this type existed decodes to no suppression")
    func decodesAbsentFields() throws {
        let window = try JSONDecoder().decode(SuppressionWindow.self, from: Data("{}".utf8))
        #expect(window == SuppressionWindow())
        #expect(!window.isSuppressing(at: at(3), calendar: calendar))
    }
}
