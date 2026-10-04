// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — the values the tokens resolve to
import CoreGraphics
import Foundation

public struct AinkradCutTokens: Codable, Equatable, Sendable {
    public var c2: Double
    public var c3: Double
    public var c4: Double
    public var c5: Double
    public var c6: Double
    public var c7: Double
    public var c8: Double
    public var c20: Double
    public var c22: Double
    public var r0_10: Double
    public var r0_2: Double
    public var r0_22: Double

    public init(
        c2: Double = 2, c3: Double = 3, c4: Double = 4, c5: Double = 5,
        c6: Double = 6, c7: Double = 7, c8: Double = 8, c20: Double = 20,
        c22: Double = 22, r0_10: Double = 0.10, r0_2: Double = 0.20, r0_22: Double = 0.22
    ) {
        self.c2 = c2
        self.c3 = c3
        self.c4 = c4
        self.c5 = c5
        self.c6 = c6
        self.c7 = c7
        self.c8 = c8
        self.c20 = c20
        self.c22 = c22
        self.r0_10 = r0_10
        self.r0_2 = r0_2
        self.r0_22 = r0_22
    }
}

public struct AinkradMotionDurationTokens: Codable, Equatable, Sendable {
    public var d0_08: Double
    public var d0_1: Double
    public var d0_12: Double
    public var d0_14: Double
    public var d0_16: Double
    public var d0_18: Double
    public var d0_2: Double
    public var d0_22: Double
    public var d0_32: Double
    public var breathe: Double

    public init(
        d0_08: Double = 0.08, d0_1: Double = 0.1, d0_12: Double = 0.12, d0_14: Double = 0.14,
        d0_16: Double = 0.16, d0_18: Double = 0.18, d0_2: Double = 0.2, d0_22: Double = 0.22,
        d0_32: Double = 0.32, breathe: Double = 3.2
    ) {
        self.d0_08 = d0_08
        self.d0_1 = d0_1
        self.d0_12 = d0_12
        self.d0_14 = d0_14
        self.d0_16 = d0_16
        self.d0_18 = d0_18
        self.d0_2 = d0_2
        self.d0_22 = d0_22
        self.d0_32 = d0_32
        self.breathe = breathe
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
        materializeAnimation: AinkradAnimationToken = AinkradAnimationToken(
            curve: "easeOut", durationKey: "materialize")
    ) {
        self.fast = fast
        self.base = base
        self.slow = slow
        self.materialize = materialize
        self.durations = durations
        self.springs = springs
        self.hover = hover
        self.present = present
        self.dismiss = dismiss
        self.materializeAnimation = materializeAnimation
    }
}

public struct AinkradMaterialTokens: Codable, Equatable, Sendable {
    public var panel: String
    public var hud: String
    public var panelOpacity: Double
    public var blurEnabled: Bool

    public init(
        panel: String = "hudWindow", hud: String = "fullScreenUI", panelOpacity: Double = 0.94, blurEnabled: Bool = true
    ) {
        self.panel = panel
        self.hud = hud
        self.panelOpacity = panelOpacity
        self.blurEnabled = blurEnabled
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
        panelSearch: AinkradPanelSearchRoleTokens, selectedFill: AinkradColorToken,
        accentTick: AinkradAccentTickRoleTokens,
        scrim: AinkradScrimRoleTokens, thumb: AinkradThumbRoleTokens, track: AinkradTrackRoleTokens
    ) {
        self.popover = popover
        self.bubble = bubble
        self.materialize = materialize
        self.field = field
        self.trigger = trigger
        self.optionRow = optionRow
        self.panelSearch = panelSearch
        self.selectedFill = selectedFill
        self.accentTick = accentTick
        self.scrim = scrim
        self.thumb = thumb
        self.track = track
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
        accentRule: AinkradAccentRuleEffectTokens, scanline: AinkradScanlineEffectTokens,
        hexGrid: AinkradHexGridEffectTokens,
        glowBloom: AinkradGlowBloomEffectTokens
    ) {
        self.panelGlow = panelGlow
        self.edgeRing = edgeRing
        self.brackets = brackets
        self.accentRule = accentRule
        self.scanline = scanline
        self.hexGrid = hexGrid
        self.glowBloom = glowBloom
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
        self.settings = settings
        self.overlay = overlay
        self.pane = pane
        self.hudBarHeight = hudBarHeight
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
