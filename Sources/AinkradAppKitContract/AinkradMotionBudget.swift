import Foundation

/// How fast decorative motion is allowed to run right now.
///
/// This is the one place that decides; every `TimelineView` in the host and in
/// every plugin reads the answer rather than choosing for itself. Pure value
/// type with no AppKit or SwiftUI import so the decision table is unit tested
/// directly — `AinkradMotionBudgetObserver` supplies the live inputs.
///
/// WHY a cap at all: `TimelineView(.animation)` with no `minimumInterval` runs
/// at the display refresh rate — 120 Hz on ProMotion — for animations whose
/// slowest is a 3.5-second sweep. The extra frames are invisible and are paid
/// for in battery.
public struct AinkradMotionBudget: Equatable, Sendable {
    public let isAppActive: Bool
    public let isWindowVisible: Bool
    public let isLowPower: Bool
    public let reduceMotion: Bool

    public init(isAppActive: Bool, isWindowVisible: Bool, isLowPower: Bool, reduceMotion: Bool) {
        self.isAppActive = isAppActive
        self.isWindowVisible = isWindowVisible
        self.isLowPower = isLowPower
        self.reduceMotion = reduceMotion
    }

    /// Seconds between frames, or `nil` for "do not animate at all".
    /// Order matters — the first matching rule wins, cheapest first.
    public var minimumInterval: Double? {
        if !isWindowVisible { return nil }
        if !isAppActive { return 1.0 / 5.0 }
        if isLowPower || reduceMotion { return 1.0 / 10.0 }
        return 1.0 / 30.0
    }

    public var isAnimating: Bool { minimumInterval != nil }

    /// The default for previews and any surface no host has wrapped. Animates,
    /// so an un-hosted component looks the way its author designed it.
    public static let full = AinkradMotionBudget(
        isAppActive: true, isWindowVisible: true, isLowPower: false, reduceMotion: false)

    public static let frozen = AinkradMotionBudget(
        isAppActive: true, isWindowVisible: false, isLowPower: false, reduceMotion: false)
}
