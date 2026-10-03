// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal theme layer — the values the tokens resolve to
import CoreGraphics
import Foundation

public struct AinkradSpacingTokens: Codable, Equatable, Sendable {
    public var xs: Double
    public var sm: Double
    public var md: Double
    public var lg: Double
    public var xl: Double
    public var xxl: Double

    public init(xs: Double = 4, sm: Double = 8, md: Double = 12, lg: Double = 16, xl: Double = 24, xxl: Double = 32) {
        self.xs = xs; self.sm = sm; self.md = md; self.lg = lg; self.xl = xl; self.xxl = xxl
    }
}

public struct AinkradRadiusTokens: Codable, Equatable, Sendable {
    public var sm: Double
    public var md: Double
    public var lg: Double
    public var panel: Double

    public init(sm: Double = 8, md: Double = 12, lg: Double = 14, panel: Double = 14) {
        self.sm = sm; self.md = md; self.lg = lg; self.panel = panel
    }
}

public struct AinkradElevationTokens: Codable, Equatable, Sendable {
    public var level0: AinkradShadowToken
    public var level1: AinkradShadowToken
    public var level2: AinkradShadowToken

    public init(level0: AinkradShadowToken, level1: AinkradShadowToken, level2: AinkradShadowToken) {
        self.level0 = level0; self.level1 = level1; self.level2 = level2
    }
}

public struct AinkradTypeRoleTokens: Codable, Equatable, Sendable {
    public var display: Double
    public var title: Double
    public var headline: Double
    public var body: Double
    public var caption: Double
    public var mono: Double

    public init(display: Double = 28, title: Double = 20, headline: Double = 16, body: Double = 14, caption: Double = 11, mono: Double = 13) {
        self.display = display; self.title = title; self.headline = headline; self.body = body; self.caption = caption; self.mono = mono
    }
}

public struct AinkradTypeTokens: Codable, Equatable, Sendable {
    public var roles: AinkradTypeRoleTokens
    public var monoFamily: String
    public var uiFamily: String?
    public var sizes: AinkradTypeSizeTokens

    public init(roles: AinkradTypeRoleTokens, monoFamily: String = "JetBrains Mono", uiFamily: String? = nil, sizes: AinkradTypeSizeTokens) {
        self.roles = roles; self.monoFamily = monoFamily; self.uiFamily = uiFamily; self.sizes = sizes
    }
}

public struct AinkradTypeSizeTokens: Codable, Equatable, Sendable {
    public var t6: Double; public var t6_5: Double; public var t7: Double; public var t8: Double
    public var t8_5: Double; public var t9: Double; public var t9_5: Double; public var t10: Double
    public var t10_5: Double; public var t11: Double; public var t12: Double; public var t12_5: Double
    public var t13: Double; public var t14: Double; public var t15: Double; public var t16: Double
    public var t17: Double; public var t18: Double; public var t20: Double; public var t21: Double
    public var t24: Double; public var t26: Double; public var t28: Double; public var t30: Double
    public var t34: Double; public var t40: Double

    public init(
        t6: Double = 6, t6_5: Double = 6.5, t7: Double = 7, t8: Double = 8,
        t8_5: Double = 8.5, t9: Double = 9, t9_5: Double = 9.5, t10: Double = 10,
        t10_5: Double = 10.5, t11: Double = 11, t12: Double = 12, t12_5: Double = 12.5,
        t13: Double = 13, t14: Double = 14, t15: Double = 15, t16: Double = 16,
        t17: Double = 17, t18: Double = 18, t20: Double = 20, t21: Double = 21,
        t24: Double = 24, t26: Double = 26, t28: Double = 28, t30: Double = 30,
        t34: Double = 34, t40: Double = 40
    ) {
        self.t6 = t6; self.t6_5 = t6_5; self.t7 = t7; self.t8 = t8
        self.t8_5 = t8_5; self.t9 = t9; self.t9_5 = t9_5; self.t10 = t10
        self.t10_5 = t10_5; self.t11 = t11; self.t12 = t12; self.t12_5 = t12_5
        self.t13 = t13; self.t14 = t14; self.t15 = t15; self.t16 = t16
        self.t17 = t17; self.t18 = t18; self.t20 = t20; self.t21 = t21
        self.t24 = t24; self.t26 = t26; self.t28 = t28; self.t30 = t30
        self.t34 = t34; self.t40 = t40
    }
}

