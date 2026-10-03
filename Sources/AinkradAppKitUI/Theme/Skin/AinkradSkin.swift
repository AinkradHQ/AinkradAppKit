// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — top-level skin model definition & standard skin
import Foundation

public struct AinkradSkin: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var id: String
    public var name: String
    public var palette: AinkradSkinPalette
    public var shape: AinkradShapeToken
    public var spacing: AinkradSpacingTokens
    public var radius: AinkradRadiusTokens
    public var elevation: AinkradElevationTokens
    public var type: AinkradTypeTokens
    public var opacity: AinkradOpacityTokens
    public var size: AinkradSizeTokens
    public var cut: AinkradCutTokens
    public var text: AinkradTextTokens
    public var syntax: AinkradSyntaxTokens
    public var terminal: AinkradTerminalTokens
    public var motion: AinkradMotionTokens
    public var material: AinkradMaterialTokens
    public var roles: AinkradRoleTokens
    public var effects: AinkradEffectTokens
    public var chrome: AinkradChromeTokens

    var components: AinkradComponentTokens

    public init(
        schemaVersion: Int = currentSchemaVersion,
        id: String,
        name: String,
        palette: AinkradSkinPalette,
        shape: AinkradShapeToken,
        spacing: AinkradSpacingTokens,
        radius: AinkradRadiusTokens,
        elevation: AinkradElevationTokens,
        type: AinkradTypeTokens,
        opacity: AinkradOpacityTokens,
        size: AinkradSizeTokens,
        cut: AinkradCutTokens,
        text: AinkradTextTokens,
        syntax: AinkradSyntaxTokens,
        terminal: AinkradTerminalTokens,
        motion: AinkradMotionTokens,
        material: AinkradMaterialTokens,
        roles: AinkradRoleTokens,
        effects: AinkradEffectTokens,
        chrome: AinkradChromeTokens,
        components: AinkradComponentTokens
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.name = name
        self.palette = palette
        self.shape = shape
        self.spacing = spacing
        self.radius = radius
        self.elevation = elevation
        self.type = type
        self.opacity = opacity
        self.size = size
        self.cut = cut
        self.text = text
        self.syntax = syntax
        self.terminal = terminal
        self.motion = motion
        self.material = material
        self.roles = roles
        self.effects = effects
        self.chrome = chrome
        self.components = components
    }

    public static let standardSpacing = AinkradSpacingTokens()
    public static let standardRadius = AinkradRadiusTokens()
    public static let standardElevation = AinkradElevationTokens(
        level0: AinkradShadowToken(color: .clear, radius: 0, x: 0, y: 0),
        level1: AinkradShadowToken(color: .palette("black", 0.22), radius: 8, x: 0, y: 2),
        level2: AinkradShadowToken(color: .palette("black", 0.30), radius: 20, x: 0, y: 8)
    )
    public static let standardTypeRoles = AinkradTypeRoleTokens()
    public static let standardMotion = AinkradMotionTokens(
        fast: 0.15, base: 0.25, slow: 0.40, materialize: 0.55,
        durations: AinkradMotionDurationTokens(),
        springs: [
            "sp30_70": AinkradAnimationToken(curve: "spring", response: 0.30, damping: 0.70),
            "sp30_80": AinkradAnimationToken(curve: "spring", response: 0.30, damping: 0.80),
            "sp30_86": AinkradAnimationToken(curve: "spring", response: 0.30, damping: 0.86),
            "sp32_74": AinkradAnimationToken(curve: "spring", response: 0.32, damping: 0.74),
            "sp32_84": AinkradAnimationToken(curve: "spring", response: 0.32, damping: 0.84),
            "sp32_85": AinkradAnimationToken(curve: "spring", response: 0.32, damping: 0.85),
            "sp34_80": AinkradAnimationToken(curve: "spring", response: 0.34, damping: 0.80),
            "sp34_82": AinkradAnimationToken(curve: "spring", response: 0.34, damping: 0.82),
            "sp42_82": AinkradAnimationToken(curve: "spring", response: 0.42, damping: 0.82),
            "sp42_88": AinkradAnimationToken(curve: "spring", response: 0.42, damping: 0.88),
            "snappy22": AinkradAnimationToken(curve: "snappy", duration: 0.22),
            "snappy26": AinkradAnimationToken(curve: "snappy", duration: 0.26),
            "snappy32": AinkradAnimationToken(curve: "snappy", duration: 0.32)
        ]
    )
    public static let standardSettingsMetrics = AinkradChromeSettingsTokens(
        panelMinWidth: 1100, panelMaxWidth: 1440, widthFraction: 0.82,
        panelMinHeight: 700, panelMaxHeight: 900, heightFraction: 0.85, yOffset: -30,
        sidebarWidth: 240, controlColumnWidth: 220, miniMapBreakpoint: 640, wideBreakpoint: 900
    )

    public static var standard: AinkradSkin {
        AinkradSkin(
            schemaVersion: currentSchemaVersion,
            id: "neonBlue",
            name: "Neon Blue",
            palette: .neonBlue,
            shape: AinkradShapeToken(style: "chamfer", corners: "diagonal"),
            spacing: standardSpacing,
            radius: standardRadius,
            elevation: standardElevation,
            type: AinkradTypeTokens(
                roles: standardTypeRoles,
                monoFamily: "JetBrains Mono",
                uiFamily: nil,
                sizes: AinkradTypeSizeTokens()
            ),
            opacity: AinkradOpacityTokens(),
            size: AinkradSizeTokens(),
            cut: AinkradCutTokens(),
            text: AinkradTextTokens(),
            syntax: AinkradSyntaxTokens(),
            terminal: AinkradTerminalTokens(
                background: .hex(0x0A / 255.0, 0x0E / 255.0, 0x17 / 255.0, 1.0),
                foreground: .hex(0xE2 / 255.0, 0xE8 / 255.0, 0xF0 / 255.0, 1.0),
                cursor: .hex(0x22 / 255.0, 0xD3 / 255.0, 0xEE / 255.0, 1.0),
                selection: .hex(0x3B / 255.0, 0x42 / 255.0, 0x52 / 255.0, 1.0),
                ansi: [
                    .hex(0x1A / 255.0, 0x1D / 255.0, 0x24 / 255.0, 1.0),
                    .hex(0xE0 / 255.0, 0x6C / 255.0, 0x75 / 255.0, 1.0),
                    .hex(0x98 / 255.0, 0xC3 / 255.0, 0x79 / 255.0, 1.0),
                    .hex(0xE5 / 255.0, 0xC0 / 255.0, 0x7B / 255.0, 1.0),
                    .hex(0x61 / 255.0, 0xAF / 255.0, 0xEF / 255.0, 1.0),
                    .hex(0xC6 / 255.0, 0x78 / 255.0, 0xDD / 255.0, 1.0),
                    .hex(0x56 / 255.0, 0xB6 / 255.0, 0xC2 / 255.0, 1.0),
                    .hex(0xAB / 255.0, 0xB2 / 255.0, 0xBF / 255.0, 1.0),
                    .hex(0x5C / 255.0, 0x63 / 255.0, 0x70 / 255.0, 1.0),
                    .hex(0xE0 / 255.0, 0x6C / 255.0, 0x75 / 255.0, 1.0),
                    .hex(0x98 / 255.0, 0xC3 / 255.0, 0x79 / 255.0, 1.0),
                    .hex(0xE5 / 255.0, 0xC0 / 255.0, 0x7B / 255.0, 1.0),
                    .hex(0x61 / 255.0, 0xAF / 255.0, 0xEF / 255.0, 1.0),
                    .hex(0xC6 / 255.0, 0x78 / 255.0, 0xDD / 255.0, 1.0),
                    .hex(0x56 / 255.0, 0xB6 / 255.0, 0xC2 / 255.0, 1.0),
                    .hex(1.0, 1.0, 1.0, 1.0)
                ]
            ),
            motion: standardMotion,
            material: AinkradMaterialTokens(),
            roles: .standard,
            effects: .standard,
            chrome: .standard,
            components: .standard
        )
    }
}
