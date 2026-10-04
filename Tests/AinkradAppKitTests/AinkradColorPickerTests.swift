import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradColorPicker hex conversion")
struct AinkradColorPickerHexTests {
    @Test("parses a 6-digit RRGGBB hex into sRGB components")
    func parsesHex() {
        let rgb = rgbComponents(fromHex: "FF8000")
        #expect(rgb != nil)
        #expect(abs((rgb?.red ?? 0) - 1.0) < 1e-9)
        #expect(abs((rgb?.green ?? 0) - 128.0 / 255.0) < 1e-9)
        #expect(abs((rgb?.blue ?? 0) - 0.0) < 1e-9)
    }

    @Test("tolerates a leading # and lowercase digits")
    func toleratesPrefixAndCase() {
        #expect(rgbComponents(fromHex: "#ffffff") != nil)
        let white = rgbComponents(fromHex: "#ffffff")
        #expect(white?.red == 1 && white?.green == 1 && white?.blue == 1)
    }

    @Test("rejects malformed hex")
    func rejectsMalformed() {
        #expect(rgbComponents(fromHex: "FFF") == nil)  // too short
        #expect(rgbComponents(fromHex: "GGGGGG") == nil)  // non-hex
        #expect(rgbComponents(fromHex: "1234567") == nil)  // too long
        #expect(rgbComponents(fromHex: "") == nil)
    }

    @Test("formats sRGB components as uppercase RRGGBB, matching the host format")
    func formatsHex() {
        #expect(hexString(red: 1, green: 128.0 / 255.0, blue: 0) == "FF8000")
        #expect(hexString(red: 0, green: 0, blue: 0) == "000000")
        #expect(hexString(red: 1, green: 1, blue: 1) == "FFFFFF")
    }

    @Test("clamps out-of-range components before formatting")
    func clampsComponents() {
        #expect(hexString(red: 2, green: -1, blue: 0.5) == "FF0080")
    }

    @Test("hex -> components -> hex round-trips for every byte value")
    func hexRoundTrip() {
        for hex in ["000000", "FFFFFF", "FF8000", "123456", "ABCDEF", "0A0B0C"] {
            let rgb = rgbComponents(fromHex: hex)
            #expect(rgb != nil)
            let back = hexString(red: rgb!.red, green: rgb!.green, blue: rgb!.blue)
            #expect(back == hex)
        }
    }

    @Test("color(fromHex:) round-trips back to the same hex via sRGB")
    func colorFromHexRoundTrip() {
        for hex in ["FF8000", "3366CC", "000000", "FFFFFF"] {
            let c = color(fromHex: hex)
            #expect(c != nil)
            let rgb = rgbComponents(of: c!)
            #expect(rgb != nil)
            #expect(hexString(red: rgb!.red, green: rgb!.green, blue: rgb!.blue) == hex)
        }
    }
}