public struct AinkradOpacityTokens: Codable, Equatable, Sendable {
    public var o03: Double; public var o05: Double; public var o06: Double; public var o07: Double
    public var o08: Double; public var o09: Double; public var o10: Double; public var o12: Double
    public var o13: Double; public var o14: Double; public var o15: Double; public var o16: Double
    public var o18: Double; public var o20: Double; public var o22: Double; public var o25: Double
    public var o28: Double; public var o30: Double; public var o32: Double; public var o35: Double
    public var o40: Double; public var o42: Double; public var o45: Double; public var o50: Double
    public var o55: Double; public var o60: Double; public var o62: Double; public var o65: Double
    public var o66: Double; public var o70: Double; public var o72: Double; public var o75: Double
    public var o78: Double; public var o80: Double; public var o82: Double; public var o85: Double
    public var o88: Double; public var o90: Double; public var o92: Double; public var o95: Double
    public var o96: Double; public var o97: Double; public var o98: Double
    public var hitTarget: Double

    public init(
        o03: Double = 0.03, o05: Double = 0.05, o06: Double = 0.06, o07: Double = 0.07,
        o08: Double = 0.08, o09: Double = 0.09, o10: Double = 0.10, o12: Double = 0.12,
        o13: Double = 0.13, o14: Double = 0.14, o15: Double = 0.15, o16: Double = 0.16,
        o18: Double = 0.18, o20: Double = 0.20, o22: Double = 0.22, o25: Double = 0.25,
        o28: Double = 0.28, o30: Double = 0.30, o32: Double = 0.32, o35: Double = 0.35,
        o40: Double = 0.40, o42: Double = 0.42, o45: Double = 0.45, o50: Double = 0.50,
        o55: Double = 0.55, o60: Double = 0.60, o62: Double = 0.62, o65: Double = 0.65,
        o66: Double = 0.66, o70: Double = 0.70, o72: Double = 0.72, o75: Double = 0.75,
        o78: Double = 0.78, o80: Double = 0.80, o82: Double = 0.82, o85: Double = 0.85,
        o88: Double = 0.88, o90: Double = 0.90, o92: Double = 0.92, o95: Double = 0.95,
        o96: Double = 0.96, o97: Double = 0.97, o98: Double = 0.98,
        hitTarget: Double = 0.001
    ) {
        self.o03 = o03; self.o05 = o05; self.o06 = o06; self.o07 = o07
        self.o08 = o08; self.o09 = o09; self.o10 = o10; self.o12 = o12
        self.o13 = o13; self.o14 = o14; self.o15 = o15; self.o16 = o16
        self.o18 = o18; self.o20 = o20; self.o22 = o22; self.o25 = o25
        self.o28 = o28; self.o30 = o30; self.o32 = o32; self.o35 = o35
        self.o40 = o40; self.o42 = o42; self.o45 = o45; self.o50 = o50
        self.o55 = o55; self.o60 = o60; self.o62 = o62; self.o65 = o65
        self.o66 = o66; self.o70 = o70; self.o72 = o72; self.o75 = o75
        self.o78 = o78; self.o80 = o80; self.o82 = o82; self.o85 = o85
        self.o88 = o88; self.o90 = o90; self.o92 = o92; self.o95 = o95
        self.o96 = o96; self.o97 = o97; self.o98 = o98
        self.hitTarget = hitTarget
    }
}

