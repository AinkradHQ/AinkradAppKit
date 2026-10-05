// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — component token models
import Foundation

public struct SignalFeedListTokens: Codable, Equatable, Sendable {
    public var dayHeaderFont: AinkradFontToken
    public var dayHeaderColor: AinkradColorToken
    public var fill: AinkradColorToken
    public var emptyGlyphFont: AinkradFontToken
    public var emptyGlyphColor: AinkradColorToken
    public var emptyTextFont: AinkradFontToken
    public var emptyTextColor: AinkradColorToken
}

public struct SignalFeedRowTokens: Codable, Equatable, Sendable {
    public var appGlyphFont: AinkradFontToken
    public var appGlyphSize: Double
    public var hoverScale: Double
    public var hoverOffsetY: Double
    public var titleFont: AinkradFontToken
    public var titleUnreadFont: AinkradFontToken
    public var repeatGlyphFont: AinkradFontToken
    public var timeFont: AinkradFontToken
    public var timeColor: AinkradColorToken
    public var bodyFont: AinkradFontToken
    public var bodyColor: AinkradColorToken
    public var metaFont: AinkradFontToken
    public var metaColor: AinkradColorToken
    public var chevronFont: AinkradFontToken
    public var chevronColor: AinkradStateColor
    public var chevronSize: Double
    public var chevronTopPadding: Double
    public var unreadDotSize: Double
    public var unreadDotTopPadding: Double
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var focusRingColor: AinkradColorToken
    public var focusRingWidth: Double
    public var infoSeverityColor: AinkradColorToken
}

public struct SignalFeedRowActionTokens: Codable, Equatable, Sendable {
    public var font: AinkradFontToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
}

public struct SignalSourceRailTokens: Codable, Equatable, Sendable {
    public var width: Double
    public var dotSize: Double
    public var gap: Double
    public var nameFont: AinkradFontToken
    public var nameSelectedFont: AinkradFontToken
    public var nameOpacity: AinkradStateDouble
    public var countFont: AinkradFontToken
    public var countColor: AinkradColorToken
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var edgeCapsuleColor: AinkradColorToken
    public var edgeCapsuleWidth: Double
    public var edgePaddingV: Double
}

public struct SignalToastTokens: Codable, Equatable, Sendable {
    public var width: Double
    public var stackGap: Double
    public var stackPadding: Double
    public var listSpring: AinkradAnimationToken
    public var removalOpacity: Double
    public var removalScale: Double
    public var expandSpring: AinkradAnimationToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var failureStrokeColor: AinkradColorToken
    public var severityEdgeWidth: Double
    public var severityEdgePadding: Double
    public var severityEdgeGlow: AinkradGlowToken
    public var dwellBarColor: AinkradColorToken
    public var dwellBarHeight: Double
    public var appTileSize: Double
    public var fallbackGlyphFont: AinkradFontToken
    public var fallbackGlyphSize: Double
    public var titleFont: AinkradFontToken
    public var titleGlyphFont: AinkradFontToken
    public var repeatFont: AinkradFontToken
    public var timeFont: AinkradFontToken
    public var timeColor: AinkradColorToken
    public var bodyFont: AinkradFontToken
    public var bodyColor: AinkradColorToken
    public var contentGap: Double
    public var chevronCloseFont: AinkradFontToken
    public var chevronCloseColor: AinkradStateColor
    public var chevronCloseSize: Double
    public var actionFont: AinkradFontToken
    public var actionWidth: Double
    public var actionHeight: Double
    public var actionShape: AinkradShapeToken
    public var actionFill: AinkradColorToken
    public var actionStroke: AinkradStrokeToken
    public var moreFont: AinkradFontToken
    public var moreWidth: Double
    public var moreHeight: Double
    public var moreFill: AinkradColorToken
    public var moreColor: AinkradColorToken
}

public struct SettingsGroupTokens: Codable, Equatable, Sendable {
    public var searchDimmedOpacity: Double
    public var highlightStroke: AinkradStrokeToken
    public var highlightShape: AinkradShapeToken
    public var captionFont: AinkradFontToken
    public var captionColor: AinkradColorToken
}

public struct SettingsPageTokens: Codable, Equatable, Sendable {
    public var listGap: Double
    public var padding: Double
    public var miniMapWidth: Double
    public var miniMapGutter: Double
    public var miniMapPaddingTopTrailing: Double
    public var tabInsertAnimation: AinkradAnimationToken
    public var scrollAnimation: AinkradAnimationToken
    public var hitsGlyphFont: AinkradFontToken
    public var hitsCaptionFont: AinkradFontToken
    public var hitsColor: AinkradColorToken
    public var miniMapTitleFont: AinkradFontToken
    public var miniMapTitleColor: AinkradColorToken
    public var itemsFont: AinkradFontToken
    public var itemsColor: AinkradColorToken
    public var hitsGap: Double
    public var itemsGap: Double
}

public struct SettingsRowTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var hoverAnimation: AinkradAnimationToken
    public var resetGlyphFont: AinkradFontToken
    public var resetGlyphColor: AinkradColorToken
    public var valueFont: AinkradFontToken
    public var valueColor: AinkradColorToken
}

public struct LabelTokens: Codable, Equatable, Sendable {
    public var glyphFont: AinkradFontToken
}

public struct RailItemTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var glyphFont: AinkradFontToken
    public var glyphSelectedFont: AinkradFontToken
    public var glyphColor: AinkradStateColor
    public var glyphDimmedColor: AinkradColorToken
    public var glyphGlow: AinkradGlowToken
    public var hoverScale: Double
    public var badgeScale: Double
    public var badgeOffsetX: Double
    public var badgeOffsetY: Double
    public var badgeOpacity: AinkradStateDouble
    public var cornerFont: AinkradFontToken
    public var cornerColor: AinkradColorToken
    public var cornerFill: AinkradColorToken
    public var cornerPadding: Double
    public var cornerOffset: Double
    public var edgeColor: AinkradColorToken
    public var edgeWidth: Double
    public var edgeHeight: AinkradStateDouble
    public var edgeGlow: AinkradGlowToken
}
