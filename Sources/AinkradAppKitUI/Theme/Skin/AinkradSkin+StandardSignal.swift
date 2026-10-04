// design-lint: allow-file hex-color,raw-color,radius-literal,font-size,padding-literal,spacing-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — standard signal and settings token values
import Foundation

extension AinkradComponentTokens {
    package static func makeStandardPart4() -> AinkradComponentGroup4 {
        AinkradComponentGroup4(
            logView: LogViewTokens(
                ansiSlots: [
                    .palette("foreground", 0.45),
                    .palette("danger", 1.0),
                    .palette("success", 1.0),
                    .palette("warning", 1.0),
                    .palette("accentPrimary", 1.0),
                    .palette("accentSecondary", 1.0),
                    .palette("accentPrimary", 0.8),
                    .palette("foreground", 1.0),
                    .palette("foreground", 0.6),
                    .palette("danger", 1.0),
                    .palette("success", 1.0),
                    .palette("warning", 1.0),
                    .palette("accentPrimary", 1.0),
                    .palette("accentSecondary", 1.0),
                    .palette("accentPrimary", 0.9),
                    .palette("foreground", 1.0),
                ],
                insetX: 8, insetY: 8,
                font: AinkradFontToken(size: 11, mono: "system"),
                sourcePrefixOpacity: 0.45,
                dimOpacity: 0.6,
                stderrSlot: 1
            ),
            signalFeedList: SignalFeedListTokens(
                dayHeaderFont: AinkradFontToken(size: 9.5, weight: "semibold", mono: "family", tracking: 0.7),
                dayHeaderColor: .palette("foreground", 0.42),
                fill: .palette("surface", 0.92),
                emptyGlyphFont: AinkradFontToken(size: 18, weight: "light", scaled: false),
                emptyGlyphColor: .palette("foreground", 0.3),
                emptyTextFont: AinkradFontToken(size: 12, weight: "medium"),
                emptyTextColor: .palette("foreground", 0.55)
            ),
            signalFeedRow: SignalFeedRowTokens(
                appGlyphFont: AinkradFontToken(size: 13, weight: "medium", scaled: false),
                appGlyphSize: 16, hoverScale: 1.12,
                titleFont: AinkradFontToken(size: 12.5),
                repeatGlyphFont: AinkradFontToken(size: 8.5, scaled: false),
                timeFont: AinkradFontToken(size: 10, weight: "medium", mono: "family"),
                timeColor: .palette("foreground", 0.45),
                bodyFont: AinkradFontToken(size: 11.5),
                bodyColor: .palette("foreground", 0.62),
                metaFont: AinkradFontToken(size: 9.5, weight: "medium", mono: "family", tracking: 0.4),
                metaColor: .palette("foreground", 0.45),
                chevronFont: AinkradFontToken(size: 8, weight: "bold", scaled: false),
                chevronColor: AinkradStateColor(rest: .palette("foreground", 0.3), hover: .palette("foreground", 0.6)),
                chevronSize: 12, unreadDotSize: 5,
                shape: AinkradShapeToken(style: "chamfer", cut: 8),
                fill: AinkradStateColor(
                    rest: .palette("surfaceElevated", 1.0), hover: .palette("surfaceElevated", 0.9)),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .clear, hover: .palette("accentSecondary", 0.35)),
                    width: AinkradStateDouble(rest: 1.0)),
                focusRingColor: .palette("accentPrimary", 0.9),
                focusRingWidth: 1.5,
                infoSeverityColor: .palette("success", 0.55)
            ),
            signalFeedRowAction: SignalFeedRowActionTokens(
                font: AinkradFontToken(size: 10.5, weight: "medium"),
                shape: AinkradShapeToken(style: "chamfer", cut: 4),
                fill: .tint(0.14),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .tint(0.5)), width: AinkradStateDouble(rest: 1.0))
            ),
            signalSourceRail: SignalSourceRailTokens(
                width: 168, dotSize: 5,
                nameFont: AinkradFontToken(size: 11.5),
                nameOpacity: AinkradStateDouble(rest: 0.72, hover: 0.9, selected: 1.0),
                countFont: AinkradFontToken(size: 9.5, weight: "medium", mono: "family"),
                countColor: .palette("foreground", 0.5),
                shape: AinkradShapeToken(style: "chamfer", cut: 8),
                fill: AinkradStateColor(
                    rest: .clear, hover: .palette("surfaceElevated", 0.45), selected: .palette("surfaceElevated", 0.9)),
                edgeCapsuleColor: .palette("accentSecondary", 1.0),
                edgeCapsuleWidth: 2
            ),
            signalToast: SignalToastTokens(
                width: 320,
                listSpring: AinkradAnimationToken(curve: "spring", response: 0.34, damping: 0.82),
                removalOpacity: 0.0, removalScale: 0.7,
                expandSpring: AinkradAnimationToken(curve: "spring", response: 0.30, damping: 0.86),
                shape: AinkradShapeToken(style: "chamfer", cut: 12),
                fill: .palette("surfaceElevated", 1.0),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(
                        rest: .palette("accentSecondary", 0.28), hover: .palette("accentSecondary", 0.45)),
                    width: AinkradStateDouble(rest: 1.0)),
                severityEdgeWidth: 2.5, dwellBarHeight: 1.5, appTileSize: 34,
                fallbackGlyphFont: AinkradFontToken(size: 18, weight: "medium", scaled: false),
                fallbackGlyphSize: 34,
                titleFont: AinkradFontToken(size: 12.5, weight: "semibold"),
                titleGlyphFont: AinkradFontToken(size: 11, weight: "semibold", scaled: false),
                repeatFont: AinkradFontToken(size: 10, weight: "semibold"),
                timeFont: AinkradFontToken(size: 10),
                timeColor: .palette("foreground", 0.4),
                bodyFont: AinkradFontToken(size: 11.5),
                bodyColor: .palette("foreground", 0.66),
                chevronCloseFont: AinkradFontToken(size: 9, weight: "bold", scaled: false),
                chevronCloseColor: AinkradStateColor(
                    rest: .palette("foreground", 0.4), hover: .palette("foreground", 0.7)),
                chevronCloseSize: 14,
                actionFont: AinkradFontToken(size: 11, weight: "semibold"),
                actionWidth: 22, actionHeight: 20,
                actionShape: AinkradShapeToken(style: "chamfer", cut: 4),
                actionFill: .tint(0.14),
                actionStroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .tint(0.45)), width: AinkradStateDouble(rest: 1.0)),
                moreFont: AinkradFontToken(size: 10, weight: "bold"),
                moreWidth: 22, moreHeight: 20,
                moreFill: .palette("foreground", 0.08),
                moreColor: .palette("foreground", 0.6)
            ),
            settingsGroup: SettingsGroupTokens(
                searchDimmedOpacity: 0.35,
                highlightStroke: AinkradStrokeToken(
                    color: AinkradStateColor(rest: .palette("accentSecondary", 0.9)),
                    width: AinkradStateDouble(rest: 1.5)),
                captionColor: .palette("foreground", 0.45)
            ),
            settingsPage: SettingsPageTokens(
                listGap: 24, padding: 18, miniMapWidth: 150, miniMapGutter: 18, miniMapPaddingTopTrailing: 18,
                tabInsertAnimation: AinkradAnimationToken(curve: "easeOut", duration: 0.12),
                scrollAnimation: AinkradAnimationToken(curve: "easeOut", duration: 0.2),
                hitsGlyphFont: AinkradFontToken(size: 10, scaled: false),
                hitsCaptionFont: AinkradFontToken(role: "caption", weight: "medium"),
                hitsColor: .palette("accentSecondary", 0.9),
                miniMapTitleFont: AinkradFontToken(role: "mono", weight: "medium", kerning: 2.5),
                miniMapTitleColor: .palette("foreground", 0.4),
                itemsFont: AinkradFontToken(role: "caption"),
                itemsColor: .palette("foreground", 0.6)
            ),
            settingsRow: SettingsRowTokens(
                shape: AinkradShapeToken(style: "chamfer", cut: 12),
                fill: .palette("surfaceElevated", 0.5),
                stroke: AinkradStrokeToken(
                    color: AinkradStateColor(
                        rest: .palette("accentPrimary", 0.15), hover: .palette("accentPrimary", 0.3)),
                    width: AinkradStateDouble(rest: 1.0)),
                hoverAnimation: AinkradAnimationToken(curve: "easeOut", durationKey: "fast"),
                resetGlyphFont: AinkradFontToken(size: 10, scaled: false),
                resetGlyphColor: .palette("accentSecondary", 0.9),
                valueFont: AinkradFontToken(role: "mono"),
                valueColor: .palette("foreground", 0.8)
            )
        )
    }

    public static func makeStandard() -> AinkradComponentTokens {
        let p1 = makeStandardPart1()
        let p2 = makeStandardPart2()
        let p3 = makeStandardPart3()
        let p4 = makeStandardPart4()
        return AinkradComponentTokens(g1: p1, g2: p2, g3: p3, g4: p4)
    }

    /// Built once: rebuilding ~50 KB of token groups per read cost a Debug
    /// worker-thread stack its whole budget (see SkinStackDepthTests).
    public static var standard: AinkradComponentTokens { cachedStandard }
    private static let cachedStandard = makeStandard()
}