public struct AinkradSizeTokens: Codable, Equatable, Sendable {
    public var s1: Double; public var s1_5: Double; public var s2: Double; public var s2_5: Double
    public var s3: Double; public var s4: Double; public var s5: Double; public var s6: Double
    public var s7: Double; public var s8: Double; public var s9: Double; public var s10: Double
    public var s11: Double; public var s12: Double; public var s14: Double; public var s15: Double
    public var s16: Double; public var s18: Double; public var s20: Double; public var s22: Double
    public var s24: Double; public var s26: Double; public var s28: Double; public var s30: Double
    public var s32: Double; public var s34: Double; public var s36: Double; public var s38: Double
    public var s40: Double; public var s42: Double; public var s44: Double; public var s46: Double
    public var s48: Double; public var s50: Double; public var s52: Double; public var s54: Double
    public var s56: Double; public var s60: Double; public var s62: Double; public var s64: Double
    public var s70: Double; public var s72: Double; public var s80: Double; public var s90: Double
    public var s92: Double; public var s96: Double; public var s104: Double; public var s108: Double
    public var s110: Double; public var s120: Double; public var s124: Double; public var s128: Double
    public var s140: Double; public var s150: Double; public var s160: Double; public var s164: Double
    public var s165: Double; public var s168: Double; public var s180: Double; public var s190: Double
    public var s200: Double; public var s220: Double; public var s232: Double; public var s240: Double
    public var s244: Double; public var s250: Double; public var s260: Double; public var s268: Double
    public var s280: Double; public var s300: Double; public var s320: Double; public var s340: Double
    public var s360: Double; public var s380: Double; public var s400: Double; public var s420: Double
    public var s440: Double; public var s460: Double; public var s480: Double; public var s520: Double
    public var s560: Double; public var s574: Double; public var s620: Double; public var s640: Double
    public var s860: Double

    public init(
        s1: Double = 1, s1_5: Double = 1.5, s2: Double = 2, s2_5: Double = 2.5,
        s3: Double = 3, s4: Double = 4, s5: Double = 5, s6: Double = 6,
        s7: Double = 7, s8: Double = 8, s9: Double = 9, s10: Double = 10,
        s11: Double = 11, s12: Double = 12, s14: Double = 14, s15: Double = 15,
        s16: Double = 16, s18: Double = 18, s20: Double = 20, s22: Double = 22,
        s24: Double = 24, s26: Double = 26, s28: Double = 28, s30: Double = 30,
        s32: Double = 32, s34: Double = 34, s36: Double = 36, s38: Double = 38,
        s40: Double = 40, s42: Double = 42, s44: Double = 44, s46: Double = 46,
        s48: Double = 48, s50: Double = 50, s52: Double = 52, s54: Double = 54,
        s56: Double = 56, s60: Double = 60, s62: Double = 62, s64: Double = 64,
        s70: Double = 70, s72: Double = 72, s80: Double = 80, s90: Double = 90,
        s92: Double = 92, s96: Double = 96, s104: Double = 104, s108: Double = 108,
        s110: Double = 110, s120: Double = 120, s124: Double = 124, s128: Double = 128,
        s140: Double = 140, s150: Double = 150, s160: Double = 160, s164: Double = 164,
        s165: Double = 165, s168: Double = 168, s180: Double = 180, s190: Double = 190,
        s200: Double = 200, s220: Double = 220, s232: Double = 232, s240: Double = 240,
        s244: Double = 244, s250: Double = 250, s260: Double = 260, s268: Double = 268,
        s280: Double = 280, s300: Double = 300, s320: Double = 320, s340: Double = 340,
        s360: Double = 360, s380: Double = 380, s400: Double = 400, s420: Double = 420,
        s440: Double = 440, s460: Double = 460, s480: Double = 480, s520: Double = 520,
        s560: Double = 560, s574: Double = 574, s620: Double = 620, s640: Double = 640,
        s860: Double = 860
    ) {
        self.s1 = s1; self.s1_5 = s1_5; self.s2 = s2; self.s2_5 = s2_5
        self.s3 = s3; self.s4 = s4; self.s5 = s5; self.s6 = s6
        self.s7 = s7; self.s8 = s8; self.s9 = s9; self.s10 = s10
        self.s11 = s11; self.s12 = s12; self.s14 = s14; self.s15 = s15
        self.s16 = s16; self.s18 = s18; self.s20 = s20; self.s22 = s22
        self.s24 = s24; self.s26 = s26; self.s28 = s28; self.s30 = s30
        self.s32 = s32; self.s34 = s34; self.s36 = s36; self.s38 = s38
        self.s40 = s40; self.s42 = s42; self.s44 = s44; self.s46 = s46
        self.s48 = s48; self.s50 = s50; self.s52 = s52; self.s54 = s54
        self.s56 = s56; self.s60 = s60; self.s62 = s62; self.s64 = s64
        self.s70 = s70; self.s72 = s72; self.s80 = s80; self.s90 = s90
        self.s92 = s92; self.s96 = s96; self.s104 = s104; self.s108 = s108
        self.s110 = s110; self.s120 = s120; self.s124 = s124; self.s128 = s128
        self.s140 = s140; self.s150 = s150; self.s160 = s160; self.s164 = s164
        self.s165 = s165; self.s168 = s168; self.s180 = s180; self.s190 = s190
        self.s200 = s200; self.s220 = s220; self.s232 = s232; self.s240 = s240
        self.s244 = s244; self.s250 = s250; self.s260 = s260; self.s268 = s268
        self.s280 = s280; self.s300 = s300; self.s320 = s320; self.s340 = s340
        self.s360 = s360; self.s380 = s380; self.s400 = s400; self.s420 = s420
        self.s440 = s440; self.s460 = s460; self.s480 = s480; self.s520 = s520
        self.s560 = s560; self.s574 = s574; self.s620 = s620; self.s640 = s640
        self.s860 = s860
    }
}

