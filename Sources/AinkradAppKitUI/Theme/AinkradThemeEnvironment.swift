import SwiftUI
import AinkradAppKitContract

/// Typography context injected alongside the theme: an optional brand font
/// family (nil = system) and the user's UI font scale.
public struct AinkradTypography: Equatable, Sendable {
    public var fontFamilyName: String?
    public var scale: CGFloat
    public init(fontFamilyName: String? = nil, scale: CGFloat = 1.0) {
        self.fontFamilyName = fontFamilyName
        self.scale = scale
    }
    public static let `default` = AinkradTypography()
}

public extension EnvironmentValues {
    /// The resolved host theme colors. Host/plugins set this at their root;
    /// SDK components read it. Default is a neutral dark fallback so previews
    /// and un-hosted use still render.
    @Entry var ainkradTheme: HostThemeTokens = .fallbackDark
    @Entry var ainkradTypography: AinkradTypography = .default
    /// AINKRAD-controlled motion preference, independent of the macOS
    /// system-level "Reduce Motion" toggle. Default false = full motion.
    /// Host/plugins set this at their root; SDK components read this
    /// instead of the platform accessibility environment value.
    @Entry var ainkradReduceMotion: Bool = false
    /// How fast decorative motion may run right now — see `AinkradMotionBudget`.
    /// Default `.full` so previews and un-hosted components animate normally.
    /// The host installs a live source once with `.ainkradMotionBudgetSource()`.
    @Entry var ainkradMotionBudget: AinkradMotionBudget = .full
    /// The user's overlay-translucency preference, as an override for the
    /// background opacity a panel asks for.
    ///
    /// `nil` — the default — means "whatever the call site chose", so an
    /// un-hosted preview and any panel with a deliberate opacity keep looking
    /// exactly as they did. The host sets this once at its root from
    /// Settings → Appearance → Overlays, which is how a HUD surface anywhere
    /// in the app (or in a plugin) starts obeying that slider without every
    /// call site having to thread it through.
    @Entry var ainkradSurfaceOpacity: Double? = nil
    /// Whether HUD surfaces blur what is behind them. Host-driven, same
    /// source as `ainkradSurfaceOpacity`; default true = blur, which is the
    /// behaviour every surface had before this existed.
    @Entry var ainkradSurfaceBlur: Bool = true
}


public extension HostThemeTokens {
    /// Neutral dark fallback for previews / when no host injects a theme.
    static let fallbackDark = HostThemeTokens(
        themeID: "fallback",
        background: Color(red: 0.04, green: 0.05, blue: 0.09),
        surface: Color(red: 0.07, green: 0.09, blue: 0.15),
        surfaceElevated: Color(red: 0.10, green: 0.13, blue: 0.20),
        accentPrimary: Color(red: 0.15, green: 0.39, blue: 0.92),
        accentSecondary: Color(red: 0.13, green: 0.83, blue: 0.93),
        accentTertiary: Color(red: 0.06, green: 0.73, blue: 0.51),
        foreground: Color(red: 0.89, green: 0.91, blue: 0.94)
    )
}
