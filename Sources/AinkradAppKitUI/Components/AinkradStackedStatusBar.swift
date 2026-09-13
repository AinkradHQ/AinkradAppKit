import SwiftUI
import AinkradAppKitContract

/// One run in an `AinkradStackedStatusBar`: how many things are in a status.
public struct AinkradStatusRun: Equatable, Sendable {
    public var count: Int
    public var status: AinkradStatus

    public init(count: Int, status: AinkradStatus) {
        self.count = count
        self.status = status
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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors

    public init(runs: [AinkradStatusRun]) {
        self.runs = runs
    }

    public var body: some View {
        let ordered = orderedStatusRuns(runs)
        GeometryReader { geometry in
            let widths = statusRunWidths(for: ordered.map { $0.count }, in: geometry.size.width)
            HStack(spacing: stackedStatusBarSpacing) {
                ForEach(Array(zip(ordered, widths).enumerated()), id: \.offset) { _, segment in
                    Rectangle()
                        .fill(segment.0.status.color(in: theme, statusColors: statusColors))
                        .frame(width: segment.1)
                }
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
        .background(Capsule().fill(theme.foreground.opacity(0.12)))
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
            let left = statusSeverity(lhs.element.status), right = statusSeverity(rhs.element.status)
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
func statusRunWidths(for counts: [Int], in width: CGFloat, spacing: CGFloat = stackedStatusBarSpacing,
                     minimum: CGFloat = 2) -> [CGFloat] {
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
