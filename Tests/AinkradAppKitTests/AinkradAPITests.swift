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

@Suite("Generation 11")
struct Generation11Tests {
    @Test("the generation is 11 and the window is still two releases")
    func generationAndWindow() {
        #expect(AinkradAppKit.apiVersion == 11)
        #expect(AinkradAppKit.minSupportedAPIVersion == 9)
        #expect(AinkradAppKit.minSupportedAPIVersion == AinkradAppKit.apiVersion - 2,
                "widened at generation 10 — see the reasoning on the property")
    }

    @Test("generation 9, 10 and 11 all load; 8 and 12 do not")
    func compatibilityRange() {
        func loadable(_ v: Int) -> Bool {
            AinkradAppKit.isCompatible(bundleAPIVersion: v,
                                       minSupported: AinkradAppKit.minSupportedAPIVersion,
                                       current: AinkradAppKit.apiVersion)
        }
        #expect(loadable(9))
        #expect(loadable(10))
        #expect(loadable(11))

        // Generation 10 had to keep a floor of 8 because every bundle then
        // INSTALLED was still generation 8, and a floor of 9 would have started
        // the host with none of the user's apps. Moving the floor to 9 here is
        // safe only because that is no longer true: on 2026-09-18 every bundle
        // in `Cache/Plugins` — gitmage, leyline, lore, quest, raven, rune,
        // thrall — reported `AinkradAPIVersion = 10`.
        //
        // Check the field again before moving this floor a third time. The
        // failure is silent: a stranded bundle does not warn, it just never
        // appears, and Ainkrad looks like it has no apps.
        #expect(!loadable(8), "generation 8 left the window when the generation became 11")
        #expect(!loadable(12), "a bundle from the future is not loadable either")
    }
}
