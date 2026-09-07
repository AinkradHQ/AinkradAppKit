import SwiftUI
import AppKit
import AinkradAppKitContract

public extension Color {
    /// Black or white, whichever reads on top of this color. Used by filled
    /// controls (selected picker segment, primary button) for their label.
    var contrastingText: Color {
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? .white
        let luminance = 0.299 * ns.redComponent + 0.587 * ns.greenComponent + 0.114 * ns.blueComponent
        return luminance > 0.6 ? .black : .white
    }

    /// WCAG relative luminance.
    var relativeLuminance: Double {
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? .white
        func channel(_ v: CGFloat) -> Double {
            let c = Double(v)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(ns.redComponent)
            + 0.7152 * channel(ns.greenComponent)
            + 0.0722 * channel(ns.blueComponent)
    }

    /// WCAG contrast ratio against another colour, 1...21.
    ///
    /// Added here rather than as a new helper: `contrastingText` above already
    /// owns the "is this legible" question, and two places computing luminance
    /// differently is how a ramp passes one check and fails the other.
    func contrastRatio(against other: Color) -> Double {
        let a = relativeLuminance
        let b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}
