import AinkradAppKitContract
// design-lint: allow-file radius-literal theme layer — the radius scale the tokens resolve to
import CoreGraphics
import SwiftUI

/// Theme-invariant layout, motion, and type scales shared by the host and all
/// plugins. These do NOT vary by theme, so they are standalone constants rather
/// than fields on the per-theme `HostThemeTokens`. See
/// WorkShop/Ainkrad/04 Planning/Milestone 6 — Refinement Plan.

/// 4-pt spacing ramp. Use instead of raw `.padding(_:)` literals.
public enum AinkradSpacing {
    public static var xs: CGFloat { CGFloat(AinkradSkin.standardSpacing.xs) }
    public static var sm: CGFloat { CGFloat(AinkradSkin.standardSpacing.sm) }
    public static var md: CGFloat { CGFloat(AinkradSkin.standardSpacing.md) }
    public static var lg: CGFloat { CGFloat(AinkradSkin.standardSpacing.lg) }
    public static var xl: CGFloat { CGFloat(AinkradSkin.standardSpacing.xl) }
    public static var xxl: CGFloat { CGFloat(AinkradSkin.standardSpacing.xxl) }
}

/// Corner-radius steps. `panel` is the standard overlay/HUD radius.
public enum AinkradRadius {
    public static var sm: CGFloat { CGFloat(AinkradSkin.standardRadius.sm) }
    public static var md: CGFloat { CGFloat(AinkradSkin.standardRadius.md) }
    public static var lg: CGFloat { CGFloat(AinkradSkin.standardRadius.lg) }
    public static var panel: CGFloat { CGFloat(AinkradSkin.standardRadius.panel) }
}

/// A drop-shadow specification. `.clear`/`0` is a no-op.
public struct ShadowSpec: Equatable, Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

extension AinkradShadowToken {
    public var spec: ShadowSpec {
        ShadowSpec(color: AinkradSkin.standard.color(color), radius: CGFloat(radius), x: CGFloat(x), y: CGFloat(y))
    }
}

/// Neutral elevation shadows by surface level. Accent glow is a separate
/// concern handled with the shared components (Slice 1b).
public enum AinkradElevation {
    public static var level0: ShadowSpec { AinkradSkin.standardElevation.level0.spec }
    public static var level1: ShadowSpec { AinkradSkin.standardElevation.level1.spec }
    public static var level2: ShadowSpec { AinkradSkin.standardElevation.level2.spec }
}

/// Motion durations + named animations. Use instead of literal `.animation`
/// durations so timing is consistent across surfaces.
public enum AinkradMotion {
    public static var durationFast: Double { AinkradSkin.standardMotion.fast }
    public static var durationBase: Double { AinkradSkin.standardMotion.base }
    public static var durationSlow: Double { AinkradSkin.standardMotion.slow }
    /// Duration of the SAO-style materialize/dematerialize (scan-in) transition.
    public static var durationMaterialize: Double { AinkradSkin.standardMotion.materialize }

    public static var hover: Animation { AinkradSkin.standard.animation(AinkradSkin.standardMotion.hover) }
    public static var present: Animation { AinkradSkin.standard.animation(AinkradSkin.standardMotion.present) }
    public static var dismiss: Animation { AinkradSkin.standard.animation(AinkradSkin.standardMotion.dismiss) }
    /// The materialize transition animation (scan-in on appear).
    public static var materialize: Animation {
        AinkradSkin.standard.animation(AinkradSkin.standardMotion.materializeAnimation)
    }
}

/// Named typography roles with base point sizes. The host's `AinkradFont`
/// applies the user's font scale/family on top of these.
public enum AinkradTypeRole: CaseIterable {
    case display, title, headline, body, caption, mono

    public var size: CGFloat {
        switch self {
        case .display: return CGFloat(AinkradSkin.standardTypeRoles.display)
        case .title: return CGFloat(AinkradSkin.standardTypeRoles.title)
        case .headline: return CGFloat(AinkradSkin.standardTypeRoles.headline)
        case .body: return CGFloat(AinkradSkin.standardTypeRoles.body)
        case .caption: return CGFloat(AinkradSkin.standardTypeRoles.caption)
        case .mono: return CGFloat(AinkradSkin.standardTypeRoles.mono)
        }
    }
}
