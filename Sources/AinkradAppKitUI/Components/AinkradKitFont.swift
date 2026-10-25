import SwiftUI

extension View {
    /// The skin's font at a size key (`"t12"`, `"t10_5"`), mono when asked — the kit-internal shorthand the Citadel
    /// components share so a size is spelled once.
    func kitFont(_ size: String, weight: String? = nil, mono: Bool = false) -> some View {
        modifier(KitFontModifier(size: size, weight: weight, mono: mono))
    }
}

private struct KitFontModifier: ViewModifier {
    let size: String
    let weight: String?
    let mono: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    func body(content: Content) -> some View {
        content.font(
            skin.font(AinkradFontToken(sizeKey: size, weight: weight, mono: mono ? "family" : nil), typography: typo))
    }
}
