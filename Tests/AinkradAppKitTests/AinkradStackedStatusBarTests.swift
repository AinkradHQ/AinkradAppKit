import Foundation
import Testing
import SwiftUI
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradStackedStatusBar")
struct AinkradStackedStatusBarTests {
    private func drawnWidth(_ widths: [CGFloat], spacing: CGFloat = 1) -> CGFloat {
        widths.reduce(0, +) + spacing * CGFloat(max(0, widths.count - 1))
    }

    @Test("runs are drawn in severity order, worst last, keeping the caller's order within a status")
    func severityOrder() {
        let ordered = orderedStatusRuns([
            AinkradStatusRun(count: 3, status: .danger), AinkradStatusRun(count: 5, status: .neutral),
            AinkradStatusRun(count: 19, status: .success), AinkradStatusRun(count: 28, status: .warning),
            AinkradStatusRun(count: 2, status: .neutral)
        ])
        #expect(ordered.map { $0.status } == [.success, .neutral, .neutral, .warning, .danger])
        #expect(ordered.map { $0.count } == [19, 5, 2, 28, 3])
    }

    @Test("empty runs are dropped, so they take no segment and no gap")
    func dropsEmptyRuns() {
        let ordered = orderedStatusRuns([AinkradStatusRun(count: 0, status: .danger), AinkradStatusRun(count: 4, status: .success)])
        #expect(ordered.map { $0.status } == [.success])
    }

    @Test("widths are proportional to counts, after the gaps")
    func proportional() {
        #expect(statusRunWidths(for: [1, 1], in: 65) == [32, 32])
        #expect(statusRunWidths(for: [3, 1], in: 65) == [48, 16])
    }

    @Test("a single problem in a large stack still gets the 2 pt minimum")
    func minimumWidth() {
        let widths = statusRunWidths(for: [1_000, 1], in: 64)
        #expect(widths.last == 2)
    }

    /// Thrall's ribbon gave a small run its 2 pt without taking that width back
    /// from anyone, so the runs overflowed the bar and the capsule clip cut off
    /// the right end — the worst-status end, the one the minimum exists for.
    /// 1,000 running and 1 dead in 64 pt left the dead run about 0.06 pt.
    @Test("the runs never overflow the bar, so the worst run is never clipped")
    func neverOverflows() {
        for counts in [[1_000, 1], [500, 1, 1, 1], [90, 3, 2, 1, 1]] {
            let widths = statusRunWidths(for: counts, in: 64)
            #expect(drawnWidth(widths) <= 64 + 0.001, "counts \(counts) draw \(drawnWidth(widths)) pt in 64")
            #expect(widths.allSatisfy { $0 >= 2 - 0.001 })
        }
    }

    @Test("with more runs than fit at the minimum, every run gets an equal share rather than some vanishing")
    func tooManyRuns() {
        let widths = statusRunWidths(for: Array(repeating: 1, count: 40), in: 64)
        #expect(drawnWidth(widths) <= 64 + 0.001)
        #expect(Set(widths).count == 1)
    }

    @Test("no runs means no segments; the track alone is drawn")
    func empty() {
        #expect(statusRunWidths(for: [], in: 64).isEmpty)
        _ = AinkradStackedStatusBar(runs: [])
        _ = AinkradStackedStatusBar(runs: [AinkradStatusRun(count: 19, status: .success), AinkradStatusRun(count: 1, status: .danger)])
    }
}
