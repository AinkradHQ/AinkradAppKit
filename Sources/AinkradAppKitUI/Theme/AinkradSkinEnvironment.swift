import AinkradAppKitContract
import AppKit
import SwiftUI

extension EnvironmentValues {
    /// The stored skin. Set via `.ainkradSkin(_:)`; forwarded across the
    /// `NSPanel` boundary by hand (see `AinkradFloatingPanelModifier` and
    /// `ainkradMenuEnvironment`), because SwiftUI's environment does not cross
    /// a window boundary on its own.
    @Entry public var ainkradSkinStorage: AinkradSkin = .standard

    /// The effective skin: the stored skin overlaid with the legacy theme and
    /// status-colour keys, which stay authoritative for the 11 colours they
    /// carry so already-installed plugins and the Gallery's subtree theme
    /// overrides keep recolouring kit components exactly as before.
    public var ainkradSkin: AinkradSkin {
        var skin = ainkradSkinStorage
        skin.palette = overlaidSkinPalette(
            base: skin.palette, theme: ainkradTheme, status: ainkradStatusColors)
        return skin
    }
}

extension View {
    /// Installs `skin` as the stored skin and derives the legacy
    /// `ainkradTheme` / `ainkradStatusColors` keys from it, so readers of
    /// either the new or the old keys see one consistent theme.
    public func ainkradSkin(_ skin: AinkradSkin) -> some View {
        modifier(AinkradSkinModifier(skin: skin))
    }
}

/// Carries the skin and its derived legacy keys into the environment.
private struct AinkradSkinModifier: ViewModifier {
    /// The skin to install.
    let skin: AinkradSkin

    func body(content: Content) -> some View {
        content
            .environment(\.ainkradSkinStorage, skin)
            .environment(\.ainkradTheme, HostThemeTokens(skin: skin))
            .environment(\.ainkradStatusColors, AinkradStatusColors(skin: skin))
    }
}

extension HostThemeTokens {
    /// Derives the legacy theme tokens from a skin. `themeID` is the skin's
    /// id, because Rune keys its terminal palette on `themeID`.
    public init(skin: AinkradSkin) {
        self.init(
            themeID: skin.id,
            background: skinBaseColor(skin.palette.background, in: skin.palette),
            surface: skinBaseColor(skin.palette.surface, in: skin.palette),
            surfaceElevated: skinBaseColor(skin.palette.surfaceElevated, in: skin.palette),
            accentPrimary: skinBaseColor(skin.palette.accentPrimary, in: skin.palette),
            accentSecondary: skinBaseColor(skin.palette.accentSecondary, in: skin.palette),
            accentTertiary: skinBaseColor(skin.palette.accentTertiary, in: skin.palette),
            foreground: skinBaseColor(skin.palette.foreground, in: skin.palette)
        )
    }
}

extension AinkradStatusColors {
    /// Derives the status colours from a skin's palette.
    public init(skin: AinkradSkin) {
        self.init(
            success: skinBaseColor(skin.palette.success, in: skin.palette),
            warning: skinBaseColor(skin.palette.warning, in: skin.palette),
            danger: skinBaseColor(skin.palette.danger, in: skin.palette)
        )
    }
}

// MARK: - File-scope helpers

/// Overlays the legacy keys onto a stored palette: the seven theme colours
/// come from `ainkradTheme`, the three status colours from
/// `ainkradStatusColors`. `black`/`white` stay as stored.
func overlaidSkinPalette(
    base: AinkradSkinPalette, theme: HostThemeTokens, status: AinkradStatusColors
) -> AinkradSkinPalette {
    AinkradSkinPalette(
        background: skinColorToken(from: theme.background),
        surface: skinColorToken(from: theme.surface),
        surfaceElevated: skinColorToken(from: theme.surfaceElevated),
        accentPrimary: skinColorToken(from: theme.accentPrimary),
        accentSecondary: skinColorToken(from: theme.accentSecondary),
        accentTertiary: skinColorToken(from: theme.accentTertiary),
        foreground: skinColorToken(from: theme.foreground),
        success: skinColorToken(from: status.success),
        warning: skinColorToken(from: status.warning),
        danger: skinColorToken(from: status.danger),
        black: base.black,
        white: base.white
    )
}

/// Encodes a `Color` as a literal-hex palette token via its sRGB components.
/// A colour outside the sRGB space falls back to opaque black rather than
/// trapping: theme data must never crash a render.
func skinColorToken(from color: Color) -> AinkradColorToken {
    let nsColor = NSColor(color)
    guard let rgb = nsColor.usingColorSpace(.sRGB) else {
        return .hex(0, 0, 0, 1)
    }
    return .hex(
        Double(rgb.redComponent),
        Double(rgb.greenComponent),
        Double(rgb.blueComponent),
        Double(rgb.alphaComponent)
    )
}

/// Resolves a palette entry to a `Color`. Palette entries are literal hex by
/// contract; the other cases are degenerate there, resolved one level only so
/// a self-referential entry can never recurse.
func skinBaseColor(_ token: AinkradColorToken, in palette: AinkradSkinPalette) -> Color {
    switch token {
    case .hex(let red, let green, let blue, let alpha):
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    case .clear:
        return .clear
    case .tint(let alpha):
        let base: Color
        if case .hex(let red, let green, let blue, _) = palette.accentPrimary {
            base = Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
        } else {
            base = .clear
        }
        return alpha == 1.0 ? base : base.opacity(alpha)
    case .palette(let key, let alpha):
        let referenced: AinkradColorToken
        switch key {
        case "background": referenced = palette.background
        case "surface": referenced = palette.surface
        case "surfaceElevated": referenced = palette.surfaceElevated
        case "accentPrimary": referenced = palette.accentPrimary
        case "accentSecondary": referenced = palette.accentSecondary
        case "accentTertiary": referenced = palette.accentTertiary
        case "foreground": referenced = palette.foreground
        case "success": referenced = palette.success
        case "warning": referenced = palette.warning
        case "danger": referenced = palette.danger
        case "black": referenced = palette.black
        case "white": referenced = palette.white
        default: referenced = palette.foreground
        }
        guard case .hex(let red, let green, let blue, _) = referenced else {
            return .clear
        }
        let base = Color(.sRGB, red: red, green: green, blue: blue, opacity: 1)
        return alpha == 1.0 ? base : base.opacity(alpha)
    }
}
