// design-lint: allow-file hex-color,raw-color,radius-literal,font-size,padding-literal,spacing-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — standard skin foundation values
import Foundation

extension AinkradSkinPalette {
    public static let neonBlue = AinkradSkinPalette(
        background: .hex(0x0A / 255.0, 0x0E / 255.0, 0x17 / 255.0, 1.0),
        surface: .hex(0x11 / 255.0, 0x18 / 255.0, 0x27 / 255.0, 1.0),
        surfaceElevated: .hex(0x1A / 255.0, 0x22 / 255.0, 0x33 / 255.0, 1.0),
        accentPrimary: .hex(0x25 / 255.0, 0x63 / 255.0, 0xEB / 255.0, 1.0),
        accentSecondary: .hex(0x22 / 255.0, 0xD3 / 255.0, 0xEE / 255.0, 1.0),
        accentTertiary: .hex(0x10 / 255.0, 0xB9 / 255.0, 0x81 / 255.0, 1.0),
        foreground: .hex(0xE2 / 255.0, 0xE8 / 255.0, 0xF0 / 255.0, 1.0),
        success: .hex(0x3F / 255.0, 0xB9 / 255.0, 0x50 / 255.0, 1.0),
        warning: .hex(0xE3 / 255.0, 0xB3 / 255.0, 0x41 / 255.0, 1.0),
        danger: .hex(0xF8 / 255.0, 0x51 / 255.0, 0x49 / 255.0, 1.0),
        black: .hex(0.0, 0.0, 0.0, 1.0),
        white: .hex(1.0, 1.0, 1.0, 1.0)
    )
}

extension AinkradRoleTokens {
    public static let standard = AinkradRoleTokens(
        popover: AinkradPopoverRoleTokens(
            shape: AinkradShapeToken(style: "chamfer", cut: 8),
            fill: .palette("surfaceElevated", 0.97),
            stroke: AinkradStrokeToken(
                color: AinkradStateColor(rest: .palette("accentSecondary", 0.55)), width: AinkradStateDouble(rest: 1.25)
            ),
            shadow: AinkradShadowToken(color: .palette("accentSecondary", 0.35), radius: 10, x: 0, y: 4)
        ),
        bubble: AinkradBubbleRoleTokens(
            shape: AinkradShapeToken(style: "chamfer", cut: 6),
            fill: .palette("surfaceElevated", 0.97),
            stroke: AinkradStrokeToken(
                color: AinkradStateColor(rest: .palette("accentSecondary", 0.55)), width: AinkradStateDouble(rest: 1.25)
            ),
            shadow: AinkradShadowToken(color: .palette("accentSecondary", 0.35), radius: 8, x: 0, y: 3)
        ),
        materialize: AinkradMaterializeRoleTokens(
            scale: 0.96,
            anchor: "top",
            animation: AinkradAnimationToken(curve: "easeOut", durationKey: "materialize")
        ),
        field: AinkradFieldRoleTokens(
            shape: AinkradShapeToken(style: "chamfer", cut: 6),
            fill: .palette("surfaceElevated", 0.5),
            stroke: AinkradStrokeToken(
                color: AinkradStateColor(
                    rest: .palette("accentPrimary", 0.25), focused: .palette("accentPrimary", 0.9)),
                width: AinkradStateDouble(rest: 1.25, focused: 1.5)),
            glow: AinkradGlowToken(
                color: AinkradStateColor(
                    rest: .palette("accentSecondary", 0.0), focused: .palette("accentSecondary", 0.45)),
                radius: AinkradStateDouble(rest: 0, focused: 6))
        ),
        trigger: AinkradTriggerRoleTokens(
            shape: AinkradShapeToken(style: "chamfer", cut: 8),
            fill: .palette("surfaceElevated", 0.5),
            stroke: AinkradStrokeToken(
                color: AinkradStateColor(
                    rest: .palette("accentPrimary", 0.3), selected: .palette("accentPrimary", 0.75)),
                width: AinkradStateDouble(rest: 1.0, selected: 1.25)),
            glow: AinkradGlowToken(
                color: AinkradStateColor(
                    rest: .palette("accentPrimary", 0.0), selected: .palette("accentPrimary", 0.4)),
                radius: AinkradStateDouble(rest: 0, selected: 5)),
            chevron: AinkradFontToken(size: 10, weight: "semibold", scaled: false),
            chevronColor: .palette("accentSecondary", 0.85)
        ),
        optionRow: AinkradOptionRowRoleTokens(
            shape: AinkradShapeToken(style: "chamfer", cut: 4),
            fill: AinkradStateColor(
                rest: .clear, hover: .palette("accentSecondary", 0.18), selected: .palette("accentSecondary", 0.18)),
            paddingV: 6,
            selectedDot: AinkradFontToken(size: 6, scaled: false),
            swatchDotSize: 9
        ),
        panelSearch: AinkradPanelSearchRoleTokens(
            shape: AinkradShapeToken(style: "chamfer", cut: 4),
            fill: .palette("surface", 0.7),
            stroke: AinkradStrokeToken(
                color: AinkradStateColor(rest: .palette("accentPrimary", 0.3)), width: AinkradStateDouble(rest: 1.0)),
            paddingV: 6
        ),
        selectedFill: .palette("accentPrimary", 0.16),
        accentTick: AinkradAccentTickRoleTokens(
            fill: .palette("accentSecondary", 1.0),
            glow: AinkradGlowToken(
                color: AinkradStateColor(rest: .palette("accentSecondary", 0.6)), radius: AinkradStateDouble(rest: 2.0))
        ),
        scrim: AinkradScrimRoleTokens(
            material: "panel",
            opacity: 0.6,
            color: .palette("black", 0.45)
        ),
        thumb: AinkradThumbRoleTokens(
            size: 14,
            fill: .palette("accentSecondary", 1.0),
            glow: AinkradGlowToken(
                color: AinkradStateColor(
                    rest: .palette("accentSecondary", 0.55), pressed: .palette("accentSecondary", 0.9)),
                radius: AinkradStateDouble(rest: 4.0, pressed: 8.0)),
            dragGlowRadius: 8.0,
            dragScale: 1.15,
            offset: 7
        ),
        track: AinkradTrackRoleTokens(
            height: 4,
            fill: .palette("surfaceElevated", 0.6),
            activeFill: .palette("accentSecondary", 0.85),
            rowHeight: 20
        )
    )
}

