// design-lint: allow-file hex-color,raw-color,radius-literal,font-size,padding-literal,spacing-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — standard rows and tables token values
import Foundation

public extension AinkradComponentTokens {
    package static func makeStandardPart3() -> AinkradComponentGroup3 {
        AinkradComponentGroup3(
        contextMenu: ContextMenuTokens(
            glyphFont: AinkradFontToken(size: 12, weight: "semibold", scaled: false),
            bodyFont: AinkradFontToken(role: "body"),
            rowShape: AinkradShapeToken(style: "chamfer", cut: 4),
            rowHoverFill: .palette("accentSecondary", 0.14)
        ),
        tooltipPopover: TooltipPopoverTokens(
            textFont: AinkradFontToken(role: "caption"),
            textColor: .palette("foreground", 0.9),
            showDelay: 0.45,
            tooltipMaxHeight: 160,
            popoverMaxHeight: 420
        ),
        commandMenuRow: CommandMenuRowTokens(
            glyphFont: AinkradFontToken(size: 13, weight: "semibold", scaled: false),
            titleFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 0.6),
            detailFont: AinkradFontToken(role: "mono"),
            detailColor: .palette("foreground", 0.45),
            valueFont: AinkradFontToken(role: "mono"),
            valueColor: .palette("accentSecondary", 0.85),
            fg: AinkradStateColor(rest: .palette("foreground", 0.65), selected: .palette("foreground", 1.0)),
            shape: AinkradShapeToken(style: "chamfer", cut: 6),
            fill: AinkradStateColor(rest: .palette("surfaceElevated", 0.2), selected: .palette("accentPrimary", 0.85)),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .clear, selected: .palette("accentSecondary", 0.9)), width: AinkradStateDouble(rest: 1.25)),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .clear, selected: .palette("accentSecondary", 0.5)), radius: AinkradStateDouble(rest: 0, selected: 5)),
            hoverScale: 1.015
        ),
        navListRow: NavListRowTokens(
            glyphFont: AinkradFontToken(size: 12, weight: "semibold", scaled: false),
            bodyFont: AinkradFontToken(role: "body"),
            bodySelectedFont: AinkradFontToken(role: "body", weight: "semibold"),
            fg: AinkradStateColor(rest: .palette("foreground", 0.6), hover: .palette("foreground", 0.85), selected: .palette("foreground", 1.0)),
            shape: AinkradShapeToken(style: "rounded", cut: 8),
            fill: AinkradStateColor(rest: .clear, hover: .palette("surfaceElevated", 0.3), selected: .palette("surfaceElevated", 0.6))
        ),
        tabs: TabsTokens(
            labelFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 0.8),
            fg: AinkradStateColor(rest: .palette("foreground", 0.6), hover: .palette("foreground", 0.9), selected: .palette("foreground", 1.0)),
            shape: AinkradShapeToken(style: "chamfer", cut: 6),
            fill: AinkradStateColor(rest: .palette("surfaceElevated", 0.25), hover: .palette("surfaceElevated", 0.5), selected: .palette("accentPrimary", 0.85)),
            hoverScale: 1.02
        ),
        breadcrumb: BreadcrumbTokens(
            chevronFont: AinkradFontToken(size: 10, weight: "bold", scaled: false),
            chevronColor: .palette("accentSecondary", 0.55),
            font: AinkradFontToken(role: "caption", tracking: 0.6),
            activeFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 0.6),
            activeColor: .palette("accentSecondary", 1.0),
            itemColor: .palette("foreground", 0.6)
        ),
        pagination: PaginationTokens(
            currentDotSize: 8, dotSize: 6,
            currentFill: .palette("accentPrimary", 1.0),
            dotFill: .palette("foreground", 0.25),
            currentGlow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentPrimary", 0.6)), radius: AinkradStateDouble(rest: 3)),
            disabledOpacity: 0.3
        ),
        listRow: ListRowTokens(
            titleFont: AinkradFontToken(role: "body", weight: "medium"),
            subtitleFont: AinkradFontToken(role: "caption"),
            subtitleColor: .palette("foreground", 0.55),
            shape: AinkradShapeToken(style: "chamfer", cut: 6),
            fill: AinkradStateColor(rest: .clear, hover: .palette("surfaceElevated", 0.5), selected: .palette("accentPrimary", 0.16))
        ),
        statRow: StatRowTokens(
            labelFont: AinkradFontToken(role: "caption", tracking: 0.6),
            labelColor: .palette("foreground", 0.6),
            valueFont: AinkradFontToken(role: "mono", weight: "medium")
        ),
        iconGlyph: IconGlyphTokens(
            size: 16, glyphRatio: 0.55,
            shape: AinkradShapeToken(style: "chamfer", cutRatio: 0.2, minCut: 2),
            fill: .palette("accentPrimary", 0.85),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.4)), width: AinkradStateDouble(rest: 1.0))
        ),
        dataTable: DataTableTokens(
            headerShape: AinkradShapeToken(style: "chamfer", cut: 6, corners: "top"),
            headerFill: .palette("surfaceElevated", 0.7),
            headerFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 0.8),
            headerColor: .palette("foreground", 0.75),
            sortGlyphFont: AinkradFontToken(size: 8, weight: "bold", scaled: false),
            cellFont: AinkradFontToken(role: "body"),
            cellColor: .palette("foreground", 0.9),
            rowShape: AinkradShapeToken(style: "chamfer", cut: 4),
            rowFill: AinkradStateColor(rest: .clear, hover: .palette("surfaceElevated", 0.4), selected: .palette("accentPrimary", 0.16))
        ),
        disclosureGroup: DisclosureGroupTokens(
            chevronFont: AinkradFontToken(size: 10, scaled: false),
            chevronColor: .palette("foreground", 0.5),
            titleFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 1.2),
            titleColor: .palette("foreground", 0.7),
            headerShape: AinkradShapeToken(style: "chamfer", cut: 8),
            headerFill: AinkradStateColor(rest: .palette("surfaceElevated", 1.0), hover: .palette("surfaceElevated", 0.5))
        ),
        emptyState: EmptyStateTokens(
            glyphFont: AinkradFontToken(role: "display", scaled: false),
            glyphColor: .palette("foreground", 0.35),
            titleFont: AinkradFontToken(role: "headline", weight: "medium"),
            messageFont: AinkradFontToken(role: "body"),
            messageColor: .palette("foreground", 0.6)
        ),
        loadingState: LoadingStateTokens(
            spinnerSize: 28,
            captionColor: .palette("foreground", 0.6)
        ),
        errorState: ErrorStateTokens(
            glyphFont: AinkradFontToken(role: "title", scaled: false),
            glyphColor: .palette("danger", 1.0),
            shape: AinkradShapeToken(style: "chamfer", cut: 8),
            fill: .palette("danger", 0.12),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .palette("danger", 0.45)), width: AinkradStateDouble(rest: 1.25)),
            messageFont: AinkradFontToken(role: "body"),
            messageColor: .palette("foreground", 0.75)
        ),
        sectionHeader: SectionHeaderTokens(
            tickWidth: 12, tickHeight: 2,
            titleFont: AinkradFontToken(role: "caption", weight: "semibold", tracking: 1.2),
            titleColor: .palette("foreground", 0.65),
            subtitleFont: AinkradFontToken(role: "caption"),
            subtitleColor: .palette("foreground", 0.4)
        ),
        statusBar: StatusBarTokens(
            segments: 12, height: 8,
            shape: AinkradShapeToken(style: "chamfer", cut: 2, corners: "all"),
            emptyFill: .palette("foreground", 0.08),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .tint(0.5)), radius: AinkradStateDouble(rest: 2))
        ),
        spinner: SpinnerTokens(
            size: 20,
            trackColor: .palette("foreground", 0.12),
            arcTrim: 0.28,
            defaultColor: .palette("accentSecondary", 1.0),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.6)), radius: AinkradStateDouble(rest: 3)),
            period: 1.0, pulsePeriod: 1.2, pulseFloor: 0.35
        ),
        meter: MeterTokens(
            size: 88,
            trackColor: .palette("foreground", 0.1),
            arcGlow: AinkradGlowToken(color: AinkradStateColor(rest: .palette("accentSecondary", 0.55)), radius: AinkradStateDouble(rest: 4)),
            valueFont: AinkradFontToken(role: "headline", weight: "semibold"),
            labelFont: AinkradFontToken(role: "caption", tracking: 0.6),
            labelColor: .palette("foreground", 0.55)
        ),
        stackedStatusBar: StackedStatusBarTokens(
            height: 4, minRun: 2, trackColor: .palette("foreground", 0.12)
        ),
        toast: ToastTokens(
            iconFont: AinkradFontToken(size: 12, weight: "semibold", scaled: false),
            bodyFont: AinkradFontToken(role: "body"),
            bodyColor: .palette("foreground", 0.9),
            closeFont: AinkradFontToken(size: 9, weight: "bold", scaled: false),
            closeColor: .palette("foreground", 0.5),
            minWidth: 220, maxWidth: 340,
            shape: AinkradShapeToken(style: "chamfer", cut: 8),
            fill: .palette("surfaceElevated", 0.92),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .tint(0.6)), width: AinkradStateDouble(rest: 1.25)),
            glow: AinkradGlowToken(color: AinkradStateColor(rest: .tint(0.4)), radius: AinkradStateDouble(rest: 6))
        ),
        banner: BannerTokens(
            iconFont: AinkradFontToken(size: 14, weight: "semibold", scaled: false),
            bodyFont: AinkradFontToken(role: "body"),
            bodyColor: .palette("foreground", 0.9),
            closeFont: AinkradFontToken(size: 10, weight: "bold", scaled: false),
            closeColor: .palette("foreground", 0.5),
            shape: AinkradShapeToken(style: "chamfer", cut: 8),
            fill: .tint(0.12),
            stroke: AinkradStrokeToken(color: AinkradStateColor(rest: .tint(0.5)), width: AinkradStateDouble(rest: 1.25))
        )
    )
    }
}
