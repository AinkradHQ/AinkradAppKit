import AinkradAppKitContract
import SwiftUI

/// One run in an `AinkradStackedStatusBar`: how many things are in a status.
public struct AinkradStatusRun: Equatable, Sendable {
    public var count: Int
    public var status: AinkradStatus

    public init(count: Int, status: AinkradStatus) {
        self.count = count
        self.status = status
    }
}

/// One run in an `AinkradStackedStatusBar` drawn in a chart tone rather than
/// a status colour: a share of spend (priced / unpriced / subscription) or of
/// time (a run's stage timings). `value` is any non-negative amount.
public struct AinkradToneRun: Equatable, Sendable {
    public var value: Double
    public var tone: AinkradChartTone

    public init(value: Double, tone: AinkradChartTone) {
        self.value = value
        self.tone = tone
    }
}

/// A set of things in mixed states as one proportional bar — "19 running,
/// 28 exited, 1 created" in a glance.
///
/// `AinkradStatusBar` is single-value: it quantises one ratio into segments.
/// This draws several runs side by side instead, each as wide as its share of
/// the total.
///
/// - Runs are drawn in a fixed severity order — success, neutral, warning,
///   danger — worst last, so the eye lands on the problem end. Within one
///   status the caller's order is kept.
/// - Every non-empty run is at least 2 pt wide, so a single failed item in a
///   large set stays visible, which is the case this component exists for.
/// - An empty set still draws its track, so a row's geometry does not change
///   when the last item goes away.
///
/// Colours come from `\.ainkradStatusColors` through `AinkradStatus`, so the
/// bar follows the host theme. It is 4 pt tall and fills the width it is
/// offered; give it one with `.frame(width:)`.
///
/// Moved here from Thrall's `StateRibbon`.
public struct AinkradStackedStatusBar: View {
    private let runs: [AinkradStatusRun]
    /// Set by `init(toneRuns:)`: drawn in the caller's order, in chart tones.
    private var toneRuns: [AinkradToneRun]?

    @Environment(\.ainkradSkin) private var skin

    public init(runs: [AinkradStatusRun]) {
        self.runs = runs
    }

    /// Runs in chart tones, drawn in the order given (not severity order) —
    /// the spend split and the stage timings of Citadel 02, 05 and 09.
    /// Empty and negative runs are skipped; the 2 pt minimum still holds.
    public init(toneRuns: [AinkradToneRun]) {
        self.runs = []
        self.toneRuns = toneRuns
    }

    public var body: some View {
        let bar = skin.components.stackedStatusBar
        let segments: [(value: Double, color: Color)] =
            toneRuns.map { runs in runs.filter { $0.value > 0 }.map { ($0.value, $0.tone.color(skin)) } }
            ?? orderedStatusRuns(runs).map {
                (
                    Double($0.count),
                    $0.status.color(in: HostThemeTokens(skin: skin), statusColors: AinkradStatusColors(skin: skin))
                )
            }
        GeometryReader { geometry in
            let widths = runWidths(
                for: segments.map(\.value), in: geometry.size.width, spacing: bar.gap, minimum: bar.minRun)
            HStack(spacing: bar.gap) {
                ForEach(Array(zip(segments, widths).enumerated()), id: \.offset) { _, segment in
                    Rectangle()
                        .fill(segment.0.color)
                        .frame(width: segment.1)
                }
            }
        }
        .frame(height: bar.height)
        .clipShape(Capsule())
        .background(Capsule().fill(skin.color(bar.trackColor)))
    }
}

let stackedStatusBarSpacing: CGFloat = 1

/// Non-empty runs in severity order, worst last; stable within a status.
///
/// A free function, not a static on the view, and deliberately: on this
/// toolchain an internal static method of a public struct in this module traps
/// when its body runs a closure and a `@testable` test calls it. `filledSegments`
/// is the same shape for the same reason.
func orderedStatusRuns(_ runs: [AinkradStatusRun]) -> [AinkradStatusRun] {
    runs.enumerated()
        .filter { $0.element.count > 0 }
        .sorted { lhs, rhs in
            let left = statusSeverity(lhs.element.status)
            let right = statusSeverity(rhs.element.status)
            return left != right ? left < right : lhs.offset < rhs.offset
        }
        .map { $0.element }
}

func statusSeverity(_ status: AinkradStatus) -> Int {
    switch status {
    case .success: return 0
    case .neutral: return 1
    case .warning: return 2
    case .danger: return 3
    }
}

/// Each run's width: proportional to its count, but never under `minimum`.
///
/// A run that would fall under the minimum is given exactly the minimum,
/// and that width is taken back from the others — which then share what is
/// left in proportion — so the runs always fit the bar. Thrall's ribbon
/// added the minimum without taking it back, so the runs overflowed and the
/// capsule clip cut off the right-hand, worst-status end: 1,000 running and
/// 1 dead in 64 pt left the dead run about 0.06 pt of the 2 pt it was given.
func statusRunWidths(
    for counts: [Int], in width: CGFloat, spacing: CGFloat = stackedStatusBarSpacing,
    minimum: CGFloat = 2
) -> [CGFloat] {
    runWidths(for: counts.map(Double.init), in: width, spacing: spacing, minimum: minimum)
}

/// `statusRunWidths` for any non-negative amounts — tone runs are seconds or dollars.
func runWidths(
    for counts: [Double], in width: CGFloat, spacing: CGFloat = stackedStatusBarSpacing,
    minimum: CGFloat = 2
) -> [CGFloat] {
    guard counts.reduce(0, +) > 0 else { return [] }
    let available = max(0, width - spacing * CGFloat(counts.count - 1))
    // Too narrow for every run to get its minimum: equal shares, so none vanishes.
    guard available >= minimum * CGFloat(counts.count) else {
        return counts.map { _ in available / CGFloat(counts.count) }
    }
    var floored = Set<Int>()
    while true {
        let free = counts.indices.filter { !floored.contains($0) }
        let freeCount = CGFloat(free.reduce(0) { $0 + counts[$1] })
        let freeWidth = available - minimum * CGFloat(floored.count)
        let share = { (index: Int) in freeWidth * CGFloat(counts[index]) / freeCount }
        let newlyFloored = free.filter { share($0) < minimum }
        if newlyFloored.isEmpty {
            return counts.indices.map { floored.contains($0) ? minimum : share($0) }
        }
        floored.formUnion(newlyFloored)
    }
}