extension AinkradEffectTokens {
    public static let standard = AinkradEffectTokens(
        panelGlow: [
            AinkradShadowToken(color: .palette("accentPrimary", 0.35), radius: 42, x: 0, y: 0),
            AinkradShadowToken(color: .palette("black", 0.5), radius: 24, x: 0, y: 10),
        ],
        edgeRing: AinkradEdgeRingEffectTokens(
            from: .palette("accentSecondary", 0.45),
            to: .palette("accentPrimary", 0.18),
            width: 1,
            defaultCutKey: "panel"
        ),
        brackets: AinkradBracketsEffectTokens(
            stroke: .palette("accentSecondary", 1.0),
            width: 1.25,
            glow: .palette("accentSecondary", 0.55),
            glowRadius: 2.5
        ),
        accentRule: AinkradAccentRuleEffectTokens(
            width: 18,
            height: 2,
            labelFont: AinkradFontToken(role: "caption", tracking: 1.5),
            labelColor: .palette("foreground", 0.7)
        ),
        scanline: AinkradScanlineEffectTokens(
            staticOpacity: 0.05,
            lineSpacing: 4,
            movingOpacity: 0.08,
            period: 3.5,
            bandFraction: 0.12,
            bandColor: .palette("white", 0.6)
        ),
        hexGrid: AinkradHexGridEffectTokens(
            radius: 14,
            stroke: .palette("white", 1.0),
            width: 0.5,
            opacity: 0.05,
            reducedOpacity: 0.04
        ),
        glowBloom: AinkradGlowBloomEffectTokens(
            color: .palette("accentPrimary", 0.20),
            reducedOpacityColor: .palette("accentPrimary", 0.16),
            endRadius: 140
        )
    )
}

extension AinkradChromeTokens {
    public static let standard = AinkradChromeTokens(
        settings: AinkradSkin.standardSettingsMetrics,
        overlay: AinkradChromeOverlayTokens(
            cutKey: "panel", backdropOpacity: 0.42, backgroundOpacity: 0.94,
            edgeFrom: .palette("accentSecondary", 0.55), edgeTo: .palette("accentPrimary", 0.28), edgeWidth: 1
        ),
        pane: AinkradChromePaneTokens(
            horizontalInsetKey: "sm", topInsetKey: "xs", bottomInsetKey: "sm", tabStripHeight: 30,
            tabStripSpacingKey: "xs"
        ),
        hudBarHeight: 30
    )
}
