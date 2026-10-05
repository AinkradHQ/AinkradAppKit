// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — component token models
import Foundation

public struct SegmentedPickerTokens: Codable, Equatable, Sendable {
    public var labelFont: AinkradFontToken
    public var labelSelectedFont: AinkradFontToken
    public var fg: AinkradStateColor
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
}

public struct MultiSelectCheckTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var shape: AinkradShapeToken
    public var stroke: AinkradStrokeToken
    public var glyphFont: AinkradFontToken
}

public struct GroupedSelectRowTokens: Codable, Equatable, Sendable {
    public var headerFont: AinkradFontToken
    public var headerColor: AinkradColorToken
    public var iconFont: AinkradFontToken
    public var iconColor: AinkradStateColor
    public var titleFont: AinkradFontToken
    public var titleColor: AinkradStateColor
    public var detailFont: AinkradFontToken
    public var detailColor: AinkradStateColor
    public var emptyFont: AinkradFontToken
    public var emptyColor: AinkradColorToken
}

public struct ContextMenuTokens: Codable, Equatable, Sendable {
    public var glyphFont: AinkradFontToken
    public var bodyFont: AinkradFontToken
    public var rowShape: AinkradShapeToken
    public var rowHoverFill: AinkradColorToken
}

public struct TooltipPopoverTokens: Codable, Equatable, Sendable {
    public var textFont: AinkradFontToken
    public var textColor: AinkradColorToken
    public var showDelay: Double
    public var tooltipMaxHeight: Double
    public var popoverMaxHeight: Double
}

public struct CommandMenuRowTokens: Codable, Equatable, Sendable {
    public var glyphFont: AinkradFontToken
    public var titleFont: AinkradFontToken
    public var detailFont: AinkradFontToken
    public var detailColor: AinkradColorToken
    public var valueFont: AinkradFontToken
    public var valueColor: AinkradColorToken
    public var fg: AinkradStateColor
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var hoverScale: Double
}

public struct NavListRowTokens: Codable, Equatable, Sendable {
    public var glyphFont: AinkradFontToken
    public var bodyFont: AinkradFontToken
    public var bodySelectedFont: AinkradFontToken
    public var fg: AinkradStateColor
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
}

public struct TabsTokens: Codable, Equatable, Sendable {
    public var labelFont: AinkradFontToken
    public var fg: AinkradStateColor
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var hoverScale: Double
}

public struct BreadcrumbTokens: Codable, Equatable, Sendable {
    public var chevronFont: AinkradFontToken
    public var chevronColor: AinkradColorToken
    public var font: AinkradFontToken
    public var activeFont: AinkradFontToken
    public var activeColor: AinkradColorToken
    public var itemColor: AinkradColorToken
}

public struct PaginationTokens: Codable, Equatable, Sendable {
    public var currentDotSize: Double
    public var dotSize: Double
    public var currentFill: AinkradColorToken
    public var dotFill: AinkradColorToken
    public var currentGlow: AinkradGlowToken
    public var disabledOpacity: Double
}

public struct ListRowTokens: Codable, Equatable, Sendable {
    public var titleFont: AinkradFontToken
    public var subtitleFont: AinkradFontToken
    public var subtitleColor: AinkradColorToken
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var edgeWidth: AinkradStateDouble
    public var edgeGlow: AinkradGlowToken
    public var gap: Double
}

public struct StatRowTokens: Codable, Equatable, Sendable {
    public var labelFont: AinkradFontToken
    public var labelColor: AinkradColorToken
    public var valueFont: AinkradFontToken
}

public struct IconGlyphTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var glyphRatio: Double
    public var glyphColor: AinkradColorToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
}

