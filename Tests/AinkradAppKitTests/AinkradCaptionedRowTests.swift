import Testing
import SwiftUI
@testable import AinkradAppKitUI

@Suite("AinkradCaptionedRow accessibility")
@MainActor
struct AinkradCaptionedRowTests {
    @Test("the caption is retained, because it is the row's accessibility label")
    func captionIsCarried() {
        // The caption used to be `.accessibilityHidden(true)` and discarded, on
        // the reasoning that the control below carried the real label. None of
        // the kit's form controls do — so a settings pane read as a list of
        // anonymous buttons, with five identical "Alert / Quiet / Off" pickers
        // and nothing to say which source each belonged to.
        //
        // The modifiers are not inspectable from here; this guards the input
        // they depend on. The behaviour itself needs a VoiceOver pass.
        let row = AinkradCaptionedRow("Delivery") { EmptyView() }
        #expect(row.caption == "Delivery")
    }
}

@Suite("Slider spoken value")
@MainActor
struct AinkradSliderAccessibilityTests {
    @Test("it is spoken as a percentage of its range, not as a raw double")
    func speaksAPercentage() {
        // "0.62" tells a listener nothing about how far along the control is.
        #expect(AinkradSlider.spokenValue(0.62, in: 0...1) == "62%")
        #expect(AinkradSlider.spokenValue(0, in: 0...1) == "0%")
        #expect(AinkradSlider.spokenValue(1, in: 0...1) == "100%")
    }

    @Test("a range that does not start at zero still reads as a proportion")
    func handlesOffsetRanges() {
        #expect(AinkradSlider.spokenValue(15, in: 10...20) == "50%")
    }

    @Test("a value outside the bounds is clamped rather than spoken as 140%")
    func clampsOutOfRange() {
        #expect(AinkradSlider.spokenValue(1.4, in: 0...1) == "100%")
        #expect(AinkradSlider.spokenValue(-3, in: 0...1) == "0%")
    }

    @Test("a degenerate range does not divide by zero")
    func survivesAnEmptyRange() {
        // `bounds` comes from a caller; a zero-width one must not crash or
        // produce NaN in a spoken string.
        let spoken = AinkradSlider.spokenValue(5, in: 5...5)
        #expect(spoken.hasSuffix("%"))
        #expect(!spoken.contains("nan"))
    }
}
