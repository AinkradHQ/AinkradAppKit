import Testing
import CoreGraphics
@testable import AinkradAppKit

/// Overlay sizes. Fixed points, capped at what fits.
@Suite("PluginOverlaySize")
struct PluginOverlaySizeTests {

    /// A full-screen host window on the machine this was specified against
    /// (3456x2234 retina = 1728x1117 points).
    private let bigWindow = CGSize(width: 1728, height: 1117)

    @Test("Large is actually large — the bug that prompted the rewrite")
    func largeIsLarge() {
        // The fraction scheme resolved large to 980x894 here: the ceiling clamp
        // ate the fraction before it did anything, so "large" was barely bigger
        // than medium.
        let large = PluginOverlaySize.large.resolved(in: bigWindow)
        let medium = PluginOverlaySize.medium.resolved(in: bigWindow)
        #expect(large.width > medium.width * 1.4,
                "large must be decisively larger than medium, not a nudge")
        #expect(large.width >= 1200)
    }

    @Test("The three sizes are strictly ordered on both axes")
    func sizesAreOrdered() {
        let s = PluginOverlaySize.small.resolved(in: bigWindow)
        let m = PluginOverlaySize.medium.resolved(in: bigWindow)
        let l = PluginOverlaySize.large.resolved(in: bigWindow)
        #expect(s.width < m.width && m.width < l.width)
        #expect(s.height < m.height && m.height < l.height)
    }

    @Test("A chosen size IS that size when the window has room")
    func fixedMeansFixed() {
        // The whole point of dropping fractions: pick large, get large.
        for size in PluginOverlaySize.allCases {
            #expect(size.resolved(in: bigWindow) == size.points)
        }
    }

    @Test("A size never overflows a small window, so the scrim stays clickable")
    func neverOverflows() {
        // An overflow guard, not a design choice: a 1280 pt panel in a 1000 pt
        // window would sit edge to edge with nothing left to click to dismiss.
        let small = CGSize(width: 1000, height: 700)
        for size in PluginOverlaySize.allCases {
            let r = size.resolved(in: small)
            #expect(r.width <= small.width * 0.9)
            #expect(r.height <= small.height * 0.9)
        }
    }

    @Test("Medium is the default")
    func mediumIsDefault() {
        #expect(PluginOverlaySize.default == .medium)
    }
}
