import Testing
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite struct AinkradAPITests {
    @Test func acceptsWithinRange() {
        #expect(AinkradAppKit.isCompatible(bundleAPIVersion: 6, minSupported: 6, current: 7))
        #expect(AinkradAppKit.isCompatible(bundleAPIVersion: 7, minSupported: 6, current: 7))
    }
    @Test func rejectsBelowMin() {
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 5, minSupported: 6, current: 7))
    }
    @Test func rejectsAboveCurrent() {
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 8, minSupported: 6, current: 7))
    }
}

@Suite("Generation 10")
struct Generation10Tests {
    @Test("the generation is 10 and the window widened to two releases")
    func generationAndWindow() {
        #expect(AinkradAppKit.apiVersion == 10)
        #expect(AinkradAppKit.minSupportedAPIVersion == 8)
        #expect(AinkradAppKit.minSupportedAPIVersion == AinkradAppKit.apiVersion - 2,
                "widened at generation 10 — see the reasoning on the property")
    }

    @Test("generation 8, 9 and 10 all load; 7 and 11 do not")
    func compatibilityRange() {
        func loadable(_ v: Int) -> Bool {
            AinkradAppKit.isCompatible(bundleAPIVersion: v,
                                       minSupported: AinkradAppKit.minSupportedAPIVersion,
                                       current: AinkradAppKit.apiVersion)
        }
        #expect(loadable(9))
        #expect(loadable(10))
        // The reason the window widened, asserted so it cannot quietly narrow
        // again: at the time generation 10 shipped, EVERY plugin bundle
        // actually installed was still generation 8. A floor of 9 would have
        // launched the host with none of the user's apps.
        #expect(loadable(8), "generation 8 bundles are still in the field and must keep loading")
        #expect(!loadable(7))
        #expect(!loadable(11), "a bundle from the future is not loadable either")
    }
}
