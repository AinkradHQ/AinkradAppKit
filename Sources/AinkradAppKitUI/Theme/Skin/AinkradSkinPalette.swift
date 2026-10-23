// design-lint: allow-file hex-color,raw-color theme layer — palette token definition
import Foundation

public struct AinkradSkinPalette: Codable, Equatable, Sendable {
    public var background: AinkradColorToken
    public var surface: AinkradColorToken
    public var surfaceElevated: AinkradColorToken
    public var accentPrimary: AinkradColorToken
    public var accentSecondary: AinkradColorToken
    public var accentTertiary: AinkradColorToken
    public var foreground: AinkradColorToken
    public var success: AinkradColorToken
    public var warning: AinkradColorToken
    public var danger: AinkradColorToken
    public var black: AinkradColorToken
    public var white: AinkradColorToken
    /// Subscription spend, the Lead role. Added after the other keys, so the
    /// init leaves it at Neon's violet; a theme file sets it (format 3).
    public var accentViolet: AinkradColorToken = AinkradSkinPalette.neonViolet

    public init(
        background: AinkradColorToken,
        surface: AinkradColorToken,
        surfaceElevated: AinkradColorToken,
        accentPrimary: AinkradColorToken,
        accentSecondary: AinkradColorToken,
        accentTertiary: AinkradColorToken,
        foreground: AinkradColorToken,
        success: AinkradColorToken,
        warning: AinkradColorToken,
        danger: AinkradColorToken,
        black: AinkradColorToken = .hex(0, 0, 0, 1),
        white: AinkradColorToken = .hex(1, 1, 1, 1)
    ) {
        self.background = background
        self.surface = surface
        self.surfaceElevated = surfaceElevated
        self.accentPrimary = accentPrimary
        self.accentSecondary = accentSecondary
        self.accentTertiary = accentTertiary
        self.foreground = foreground
        self.success = success
        self.warning = warning
        self.danger = danger
        self.black = black
        self.white = white
    }

    /// Neon's violet, #A78BFA (the Citadel mockups' `--violet`).
    static let neonViolet = AinkradColorToken.hex(0xA7 / 255.0, 0x8B / 255.0, 0xFA / 255.0, 1.0)
}
