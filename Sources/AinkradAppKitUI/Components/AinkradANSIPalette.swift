import AinkradAppKitContract
import SwiftUI

/// Maps the 16 ANSI slots `AinkradANSIParser` emits **through the host theme**,
/// so a log pane follows the user's colours like every other Ainkrad surface.
///
/// Slots 1/9 (red) and 3/11 (yellow) come from the status colours the rest of
/// the app already uses for danger and warning, so an error line in a log is
/// the same red as an error badge beside it. The rest are derived from theme
/// tokens rather than picked, which is what keeps a log from looking like a
/// terminal someone pasted in.
///
/// Moved here from Thrall's `ThrallANSIPalette`, unchanged in mapping.
public struct AinkradANSIPalette: Sendable {
    let colors: [Color]

    /// Builds the 16 slots from a skin's `components.logView.ansiSlots`,
    /// resolved against that skin, so a log pane follows the active skin.
    public init(skin: AinkradSkin) {
        colors = skin.components.logView.ansiSlots.map { skin.color($0) }
    }

    public init(theme: HostThemeTokens, statusColors: AinkradStatusColors) {
        let standardOpacity = AinkradSkin.standard.opacity
        let foreground = theme.foreground
        let danger = AinkradStatus.danger.color(in: theme, statusColors: statusColors)
        let warning = AinkradStatus.warning.color(in: theme, statusColors: statusColors)
        let success = AinkradStatus.success.color(in: theme, statusColors: statusColors)
        colors = [
            foreground.opacity(standardOpacity.o45),  // 0 black -> dimmed foreground
            danger,  // 1 red
            success,  // 2 green
            warning,  // 3 yellow
            theme.accentPrimary,  // 4 blue
            theme.accentSecondary,  // 5 magenta
            theme.accentPrimary.opacity(standardOpacity.o80),  // 6 cyan
            foreground,  // 7 white
            foreground.opacity(standardOpacity.o60),  // 8 bright black
            danger,  // 9
            success,  // 10
            warning,  // 11
            theme.accentPrimary,  // 12
            theme.accentSecondary,  // 13
            theme.accentPrimary.opacity(standardOpacity.o90),  // 14
            foreground,  // 15
        ]
    }

    /// The colour for `slot`, or `fallback` for no slot or one outside 0–15.
    public func color(slot: Int?, default fallback: Color) -> Color {
        guard let slot, slot >= 0, slot < colors.count else { return fallback }
        return colors[slot]
    }
}
