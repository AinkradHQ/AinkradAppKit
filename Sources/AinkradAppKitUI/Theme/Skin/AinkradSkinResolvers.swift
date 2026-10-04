// design-lint: allow-file font-size,radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — resolve helpers
import CoreGraphics
import SwiftUI

extension AinkradSkin {
    public func color(
        _ token: AinkradColorToken,
        tint: Color? = nil,
        state: AinkradControlState = []
    ) -> Color {
        resolveColorToken(token, palette: palette, tint: tint)
    }

    public func color(
        _ stateColor: AinkradStateColor,
        tint: Color? = nil,
        state: AinkradControlState = []
    ) -> Color {
        let token = stateColor.resolve(state)
        return resolveColorToken(token, palette: palette, tint: tint)
    }

    public func font(
        _ token: AinkradFontToken,
        typography: AinkradTypography = AinkradTypography()
    ) -> Font {
        var baseSize: CGFloat = 14
        if let roleName = token.role {
            baseSize = sizeForTypeRole(roleName, roles: type.roles)
        } else if let num = token.size {
            baseSize = CGFloat(num)
        } else if let key = token.sizeKey {
            baseSize = CGFloat(sizeForTypeKey(key, sizes: type.sizes))
        }

        let isScaled = token.scaled ?? true
        let finalSize = isScaled ? baseSize * typography.scale : baseSize
        let weight = parseWeight(token.weight)

        var font: Font
        if token.mono == "system" {
            font = Font.system(size: finalSize, weight: weight, design: .monospaced)
        } else if token.mono == "family" {
            font = Font.custom(type.monoFamily, size: finalSize).weight(weight)
        } else if let family = typography.fontFamilyName {
            font = Font.custom(family, size: finalSize).weight(weight)
        } else if let uiFamily = type.uiFamily {
            font = Font.custom(uiFamily, size: finalSize).weight(weight)
        } else {
            font = Font.system(size: finalSize, weight: weight)
        }

        if token.monospacedDigits == true {
            font = font.monospacedDigit()
        }
        return font
    }

    public func animation(_ token: AinkradAnimationToken) -> Animation {
        var dur: Double = 0.25
        if let d = token.duration {
            dur = d
        } else if let key = token.durationKey {
            dur = durationForKey(key, motion: motion)
        }

        switch token.curve {
        case "easeIn":
            return .easeIn(duration: dur)
        case "easeOut":
            return .easeOut(duration: dur)
        case "easeInOut":
            return .easeInOut(duration: dur)
        case "linear":
            return .linear(duration: dur)
        case "spring":
            let resp = token.response ?? 0.34
            let damp = token.damping ?? 0.82
            return .spring(response: resp, dampingFraction: damp)
        case "snappy":
            return .snappy(duration: dur)
        default:
            return .easeInOut(duration: dur)
        }
    }
}

// MARK: - File-scope Helper Functions

private func resolveColorToken(_ token: AinkradColorToken, palette: AinkradSkinPalette, tint: Color?) -> Color {
    switch token {
    case .clear:
        return .clear
    case .tint(let alpha):
        if let tint {
            return alpha == 1.0 ? tint : tint.opacity(alpha)
        }
        return resolveColorToken(palette.accentPrimary, palette: palette, tint: nil).opacity(alpha)
    case .hex(let r, let g, let b, let a):
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    case .palette(let key, let alpha):
        let baseColor = colorForPaletteKey(key, palette: palette)
        return alpha == 1.0 ? baseColor : baseColor.opacity(alpha)
    }
}

private func colorForPaletteKey(_ key: String, palette: AinkradSkinPalette) -> Color {
    switch key {
    case "background": return colorFromToken(palette.background)
    case "surface": return colorFromToken(palette.surface)
    case "surfaceElevated": return colorFromToken(palette.surfaceElevated)
    case "accentPrimary": return colorFromToken(palette.accentPrimary)
    case "accentSecondary": return colorFromToken(palette.accentSecondary)
    case "accentTertiary": return colorFromToken(palette.accentTertiary)
    case "foreground": return colorFromToken(palette.foreground)
    case "success": return colorFromToken(palette.success)
    case "warning": return colorFromToken(palette.warning)
    case "danger": return colorFromToken(palette.danger)
    case "black": return Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
    case "white": return Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
    default: return colorFromToken(palette.foreground)
    }
}

private func colorFromToken(_ token: AinkradColorToken) -> Color {
    switch token {
    case .hex(let r, let g, let b, let a):
        return Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    default:
        return .clear
    }
}

private func sizeForTypeRole(_ role: String, roles: AinkradTypeRoleTokens) -> CGFloat {
    switch role {
    case "display": return CGFloat(roles.display)
    case "title": return CGFloat(roles.title)
    case "headline": return CGFloat(roles.headline)
    case "body": return CGFloat(roles.body)
    case "caption": return CGFloat(roles.caption)
    case "mono": return CGFloat(roles.mono)
    default: return 14
    }
}

private func sizeForTypeKey(_ key: String, sizes: AinkradTypeSizeTokens) -> Double {
    switch key {
    case "t6": return sizes.t6
    case "t6_5": return sizes.t6_5
    case "t7": return sizes.t7
    case "t8": return sizes.t8
    case "t8_5": return sizes.t8_5
    case "t9": return sizes.t9
    case "t9_5": return sizes.t9_5
    case "t10": return sizes.t10
    case "t10_5": return sizes.t10_5
    case "t11": return sizes.t11
    case "t12": return sizes.t12
    case "t12_5": return sizes.t12_5
    case "t13": return sizes.t13
    case "t14": return sizes.t14
    case "t15": return sizes.t15
    case "t16": return sizes.t16
    case "t17": return sizes.t17
    case "t18": return sizes.t18
    case "t20": return sizes.t20
    case "t21": return sizes.t21
    case "t24": return sizes.t24
    case "t26": return sizes.t26
    case "t28": return sizes.t28
    case "t30": return sizes.t30
    case "t34": return sizes.t34
    case "t40": return sizes.t40
    default: return 14
    }
}

private func parseWeight(_ weightStr: String?) -> Font.Weight {
    guard let weightStr else { return .regular }
    switch weightStr {
    case "ultraLight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "regular": return .regular
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return .regular
    }
}

private func durationForKey(_ key: String, motion: AinkradMotionTokens) -> Double {
    switch key {
    case "fast": return motion.fast
    case "base": return motion.base
    case "slow": return motion.slow
    case "materialize": return motion.materialize
    case "d0_08": return motion.durations.d0_08
    case "d0_1": return motion.durations.d0_1
    case "d0_12": return motion.durations.d0_12
    case "d0_14": return motion.durations.d0_14
    case "d0_16": return motion.durations.d0_16
    case "d0_18": return motion.durations.d0_18
    case "d0_2": return motion.durations.d0_2
    case "d0_22": return motion.durations.d0_22
    case "d0_32": return motion.durations.d0_32
    case "breathe": return motion.durations.breathe
    default: return 0.25
    }
}
