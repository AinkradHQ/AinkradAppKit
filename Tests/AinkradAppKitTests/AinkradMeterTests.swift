import Foundation
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("meterFraction")
struct MeterFractionTests {
    @Test("half value over total is 0.5")
    func half() {
        #expect(meterFraction(value: 5, total: 10) == 0.5)
    }

    @Test("zero value is 0")
    func zero() {
        #expect(meterFraction(value: 0, total: 10) == 0)
    }

    @Test("value equal to total is 1")
    func full() {
        #expect(meterFraction(value: 10, total: 10) == 1)
    }

    @Test("value beyond total clamps to 1")
    func overshoot() {
        #expect(meterFraction(value: 20, total: 10) == 1)
    }

    @Test("negative value clamps to 0")
    func negative() {
        #expect(meterFraction(value: -5, total: 10) == 0)
    }

    @Test("a zero or negative total is division-safe and yields 0")
    func zeroTotal() {
        #expect(meterFraction(value: 5, total: 0) == 0)
        #expect(meterFraction(value: 5, total: -1) == 0)
    }
}
