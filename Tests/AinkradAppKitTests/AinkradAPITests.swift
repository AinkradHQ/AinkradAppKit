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

@Suite("Generation 12")
struct Generation12Tests {
    @Test("the generation is 12 and the window is still two releases")
    func generationAndWindow() {
        #expect(AinkradAppKit.apiVersion == 12)
        #expect(AinkradAppKit.minSupportedAPIVersion == 10)
        #expect(
            AinkradAppKit.minSupportedAPIVersion == AinkradAppKit.apiVersion - 2,
            "widened at generation 10 — see the reasoning on the property")
    }

    @Test("generation 10, 11 and 12 all load; 9 and 13 do not")
    func compatibilityRange() {
        func loadable(_ v: Int) -> Bool {
            AinkradAppKit.isCompatible(
                bundleAPIVersion: v,
                minSupported: AinkradAppKit.minSupportedAPIVersion,
                current: AinkradAppKit.apiVersion)
        }
        #expect(loadable(10))
        #expect(loadable(11))
        #expect(loadable(12))

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
        //
        // Checked again for generation 12: on 2026-10-08 every bundle in
        // `Cache/Plugins` — gitmage, leyline, lore, quest, raven, rune, thrall,
        // whisper — reported `AinkradAPIVersion = 11`, so a floor of 10 strands
        // nothing.
        #expect(!loadable(8))
        #expect(!loadable(9), "generation 9 left the window when the generation became 12")
        #expect(!loadable(13), "a bundle from the future is not loadable either")
    }
}
