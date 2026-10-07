import Foundation

/// The markdown editor's type ratios (`type.editor`), shared by Lore's native
/// editor and its CM6 stylesheet. Every default is today's Lore literal.
public struct AinkradTypeEditorTokens: Codable, Equatable, Sendable {
    /// Line-height multiple at Standard density.
    public var lineHeight: Double
    /// Heading sizes h1…h6 as multiples of the body size.
    public var headingRatios: [Double]
    /// A code fence's language label as a multiple of the body size.
    public var labelRatio: Double

    public init(
        lineHeight: Double = 1.5,
        headingRatios: [Double] = [1.80, 1.60, 1.40, 1.25, 1.125, 1.05],
        labelRatio: Double = 0.85
    ) {
        self.lineHeight = lineHeight
        self.headingRatios = headingRatios
        self.labelRatio = labelRatio
    }
}

/// Callout hues (`syntax.callout`), in degrees, and the tones they are drawn
/// at. Semantic like the code hues — danger is red in every theme — and a
/// touch more saturated, because a callout tints a panel, not a few glyphs.
/// Aliases (`info` → `note`, `tip` → `abstract`, …) are the caller's mapping.
public struct AinkradSyntaxCalloutTokens: Codable, Equatable, Sendable {
    public var note: Double
    public var abstract: Double
    public var todo: Double
    public var success: Double
    public var warning: Double
    public var failure: Double
    public var bug: Double
    public var example: Double
    public var onDark: AinkradSyntaxTone
    public var onLight: AinkradSyntaxTone

    public init(
        note: Double = 210, abstract: Double = 175, todo: Double = 45, success: Double = 140,
        warning: Double = 30, failure: Double = 0, bug: Double = 350, example: Double = 275,
        onDark: AinkradSyntaxTone = AinkradSyntaxTone(saturation: 0.55, brightness: 0.95),
        onLight: AinkradSyntaxTone = AinkradSyntaxTone(saturation: 0.75, brightness: 0.70)
    ) {
        self.note = note
        self.abstract = abstract
        self.todo = todo
        self.success = success
        self.warning = warning
        self.failure = failure
        self.bug = bug
        self.example = example
        self.onDark = onDark
        self.onLight = onLight
    }

    var hues: [(String, Double)] {
        [
            ("note", note), ("abstract", abstract), ("todo", todo), ("success", success),
            ("warning", warning), ("failure", failure), ("bug", bug), ("example", example),
        ]
    }
}

/// Fixed, theme-independent colours (`colors`): data-viz hues that must not
/// follow the palette.
public struct AinkradFixedColorTokens: Codable, Equatable, Sendable {
    /// GitMage's commit-graph lanes after the three theme accents. GitMage's
    /// literals (0.38, 0.80, 0.52 · 0.92, 0.62, 0.32 · 0.60, 0.52, 0.92) to the
    /// nearest 8-bit step, because a theme file stores `#RRGGBB`: the same
    /// 8-bit colour, and a value that survives a theme-file round trip.
    public var graphLanes: [AinkradColorToken]

    public init(
        graphLanes: [AinkradColorToken] = [
            .hex(0x61 / 255.0, 0xCC / 255.0, 0x85 / 255.0, 1.0),
            .hex(0xEB / 255.0, 0x9E / 255.0, 0x52 / 255.0, 1.0),
            .hex(0x99 / 255.0, 0x85 / 255.0, 0xEB / 255.0, 1.0),
        ]
    ) {
        self.graphLanes = graphLanes
    }
}