public struct AinkradCutTokens: Codable, Equatable, Sendable {
    public var c2: Double; public var c3: Double; public var c4: Double; public var c5: Double
    public var c6: Double; public var c7: Double; public var c8: Double; public var c20: Double
    public var c22: Double; public var r0_10: Double; public var r0_2: Double; public var r0_22: Double

    public init(
        c2: Double = 2, c3: Double = 3, c4: Double = 4, c5: Double = 5,
        c6: Double = 6, c7: Double = 7, c8: Double = 8, c20: Double = 20,
        c22: Double = 22, r0_10: Double = 0.10, r0_2: Double = 0.20, r0_22: Double = 0.22
    ) {
        self.c2 = c2; self.c3 = c3; self.c4 = c4; self.c5 = c5
        self.c6 = c6; self.c7 = c7; self.c8 = c8; self.c20 = c20
        self.c22 = c22; self.r0_10 = r0_10; self.r0_2 = r0_2; self.r0_22 = r0_22
    }
}

public struct AinkradMotionDurationTokens: Codable, Equatable, Sendable {
    public var d0_08: Double; public var d0_1: Double; public var d0_12: Double; public var d0_14: Double
    public var d0_16: Double; public var d0_18: Double; public var d0_2: Double; public var d0_22: Double
    public var d0_32: Double; public var breathe: Double

    public init(
        d0_08: Double = 0.08, d0_1: Double = 0.1, d0_12: Double = 0.12, d0_14: Double = 0.14,
        d0_16: Double = 0.16, d0_18: Double = 0.18, d0_2: Double = 0.2, d0_22: Double = 0.22,
        d0_32: Double = 0.32, breathe: Double = 3.2
    ) {
        self.d0_08 = d0_08; self.d0_1 = d0_1; self.d0_12 = d0_12; self.d0_14 = d0_14
        self.d0_16 = d0_16; self.d0_18 = d0_18; self.d0_2 = d0_2; self.d0_22 = d0_22
        self.d0_32 = d0_32; self.breathe = breathe
    }
}

public struct AinkradMotionTokens: Codable, Equatable, Sendable {
    public var fast: Double
    public var base: Double
    public var slow: Double
    public var materialize: Double
    public var durations: AinkradMotionDurationTokens
    public var springs: [String: AinkradAnimationToken]
    public var hover: AinkradAnimationToken
    public var present: AinkradAnimationToken
    public var dismiss: AinkradAnimationToken
    public var materializeAnimation: AinkradAnimationToken

