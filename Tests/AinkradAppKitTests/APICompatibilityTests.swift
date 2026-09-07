import Testing
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

struct APICompatibilityTests {
    @Test("the SDK reports a generation at or beyond 8")
    func currentVersion() {
        // The exact number is pinned once, in `Generation9Tests`.
        #expect(AinkradAppKit.apiVersion >= 8)
    }

    @Test("a version inside the supported range is compatible")
    func inRange() {
        #expect(AinkradAppKit.isCompatible(bundleAPIVersion: 1, minSupported: 1, current: 1))
    }

    @Test("a version below the minimum is rejected")
    func belowMin() {
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 0, minSupported: 1, current: 3))
    }

    @Test("a version above the current is rejected")
    func aboveCurrent() {
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 4, minSupported: 1, current: 3))
    }
}
