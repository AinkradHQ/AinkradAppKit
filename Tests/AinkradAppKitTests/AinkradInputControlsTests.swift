import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradStepper clamp/step")
struct AinkradStepperTests {
    @Test("a value within range and on the step grid is unchanged")
    func withinRangeOnGrid() {
        #expect(steppedClamp(4, in: 0...10, step: 2) == 4)
    }

    @Test("a value above the upper bound clamps to it")
    func clampsAboveUpper() {
        #expect(steppedClamp(50, in: 0...10, step: 1) == 10)
    }

    @Test("a value below the lower bound clamps to it")
    func clampsBelowLower() {
        #expect(steppedClamp(-5, in: 0...10, step: 1) == 0)
    }

    @Test("a value off the step grid snaps down to the nearest step from the lower bound")
    func snapsToStepGrid() {
        #expect(steppedClamp(9, in: 0...10, step: 5) == 5)
        #expect(steppedClamp(4, in: 1...10, step: 3) == 4)  // 1 + 3*1 = 4, exact
    }

    @Test("incrementing then clamping stops exactly at the upper bound")
    func incrementStopsAtBound() {
        #expect(steppedClamp(9 + 5, in: 0...10, step: 5) == 10)
    }
}

@Suite("AinkradRangeSlider clamp")
struct AinkradRangeSliderTests {
    @Test("a range within bounds is returned unchanged")
    func withinBoundsUnchanged() {
        #expect(clampRange(2...8, within: 0...10) == 2...8)
    }

    @Test("a range extending past bounds is clamped on both ends")
    func clampsBothEnds() {
        #expect(clampRange(-5...20, within: 0...10) == 0...10)
    }

    @Test("a fully out-of-range pair collapses to a valid single point at the bound")
    func collapsesWhenBothPastUpper() {
        #expect(clampRange(15...16, within: 0...10) == 10...10)
    }
}