    public init(
        fast: Double = 0.15, base: Double = 0.25, slow: Double = 0.40, materialize: Double = 0.55,
        durations: AinkradMotionDurationTokens = AinkradMotionDurationTokens(),
        springs: [String: AinkradAnimationToken] = [:],
        hover: AinkradAnimationToken = AinkradAnimationToken(curve: "easeInOut", durationKey: "fast"),
        present: AinkradAnimationToken = AinkradAnimationToken(curve: "easeOut", durationKey: "base"),
        dismiss: AinkradAnimationToken = AinkradAnimationToken(curve: "easeIn", durationKey: "fast"),
        materializeAnimation: AinkradAnimationToken = AinkradAnimationToken(curve: "easeOut", durationKey: "materialize")
    ) {
        self.fast = fast; self.base = base; self.slow = slow; self.materialize = materialize
        self.durations = durations; self.springs = springs
        self.hover = hover; self.present = present; self.dismiss = dismiss
        self.materializeAnimation = materializeAnimation
    }
}

public struct AinkradMaterialTokens: Codable, Equatable, Sendable {
    public var panel: String
    public var hud: String
    public var panelOpacity: Double
    public var blurEnabled: Bool

    public init(panel: String = "hudWindow", hud: String = "fullScreenUI", panelOpacity: Double = 0.94, blurEnabled: Bool = true) {
        self.panel = panel; self.hud = hud; self.panelOpacity = panelOpacity; self.blurEnabled = blurEnabled
    }
}

public struct AinkradRoleTokens: Codable, Equatable, Sendable {
    public var popover: AinkradPopoverRoleTokens
    public var bubble: AinkradBubbleRoleTokens
    public var materialize: AinkradMaterializeRoleTokens
    public var field: AinkradFieldRoleTokens
    public var trigger: AinkradTriggerRoleTokens
    public var optionRow: AinkradOptionRowRoleTokens
    public var panelSearch: AinkradPanelSearchRoleTokens
    public var selectedFill: AinkradColorToken
    public var accentTick: AinkradAccentTickRoleTokens
    public var scrim: AinkradScrimRoleTokens
    public var thumb: AinkradThumbRoleTokens
    public var track: AinkradTrackRoleTokens

    public init(
        popover: AinkradPopoverRoleTokens, bubble: AinkradBubbleRoleTokens, materialize: AinkradMaterializeRoleTokens,
        field: AinkradFieldRoleTokens, trigger: AinkradTriggerRoleTokens, optionRow: AinkradOptionRowRoleTokens,
        panelSearch: AinkradPanelSearchRoleTokens, selectedFill: AinkradColorToken, accentTick: AinkradAccentTickRoleTokens,
        scrim: AinkradScrimRoleTokens, thumb: AinkradThumbRoleTokens, track: AinkradTrackRoleTokens
    ) {
        self.popover = popover; self.bubble = bubble; self.materialize = materialize; self.field = field
        self.trigger = trigger; self.optionRow = optionRow; self.panelSearch = panelSearch
        self.selectedFill = selectedFill; self.accentTick = accentTick; self.scrim = scrim
        self.thumb = thumb; self.track = track
    }
}

public struct AinkradPopoverRoleTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var shadow: AinkradShadowToken
}

public struct AinkradBubbleRoleTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var shadow: AinkradShadowToken
}

public struct AinkradMaterializeRoleTokens: Codable, Equatable, Sendable {
    public var scale: Double
    public var anchor: String
    public var animation: AinkradAnimationToken
}

public struct AinkradFieldRoleTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
}

public struct AinkradTriggerRoleTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var chevron: AinkradFontToken
    public var chevronColor: AinkradColorToken
}

public struct AinkradOptionRowRoleTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var paddingV: Double
    public var selectedDot: AinkradFontToken
    public var swatchDotSize: Double
}

public struct AinkradPanelSearchRoleTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var paddingV: Double
}

public struct AinkradAccentTickRoleTokens: Codable, Equatable, Sendable {
    public var fill: AinkradColorToken
    public var glow: AinkradGlowToken
}

public struct AinkradScrimRoleTokens: Codable, Equatable, Sendable {
    public var material: String
    public var opacity: Double
    public var color: AinkradColorToken
}

public struct AinkradThumbRoleTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var fill: AinkradColorToken
    public var glow: AinkradGlowToken
    public var dragGlowRadius: Double
    public var dragScale: Double
    public var offset: Double
}

public struct AinkradTrackRoleTokens: Codable, Equatable, Sendable {
    public var height: Double
    public var fill: AinkradColorToken
    public var activeFill: AinkradColorToken
    public var rowHeight: Double
}