public struct DataTableTokens: Codable, Equatable, Sendable {
    public var headerShape: AinkradShapeToken
    public var headerFill: AinkradColorToken
    public var headerFont: AinkradFontToken
    public var headerColor: AinkradColorToken
    public var sortGlyphFont: AinkradFontToken
    public var headerCellGap: Double
    public var cellFont: AinkradFontToken
    public var cellColor: AinkradColorToken
    public var rowShape: AinkradShapeToken
    public var rowFill: AinkradStateColor
    public var rowGap: Double
    public var edgeWidth: Double
    public var edgeGlow: AinkradGlowToken
}

public struct DisclosureGroupTokens: Codable, Equatable, Sendable {
    public var chevronFont: AinkradFontToken
    public var chevronColor: AinkradColorToken
    public var titleFont: AinkradFontToken
    public var titleColor: AinkradColorToken
    public var headerShape: AinkradShapeToken
    public var headerFill: AinkradStateColor
    public var hoverAnimation: AinkradAnimationToken
    public var expandAnimation: AinkradAnimationToken
}

public struct EmptyStateTokens: Codable, Equatable, Sendable {
    public var glyphFont: AinkradFontToken
    public var glyphColor: AinkradColorToken
    public var titleFont: AinkradFontToken
    public var messageFont: AinkradFontToken
    public var messageColor: AinkradColorToken
}

public struct LoadingStateTokens: Codable, Equatable, Sendable {
    public var spinnerSize: Double
    public var captionFont: AinkradFontToken
    public var captionColor: AinkradColorToken
}

public struct ErrorStateTokens: Codable, Equatable, Sendable {
    public var glyphFont: AinkradFontToken
    public var glyphColor: AinkradColorToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var messageFont: AinkradFontToken
    public var messageColor: AinkradColorToken
}

public struct SectionHeaderTokens: Codable, Equatable, Sendable {
    public var tickWidth: Double
    public var tickHeight: Double
    public var titleFont: AinkradFontToken
    public var titleColor: AinkradColorToken
    public var subtitleFont: AinkradFontToken
    public var subtitleColor: AinkradColorToken
}

public struct StatusBarTokens: Codable, Equatable, Sendable {
    public var segments: Int
    public var height: Double
    public var gap: Double
    public var shape: AinkradShapeToken
    public var gradientFrom: AinkradColorToken
    public var emptyFill: AinkradColorToken
    public var glow: AinkradGlowToken
}

public struct SpinnerTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var trackColor: AinkradColorToken
    public var lineMinWidth: Double
    public var lineWidthRatio: Double
    public var arcTrim: Double
    public var defaultColor: AinkradColorToken
    public var glow: AinkradGlowToken
    public var period: Double
    public var pulsePeriod: Double
    public var pulseFloor: Double
}

public struct MeterTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var trackColor: AinkradColorToken
    public var lineMinWidth: Double
    public var lineWidthRatio: Double
    public var arcGlow: AinkradGlowToken
    public var valueFont: AinkradFontToken
    public var labelFont: AinkradFontToken
    public var labelColor: AinkradColorToken
    public var gap: Double
}

public struct StackedStatusBarTokens: Codable, Equatable, Sendable {
    public var height: Double
    public var gap: Double
    public var minRun: Double
    public var trackColor: AinkradColorToken
}

public struct ToastTokens: Codable, Equatable, Sendable {
    public var iconFont: AinkradFontToken
    public var bodyFont: AinkradFontToken
    public var bodyColor: AinkradColorToken
    public var closeFont: AinkradFontToken
    public var closeColor: AinkradColorToken
    public var minWidth: Double
    public var maxWidth: Double
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
}

public struct BannerTokens: Codable, Equatable, Sendable {
    public var iconFont: AinkradFontToken
    public var bodyFont: AinkradFontToken
    public var bodyColor: AinkradColorToken
    public var closeFont: AinkradFontToken
    public var closeColor: AinkradColorToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
}

public struct LogViewTokens: Codable, Equatable, Sendable {
    public var ansiSlots: [AinkradColorToken]
    public var insetX: Double
    public var insetY: Double
    public var font: AinkradFontToken
    public var sourcePrefixOpacity: Double
    public var dimOpacity: Double
    public var stderrSlot: Int
}
