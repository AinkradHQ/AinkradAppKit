import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("clampedPage")
struct ClampedPageTests {
    @Test("clamps within 0..<count")
    func withinRange() {
        #expect(clampedPage(2, count: 5) == 2)
    }

    @Test("clamps a negative page up to 0")
    func negativeClampsToZero() {
        #expect(clampedPage(-3, count: 5) == 0)
    }

    @Test("clamps a page past the end down to the last page")
    func overshootClampsToLast() {
        #expect(clampedPage(9, count: 5) == 4)
    }

    @Test("a zero/negative count clamps to 0")
    func zeroCountClampsToZero() {
        #expect(clampedPage(2, count: 0) == 0)
        #expect(clampedPage(-1, count: 0) == 0)
    }
}
