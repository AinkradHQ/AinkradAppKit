import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradTheme environment")
struct AinkradThemeEnvironmentTests {
    @Test("default theme is present and dark")
    func hasDefault() {
        let env = EnvironmentValues()
        #expect(env.ainkradTheme.themeID.isEmpty == false)
    }

    @Test("font resolver scales role sizes")
    func fontScales() {
        let base = AinkradTypography(fontFamilyName: nil, scale: 1.0)
        let big = AinkradTypography(fontFamilyName: nil, scale: 2.0)
        #expect(AinkradFontResolver.pointSize(.body, typography: base) == 14)
        #expect(AinkradFontResolver.pointSize(.body, typography: big) == 28)
    }
}
