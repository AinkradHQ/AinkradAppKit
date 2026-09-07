import Testing
import CoreGraphics
import SwiftUI
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradSpacing")
struct AinkradSpacingTests {
    @Test("spacing ramp uses the documented 4-pt base scale")
    func ramp() {
        #expect(AinkradSpacing.xs == 4)
        #expect(AinkradSpacing.sm == 8)
        #expect(AinkradSpacing.md == 12)
        #expect(AinkradSpacing.lg == 16)
        #expect(AinkradSpacing.xl == 24)
        #expect(AinkradSpacing.xxl == 32)
    }

    @Test("ramp is strictly increasing")
    func monotonic() {
        let steps = [AinkradSpacing.xs, AinkradSpacing.sm, AinkradSpacing.md, AinkradSpacing.lg, AinkradSpacing.xl, AinkradSpacing.xxl]
        #expect(zip(steps, steps.dropFirst()).allSatisfy { $0 < $1 })
    }
}

@Suite("AinkradRadius")
struct AinkradRadiusTests {
    @Test("radius steps; panel stays 14 to preserve current chrome")
    func steps() {
        #expect(AinkradRadius.sm == 8)
        #expect(AinkradRadius.md == 12)
        #expect(AinkradRadius.lg == 14)
        #expect(AinkradRadius.panel == 14)
    }
}

@Suite("AinkradElevation")
struct AinkradElevationTests {
    @Test("level0 is a no-op shadow")
    func flat() {
        #expect(AinkradElevation.level0 == ShadowSpec(color: .clear, radius: 0, x: 0, y: 0))
    }

    @Test("elevation deepens with level")
    func deepens() {
        #expect(AinkradElevation.level1.radius < AinkradElevation.level2.radius)
        #expect(AinkradElevation.level1.y < AinkradElevation.level2.y)
    }
}

@Suite("AinkradMotion")
struct AinkradMotionTests {
    @Test("durations are ordered fast < base < slow")
    func durations() {
        #expect(AinkradMotion.durationFast == 0.15)
        #expect(AinkradMotion.durationBase == 0.25)
        #expect(AinkradMotion.durationSlow == 0.40)
        #expect(AinkradMotion.durationFast < AinkradMotion.durationBase)
        #expect(AinkradMotion.durationBase < AinkradMotion.durationSlow)
    }
}

@Suite("AinkradTypeRole")
struct AinkradTypeRoleTests {
    @Test("role base sizes match the documented ramp")
    func sizes() {
        #expect(AinkradTypeRole.display.size == 28)
        #expect(AinkradTypeRole.title.size == 20)
        #expect(AinkradTypeRole.headline.size == 16)
        #expect(AinkradTypeRole.body.size == 14)
        #expect(AinkradTypeRole.caption.size == 11)
        #expect(AinkradTypeRole.mono.size == 13)
    }

    @Test("display is the largest role")
    func displayLargest() {
        let maxSize = AinkradTypeRole.allCases.map(\.size).max()
        #expect(maxSize == AinkradTypeRole.display.size)
    }
}

@Suite("AinkradMotion materialize")
struct AinkradMotionMaterializeTests {
    @Test("materialize duration sits above the base transition")
    func materializeDuration() {
        #expect(AinkradMotion.durationMaterialize == 0.55)
        #expect(AinkradMotion.durationMaterialize > AinkradMotion.durationSlow)
    }
}

@Suite("AinkradAppKit generation")
struct AinkradAppKitVersionTests {
    @Test("the design scales shipped in generation 8 and are still present")
    func scalesStillShipped() {
        // Not `== 8`: this test is about the scales, and pinning the exact
        // generation here made every bump edit an unrelated file.
        #expect(AinkradAppKit.apiVersion >= 8)
    }

    @Test("v4 plugins remain loadable under a v7 host (additive bump)")
    func v4StillCompatible() {
        #expect(AinkradAppKit.isCompatible(bundleAPIVersion: 4, minSupported: 4, current: 7))
        #expect(AinkradAppKit.isCompatible(bundleAPIVersion: 7, minSupported: 4, current: 7))
        #expect(!AinkradAppKit.isCompatible(bundleAPIVersion: 8, minSupported: 4, current: 7))
    }
}
