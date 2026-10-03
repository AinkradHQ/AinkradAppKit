import CoreGraphics

/// The single source of truth for settings geometry. The later
/// user-resizable pass edits these, not thirty call sites.
public enum SettingsMetrics {
    public static var panelMinWidth: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.panelMinWidth) }
    public static var panelMaxWidth: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.panelMaxWidth) }
    public static var panelWidthFraction: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.widthFraction) }
    public static var panelMinHeight: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.panelMinHeight) }
    public static var panelMaxHeight: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.panelMaxHeight) }
    public static var panelHeightFraction: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.heightFraction) }
    public static var panelYOffset: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.yOffset) }

    public static var sidebarWidth: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.sidebarWidth) }
    public static var controlColumnWidth: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.controlColumnWidth) }

    /// Below this the mini-map is hidden.
    public static var miniMapBreakpoint: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.miniMapBreakpoint) }
    /// Above this rows lay out side-by-side on a shared control rail.
    public static var wideBreakpoint: CGFloat { CGFloat(AinkradSkin.standardSettingsMetrics.wideBreakpoint) }
}
