// design-lint: allow-file hex-color,raw-color,radius-literal,font-size,padding-literal,spacing-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — standard form pickers token values
import Foundation

public extension AinkradComponentTokens {
    package static func makeStandardPart2() -> AinkradComponentGroup2 {
        let trig = AinkradRoleTokens.standard.trigger
        return AinkradComponentGroup2(
        toggle: ToggleControlTokens(
            width: 40, height: 22,
            shape: AinkradShapeToken(style: "chamfer", cut: 6, corners: "all"),
            fill: AinkradStateColor(rest: .palette("surfaceElevated", 0.6), selected: .palette("accentPrimary", 0.9)),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("foreground", 0.18), hover: .palette("foreground", 0.35), selected: .palette("accentSecondary", 0.75)), width: AinkradStateDouble(rest: 1.0, selected: 1.25)),
            knobColor: .palette("white", 1.0),
            knobShadow: AinkradShadowToken(color: .palette("black", 0.4), radius: 3, x: 0, y: 0),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.0), selected: .palette("accentSecondary", 0.45)), radius: AinkradStateDouble(rest: 0, selected: 6))
        ),
        secureField: FieldControlTokens(
            font: AinkradFontToken(role: "mono"),
            leadingGlyphFont: AinkradFontToken(size: 12, scaled: false),
            leadingGlyphColor: .palette("foreground", 0.55),
            searchGlyphFont: AinkradFontToken(size: 12, weight: "semibold", scaled: false),
            searchGlyphColor: AinkradStateColor(rest: .palette("accentSecondary", 0.55)),
            clearGlyphFont: AinkradFontToken(size: 12, scaled: false),
            clearGlyphColor: .palette("foreground", 0.45)
        ),
        textField: FieldControlTokens(
            font: AinkradFontToken(role: "body"),
            leadingGlyphFont: AinkradFontToken(size: 12, scaled: false),
            leadingGlyphColor: .palette("foreground", 0.55),
            searchGlyphFont: AinkradFontToken(size: 12, weight: "semibold", scaled: false),
            searchGlyphColor: AinkradStateColor(rest: .palette("accentSecondary", 0.55)),
            clearGlyphFont: AinkradFontToken(size: 12, scaled: false),
            clearGlyphColor: .palette("foreground", 0.45)
        ),
        searchField: FieldControlTokens(
            font: AinkradFontToken(role: "body"),
            leadingGlyphFont: AinkradFontToken(size: 12, scaled: false),
            leadingGlyphColor: .palette("foreground", 0.55),
            searchGlyphFont: AinkradFontToken(size: 12, weight: "semibold", scaled: false),
            searchGlyphColor: AinkradStateColor(rest: .palette("accentSecondary", 0.55), focused: .palette("accentSecondary", 0.95)),
            clearGlyphFont: AinkradFontToken(size: 12, scaled: false),
            clearGlyphColor: .palette("foreground", 0.45)
        ),
        textArea: TextAreaTokens(
            shape: AinkradShapeToken(style: "chamfer", cut: 8),
            fill: .palette("surfaceElevated", 0.5),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.25), focused: .palette("accentPrimary", 0.9)), width: AinkradStateDouble(rest: 1.0, focused: 1.5)),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.0), focused: .palette("accentSecondary", 0.4)), radius: AinkradStateDouble(rest: 0, focused: 6)),
            placeholderFont: AinkradFontToken(role: "body"),
            placeholderColor: .palette("foreground", 0.4),
            minHeight: 80,
            caretColor: .palette("accentSecondary", 1.0)
        ),
        slider: SliderTokens(
            containerShape: AinkradShapeToken(style: "chamfer", cut: 6),
            containerFill: .palette("surfaceElevated", 0.3),
            containerStroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.2)), width: AinkradStateDouble(rest: 1.0))
        ),
        formRow: FormRowTokens(
            tickColor: .palette("accentSecondary", 0.55),
            labelFont: AinkradFontToken(role: "body"),
            hintFont: AinkradFontToken(role: "caption"),
            hintColor: .palette("foreground", 0.55)
        ),
        stepper: StepperTokens(
            valueFont: AinkradFontToken(role: "mono", weight: "medium", monospacedDigits: true),
            shape: AinkradShapeToken(style: "chamfer", cut: 6),
            fill: .palette("surfaceElevated", 0.5),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.3)), width: AinkradStateDouble(rest: 1.25)),
            buttonGlyphFont: AinkradFontToken(size: 10, weight: "bold", scaled: false),
            buttonGlyphColor: AinkradStateColor(rest: .palette("accentSecondary", 1.0), disabled: .palette("foreground", 0.25))
        ),
        rangeSlider: SliderTokens(
            containerShape: AinkradShapeToken(style: "chamfer", cut: 6),
            containerFill: .palette("surfaceElevated", 0.3),
            containerStroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.2)), width: AinkradStateDouble(rest: 1.0))
        ),
        checkbox: CheckboxTokens(
            size: 18,
            shape: AinkradShapeToken(style: "chamfer", cut: 3),
            fill: AinkradStateColor(rest: .palette("surfaceElevated", 0.5), selected: .palette("accentSecondary", 0.22)),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.4), hover: .palette("accentSecondary", 0.85), selected: .palette("accentSecondary", 0.85)), width: AinkradStateDouble(rest: 1.0, selected: 1.25)),
            checkGlyphFont: AinkradFontToken(size: 10, weight: "bold", scaled: false),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.0), selected: .palette("accentSecondary", 0.5)), radius: AinkradStateDouble(rest: 0, selected: 4)),
            labelFont: AinkradFontToken(role: "body"),
            hoverScale: 1.04
        ),
        radioGroup: RadioGroupTokens(
            ringSize: 16,
            ringStroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.4), hover: .palette("accentSecondary", 0.9), selected: .palette("accentSecondary", 0.9)), width: AinkradStateDouble(rest: 1.0, selected: 1.25)),
            markerShape: "Diamond",
            markerSize: 8,
            markerFill: .palette("accentSecondary", 1.0),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.0), selected: .palette("accentSecondary", 0.5)), radius: AinkradStateDouble(rest: 0, selected: 4)),
            labelFont: AinkradFontToken(role: "body")
        ),
        colorPicker: ColorPickerControlTokens(
            swatchWidth: 28, swatchHeight: 24,
            swatchShape: AinkradShapeToken(style: "chamfer", cut: 6),
            swatchStroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.35), focused: .palette("accentPrimary", 0.9)), width: AinkradStateDouble(rest: 1.0, focused: 1.25)),
            swatchGlow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.0), focused: .palette("accentPrimary", 0.45)), radius: AinkradStateDouble(rest: 0, focused: 6)),
            panelWidth: 244, panelMaxHeight: 360, previewHeight: 28,
            previewShape: AinkradShapeToken(style: "chamfer", cut: 6),
            previewStroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.3)), width: AinkradStateDouble(rest: 1.0)),
            channelTickColor: .palette("accentSecondary", 0.55)
        ),
        segmentedPicker: SegmentedPickerTokens(
            labelFont: AinkradFontToken(role: "caption"),
            labelSelectedFont: AinkradFontToken(role: "caption", weight: "medium"),
            fg: AinkradStateColor(rest: .palette("foreground", 0.75)),
            shape: AinkradShapeToken(style: "chamfer", cut: 5),
            fill: AinkradStateColor(rest: .palette("surfaceElevated", 0.5), hover: .palette("surfaceElevated", 0.65), selected: .palette("accentPrimary", 0.9)),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.15), hover: .palette("accentPrimary", 0.5), selected: .clear), width: AinkradStateDouble(rest: 1.0)),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.0), selected: .palette("accentPrimary", 0.4)), radius: AinkradStateDouble(rest: 0, selected: 5))
        ),
        combobox: AinkradFieldRoleTokens(
            shape: AinkradShapeToken(style: "chamfer", cut: 8),
            fill: .palette("surfaceElevated", 0.5),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.3), focused: .palette("accentPrimary", 0.85)), width: AinkradStateDouble(rest: 1.0, focused: 1.25)),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.0), focused: .palette("accentPrimary", 0.45)), radius: AinkradStateDouble(rest: 0, focused: 6))
        ),
        selectTrigger: trig,
        multiSelectTrigger: trig,
        groupedSelectTrigger: trig,
        multiSelectCheck: MultiSelectCheckTokens(
            size: 12,
            shape: AinkradShapeToken(style: "chamfer", cut: 2),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.6)), width: AinkradStateDouble(rest: 1.0)),
            glyphFont: AinkradFontToken(size: 8, weight: "bold", scaled: false)
        ),
        groupedSelectRows: GroupedSelectRowTokens(
            headerFont: AinkradFontToken(role: "caption"),
            headerColor: .palette("foreground", 0.45),
            iconFont: AinkradFontToken(size: 11, scaled: false),
            iconColor: AinkradStateColor(rest: .palette("foreground", 0.75), disabled: .palette("foreground", 0.4)),
            titleFont: AinkradFontToken(role: "body"),
            titleColor: AinkradStateColor(rest: .palette("foreground", 1.0), disabled: .palette("foreground", 0.4)),
            detailFont: AinkradFontToken(role: "caption"),
            detailColor: AinkradStateColor(rest: .palette("foreground", 0.5), disabled: .palette("foreground", 0.3)),
            emptyFont: AinkradFontToken(role: "caption"),
            emptyColor: .palette("foreground", 0.5)
        )
    )
    }
}
