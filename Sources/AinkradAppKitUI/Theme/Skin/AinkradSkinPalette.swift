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
}
