// design-lint: allow-file hex-color,raw-color,radius-literal,font-size,padding-literal,spacing-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — standard controls token values
import Foundation

extension AinkradComponentTokens {
    package static func makeStandardPart1() -> AinkradComponentGroup1 {
        AinkradComponentGroup1(
            panel: PanelTokens(
                shape: AinkradShapeToken(style: "chamfer", cut: 14),
                fill: .palette("background", 0.94),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .palette("accentSecondary", 0.4)),
                    width: AinkradStateDouble(rest: 1.0))
            ),
            card: CardTokens(
                shape: AinkradShapeToken(style: "chamfer", cut: 12),
                padding: 12,
                fill: .palette("surface", 0.9),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.25), hover: .palette("accentSecondary", 0.6),
                        selected: .palette("accentPrimary", 0.85)), width: AinkradStateDouble(rest: 1.0, selected: 1.5)),
                hoverScale: 1.015,
                hoverBracketLength: 10,
                hoverBracketInset: -2
            ),
            sectionFrame: SectionFrameTokens(
                tickWidth: 14, tickHeight: 2,
                titleFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 1.2),
                titleColor: .palette("foreground", 0.7),
                bodyShape: AinkradShapeToken(style: "chamfer", cut: 12),
                bodyFill: .palette("surfaceElevated", 0.35),
                bodyStroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .palette("accentSecondary", 0.35)),
                    width: AinkradStateDouble(rest: 1.0))
            ),
            settingsPanel: SettingsPanelTokens(
                shape: AinkradShapeToken(style: "chamfer", cut: 12),
                fill: .palette("surfaceElevated", 0.32),
                padding: 16,
                titleFont: AinkradFontToken(role: "headline", weight: "medium"),
                titleColor: .palette("foreground", 0.95),
                hintFont: AinkradFontToken(role: "caption"),
                hintColor: .palette("foreground", 0.55),
                hintReadingWidth: 560
            ),
            captionedRow: CaptionedRowTokens(
                captionColumnWidth: 86,
                captionFont: AinkradFontToken(role: "caption", weight: "medium"),
                captionColor: .palette("foreground", 0.45)
            ),
            codeBlock: CodeBlockTokens(
                headerFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 0.8),
                headerColor: .palette("foreground", 0.55),
                codeFont: AinkradFontToken(role: "mono"),
                codeColor: .palette("foreground", 0.92),
                shape: AinkradShapeToken(style: "chamfer", cut: 8),
                fill: .palette("surface", 0.9),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .palette("accentSecondary", 0.3)),
                    width: AinkradStateDouble(rest: 1.0))
            ),
            modal: ModalTokens(maxWidth: 480, contentWidthPadding: 32, edgeSheetWidth: 360),
            drawer: DrawerTokens(scrimColor: .palette("black", 0.45), width: 280),
            confirmDialog: ConfirmDialogTokens(
                maxWidth: 360,
                titleFont: AinkradFontToken(role: "headline", weight: "semibold", tracking: 0.6),
                messageFont: AinkradFontToken(role: "body"),
                messageColor: .palette("foreground", 0.75)
            ),
            button: ButtonTokens(
                shape: AinkradShapeToken(style: "chamfer", cut: 8),
                fill: AinkradStateColor(
                    rest: .tint(0.9), hover: .tint(0.95), pressed: .tint(0.95), disabled: .tint(0.4)),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .tint(0.55), hover: .tint(0.9)),
                    width: AinkradStateDouble(rest: 1.0, hover: 1.25)),
                glow: AinkradGlowToken(
                    color: AinkradStateColor(rest: .tint(0.0), hover: .tint(0.55)),
                    radius: AinkradStateDouble(rest: 0, hover: 6)),
                pressedScale: 0.97, hoverScale: 1.02, spinnerSize: 14,
                iconFont: AinkradFontToken(size: 12, weight: "semibold", scaled: false),
                labelFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 0.8)
            ),
            iconButton: IconButtonTokens(
                size: 30,
                shape: AinkradShapeToken(style: "chamfer", cutRatio: 0.2),
                glyphRatio: 0.433,
                fg: AinkradStateColor(rest: .palette("foreground", 0.75), hover: .palette("foreground", 1.0)),
                fill: AinkradStateColor(
                    rest: .palette("surfaceElevated", 0.4), hover: .palette("surfaceElevated", 0.7)),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.35), hover: .palette("accentSecondary", 0.85)),
                    width: AinkradStateDouble(rest: 1.0)),
                glow: AinkradGlowToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.0), hover: .palette("accentSecondary", 0.5)),
                    radius: AinkradStateDouble(rest: 0, hover: 5)),
                hoverScale: 1.05
            ),
            toggleButton: ToggleButtonTokens(
                shape: AinkradShapeToken(style: "chamfer", cut: 6),
                iconFont: AinkradFontToken(size: 12, weight: "semibold", scaled: false),
                labelFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 0.8),
                fg: AinkradStateColor(rest: .palette("foreground", 0.75), selected: .palette("foreground", 1.0)),
                fill: AinkradStateColor(
                    rest: .palette("surfaceElevated", 0.4), hover: .palette("surfaceElevated", 0.6),
                    selected: .palette("accentPrimary", 0.85)),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.3), hover: .palette("accentSecondary", 0.6),
                        selected: .palette("accentSecondary", 0.95)),
                    width: AinkradStateDouble(rest: 1.0, selected: 1.25)),
                glow: AinkradGlowToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.0), selected: .palette("accentSecondary", 0.55)),
                    radius: AinkradStateDouble(rest: 0, selected: 5)),
                hoverScale: 1.02
            ),
            appTile: AppTileTokens(
                size: 44, glyphRatio: 0.42,
                shape: AinkradShapeToken(style: "chamfer", cutRatio: 0.22),
                fill: .palette("surfaceElevated", 0.85),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.3), hover: .palette("accentSecondary", 0.65),
                        selected: .palette("accentPrimary", 0.9)), width: AinkradStateDouble(rest: 1.0, selected: 1.5)),
                glow: AinkradGlowToken(
                    color: AinkradStateColor(
                        rest: .palette("accentPrimary", 0.0), hover: .palette("accentPrimary", 0.4),
                        selected: .palette("accentPrimary", 0.5)),
                    radius: AinkradStateDouble(rest: 0, hover: 8, selected: 8)),
                hoverScale: 1.05,
                titleFont: AinkradFontToken(role: "caption"),
                titleColor: .palette("foreground", 0.75)
            ),
            chip: ChipTokens(
                shape: AinkradShapeToken(style: "chamfer", cut: 5),
                iconFont: AinkradFontToken(size: 10, weight: "semibold", scaled: false),
                labelFont: AinkradFontToken(role: "caption"),
                fg: AinkradStateColor(rest: .palette("foreground", 0.85)),
                fill: AinkradStateColor(
                    rest: .palette("surfaceElevated", 0.45), hover: .palette("surfaceElevated", 0.65)),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.3), hover: .palette("accentSecondary", 0.6)),
                    width: AinkradStateDouble(rest: 1.0)),
                hoverScale: 1.03
            ),
            swatchChip: SwatchChipTokens(
                shape: AinkradShapeToken(style: "chamfer", cut: 5),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.3), selected: .palette("accentPrimary", 0.85)),
                    width: AinkradStateDouble(rest: 1.0, selected: 1.25)),
                glow: AinkradGlowToken(
                    color: AinkradStateColor(
                        rest: .palette("accentPrimary", 0.0), selected: .palette("accentPrimary", 0.3)),
                    radius: AinkradStateDouble(rest: 0, selected: 4)),
                swatchSize: 10,
                swatchShape: AinkradShapeToken(style: "chamfer", cut: 2, corners: "all"),
                swatchStroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .palette("foreground", 0.25)), width: AinkradStateDouble(rest: 0.5))
            ),
            badge: BadgeTokens(
                font: AinkradFontToken(role: "caption", weight: "semibold", tracking: 0.6),
                shape: AinkradShapeToken(style: "chamfer", cut: 4),
                fill: .tint(0.16),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .tint(0.55)), width: AinkradStateDouble(rest: 1.0))
            ),
            kbd: KbdTokens(
                font: AinkradFontToken(role: "mono", weight: "medium"),
                color: .palette("foreground", 0.75),
                shape: AinkradShapeToken(style: "chamfer", cut: 3),
                fill: .palette("surfaceElevated", 0.55),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .palette("foreground", 0.2)), width: AinkradStateDouble(rest: 1.0))
            ),
            modeSwitch: ModeSwitchTokens(
                glyphFont: AinkradFontToken(size: 9, weight: "semibold", scaled: false),
                labelFont: AinkradFontToken(role: "caption", weight: "medium"),
                fg: AinkradStateColor(rest: .palette("foreground", 0.55), hover: .palette("foreground", 0.95)),
                shape: AinkradShapeToken(style: "continuous", cut: 8),
                hoverFill: .palette("foreground", 0.08)
            ),
            basicShellHeader: BasicShellHeaderTokens(
                glyphFont: AinkradFontToken(size: 12, weight: "medium", scaled: false),
                titleFont: AinkradFontToken(role: "headline", weight: "medium"),
                subtitleFont: AinkradFontToken(role: "caption"),
                subtitleColor: .palette("foreground", 0.55)
            )
        )
    }
}