public struct AinkradEffectTokens: Codable, Equatable, Sendable {
    public var panelGlow: [AinkradShadowToken]
    public var edgeRing: AinkradEdgeRingEffectTokens
    public var brackets: AinkradBracketsEffectTokens
    public var accentRule: AinkradAccentRuleEffectTokens
    public var scanline: AinkradScanlineEffectTokens
    public var hexGrid: AinkradHexGridEffectTokens
    public var glowBloom: AinkradGlowBloomEffectTokens

    public init(
        panelGlow: [AinkradShadowToken], edgeRing: AinkradEdgeRingEffectTokens, brackets: AinkradBracketsEffectTokens,
        accentRule: AinkradAccentRuleEffectTokens, scanline: AinkradScanlineEffectTokens, hexGrid: AinkradHexGridEffectTokens,
        glowBloom: AinkradGlowBloomEffectTokens
    ) {
        self.panelGlow = panelGlow; self.edgeRing = edgeRing; self.brackets = brackets
        self.accentRule = accentRule; self.scanline = scanline; self.hexGrid = hexGrid; self.glowBloom = glowBloom
    }
}

public struct AinkradEdgeRingEffectTokens: Codable, Equatable, Sendable {
    public var from: AinkradColorToken
    public var to: AinkradColorToken
    public var width: Double
    public var defaultCutKey: String
}

public struct AinkradBracketsEffectTokens: Codable, Equatable, Sendable {
    public var stroke: AinkradColorToken
    public var width: Double
    public var glow: AinkradColorToken
    public var glowRadius: Double
}

public struct AinkradAccentRuleEffectTokens: Codable, Equatable, Sendable {
    public var width: Double
    public var height: Double
    public var labelFont: AinkradFontToken
    public var labelColor: AinkradColorToken
}

public struct AinkradScanlineEffectTokens: Codable, Equatable, Sendable {
    public var staticOpacity: Double
    public var lineSpacing: Double
    public var movingOpacity: Double
    public var period: Double
    public var bandFraction: Double
    public var bandColor: AinkradColorToken
}

public struct AinkradHexGridEffectTokens: Codable, Equatable, Sendable {
    public var radius: Double
    public var stroke: AinkradColorToken
    public var width: Double
    public var opacity: Double
    public var reducedOpacity: Double
}

public struct AinkradGlowBloomEffectTokens: Codable, Equatable, Sendable {
    public var color: AinkradColorToken
    public var reducedOpacityColor: AinkradColorToken
    public var endRadius: Double
}

public struct AinkradChromeTokens: Codable, Equatable, Sendable {
    public var settings: AinkradChromeSettingsTokens
    public var overlay: AinkradChromeOverlayTokens
    public var pane: AinkradChromePaneTokens
    public var hudBarHeight: Double

    public init(
        settings: AinkradChromeSettingsTokens, overlay: AinkradChromeOverlayTokens,
        pane: AinkradChromePaneTokens, hudBarHeight: Double = 30
    ) {
        self.settings = settings; self.overlay = overlay; self.pane = pane; self.hudBarHeight = hudBarHeight
    }
}

public struct AinkradChromeSettingsTokens: Codable, Equatable, Sendable {
    public var panelMinWidth: Double
    public var panelMaxWidth: Double
    public var widthFraction: Double
    public var panelMinHeight: Double
    public var panelMaxHeight: Double
    public var heightFraction: Double
    public var yOffset: Double
    public var sidebarWidth: Double
    public var controlColumnWidth: Double
    public var miniMapBreakpoint: Double
    public var wideBreakpoint: Double
}

public struct AinkradChromeOverlayTokens: Codable, Equatable, Sendable {
    public var cutKey: String
    public var backdropOpacity: Double
    public var backgroundOpacity: Double
    public var edgeFrom: AinkradColorToken
    public var edgeTo: AinkradColorToken
    public var edgeWidth: Double
}

public struct AinkradChromePaneTokens: Codable, Equatable, Sendable {
    public var horizontalInsetKey: String
    public var topInsetKey: String
    public var bottomInsetKey: String
    public var tabStripHeight: Double
    public var tabStripSpacingKey: String
}
