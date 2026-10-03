// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — component token models
import Foundation

public struct PanelTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
}

public struct CardTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var padding: Double
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var hoverScale: Double
}

public struct SectionFrameTokens: Codable, Equatable, Sendable {
    public var tickWidth: Double
    public var tickHeight: Double
    public var titleFont: AinkradFontToken
    public var titleColor: AinkradColorToken
    public var bodyShape: AinkradShapeToken
    public var bodyFill: AinkradColorToken
    public var bodyStroke: AinkradStrokeToken
}

public struct SettingsPanelTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var padding: Double
    public var titleFont: AinkradFontToken
    public var titleColor: AinkradColorToken
    public var hintFont: AinkradFontToken
    public var hintColor: AinkradColorToken
    public var hintReadingWidth: Double
}

public struct CaptionedRowTokens: Codable, Equatable, Sendable {
    public var captionColumnWidth: Double
    public var captionFont: AinkradFontToken
    public var captionColor: AinkradColorToken
}

public struct CodeBlockTokens: Codable, Equatable, Sendable {
    public var headerFont: AinkradFontToken
    public var headerColor: AinkradColorToken
    public var codeFont: AinkradFontToken
    public var codeColor: AinkradColorToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
}

public struct ModalTokens: Codable, Equatable, Sendable {
    public var maxWidth: Double
    public var contentWidthPadding: Double
    public var edgeSheetWidth: Double
}

public struct DrawerTokens: Codable, Equatable, Sendable {
    public var scrimColor: AinkradColorToken
    public var width: Double
}

public struct ConfirmDialogTokens: Codable, Equatable, Sendable {
    public var maxWidth: Double
    public var titleFont: AinkradFontToken
    public var messageFont: AinkradFontToken
    public var messageColor: AinkradColorToken
}

public struct ButtonTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var pressedScale: Double
    public var hoverScale: Double
    public var spinnerSize: Double
    public var iconFont: AinkradFontToken
    public var labelFont: AinkradFontToken
}

public struct IconButtonTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var shape: AinkradShapeToken
    public var glyphRatio: Double
    public var fg: AinkradStateColor
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var hoverScale: Double
}

public struct ToggleButtonTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var iconFont: AinkradFontToken
    public var labelFont: AinkradFontToken
    public var fg: AinkradStateColor
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var hoverScale: Double
}

public struct AppTileTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var glyphRatio: Double
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var hoverScale: Double
    public var titleFont: AinkradFontToken
    public var titleColor: AinkradColorToken
}

public struct ChipTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var iconFont: AinkradFontToken
    public var labelFont: AinkradFontToken
    public var fg: AinkradStateColor
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var hoverScale: Double
}

public struct SwatchChipTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var swatchSize: Double
    public var swatchShape: AinkradShapeToken
    public var swatchStroke: AinkradStrokeToken
}

public struct BadgeTokens: Codable, Equatable, Sendable {
    public var font: AinkradFontToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
}

public struct KbdTokens: Codable, Equatable, Sendable {
    public var font: AinkradFontToken
    public var color: AinkradColorToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
}

public struct ModeSwitchTokens: Codable, Equatable, Sendable {
    public var glyphFont: AinkradFontToken
    public var labelFont: AinkradFontToken
    public var fg: AinkradStateColor
    public var shape: AinkradShapeToken
    public var hoverFill: AinkradColorToken
}

public struct BasicShellHeaderTokens: Codable, Equatable, Sendable {
    public var glyphFont: AinkradFontToken
    public var titleFont: AinkradFontToken
    public var subtitleFont: AinkradFontToken
    public var subtitleColor: AinkradColorToken
}

public struct ToggleControlTokens: Codable, Equatable, Sendable {
    public var width: Double
    public var height: Double
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var knobColor: AinkradColorToken
    public var knobShadow: AinkradShadowToken
    public var glow: AinkradGlowToken
}

public struct FieldControlTokens: Codable, Equatable, Sendable {
    public var font: AinkradFontToken
    public var leadingGlyphFont: AinkradFontToken
    public var leadingGlyphColor: AinkradColorToken
    public var searchGlyphFont: AinkradFontToken
    public var searchGlyphColor: AinkradStateColor
    public var clearGlyphFont: AinkradFontToken
    public var clearGlyphColor: AinkradColorToken
}

public struct TextAreaTokens: Codable, Equatable, Sendable {
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var glow: AinkradGlowToken
    public var placeholderFont: AinkradFontToken
    public var placeholderColor: AinkradColorToken
    public var minHeight: Double
    public var caretColor: AinkradColorToken
}

public struct SliderTokens: Codable, Equatable, Sendable {
    public var containerShape: AinkradShapeToken
    public var containerFill: AinkradColorToken
    public var containerStroke: AinkradStrokeToken
}

public struct FormRowTokens: Codable, Equatable, Sendable {
    public var tickColor: AinkradColorToken
    public var labelFont: AinkradFontToken
    public var hintFont: AinkradFontToken
    public var hintColor: AinkradColorToken
}

public struct StepperTokens: Codable, Equatable, Sendable {
    public var valueFont: AinkradFontToken
    public var shape: AinkradShapeToken
    public var fill: AinkradColorToken
    public var stroke: AinkradStrokeToken
    public var buttonGlyphFont: AinkradFontToken
    public var buttonGlyphColor: AinkradStateColor
}

public struct CheckboxTokens: Codable, Equatable, Sendable {
    public var size: Double
    public var shape: AinkradShapeToken
    public var fill: AinkradStateColor
    public var stroke: AinkradStrokeToken
    public var checkGlyphFont: AinkradFontToken
    public var glow: AinkradGlowToken
    public var labelFont: AinkradFontToken
    public var hoverScale: Double
}

public struct RadioGroupTokens: Codable, Equatable, Sendable {
    public var ringSize: Double
    public var ringStroke: AinkradStrokeToken
    public var markerShape: String
    public var markerSize: Double
    public var markerFill: AinkradColorToken
    public var glow: AinkradGlowToken
    public var labelFont: AinkradFontToken
}

public struct ColorPickerControlTokens: Codable, Equatable, Sendable {
    public var swatchWidth: Double
    public var swatchHeight: Double
    public var swatchShape: AinkradShapeToken
    public var swatchStroke: AinkradStrokeToken
    public var swatchGlow: AinkradGlowToken
    public var panelWidth: Double
    public var panelMaxHeight: Double
    public var previewHeight: Double
    public var previewShape: AinkradShapeToken
    public var previewStroke: AinkradStrokeToken
    public var channelTickColor: AinkradColorToken
}
