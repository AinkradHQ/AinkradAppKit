// design-lint: allow-file radius-literal theme layer — the radius scale the tokens resolve to
import CoreGraphics
import SwiftUI
import AinkradAppKitContract

/// Theme-invariant layout, motion, and type scales shared by the host and all
/// plugins. These do NOT vary by theme, so they are standalone constants rather
/// than fields on the per-theme `HostThemeTokens`. See
/// WorkShop/Ainkrad/04 Planning/Milestone 6 — Refinement Plan.

/// 4-pt spacing ramp. Use instead of raw `.padding(_:)` literals.
public enum AinkradSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

/// Corner-radius steps. `panel` is the standard overlay/HUD radius.
public enum AinkradRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 14
    public static let panel: CGFloat = 14
}

/// A drop-shadow specification. `.clear`/`0` is a no-op.
public struct ShadowSpec: Equatable, Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color; self.radius = radius; self.x = x; self.y = y
    }
}

/// Neutral elevation shadows by surface level. Accent glow is a separate
/// concern handled with the shared components (Slice 1b).
public enum AinkradElevation {
    public static let level0 = ShadowSpec(color: .clear, radius: 0, x: 0, y: 0)
    public static let level1 = ShadowSpec(color: .black.opacity(0.22), radius: 8, x: 0, y: 2)
    public static let level2 = ShadowSpec(color: .black.opacity(0.30), radius: 20, x: 0, y: 8)
}

/// Motion durations + named animations. Use instead of literal `.animation`
/// durations so timing is consistent across surfaces.
public enum AinkradMotion {
    public static let durationFast: Double = 0.15
    public static let durationBase: Double = 0.25
    public static let durationSlow: Double = 0.40
    /// Duration of the SAO-style materialize/dematerialize (scan-in) transition.
    public static let durationMaterialize: Double = 0.55

    public static var hover: Animation { .easeInOut(duration: durationFast) }
    public static var present: Animation { .easeOut(duration: durationBase) }
    public static var dismiss: Animation { .easeIn(duration: durationFast) }
    /// The materialize transition animation (scan-in on appear).
    public static var materialize: Animation { .easeOut(duration: durationMaterialize) }
}

/// Named typography roles with base point sizes. The host's `AinkradFont`
/// applies the user's font scale/family on top of these.
public enum AinkradTypeRole: CaseIterable {
    case display, title, headline, body, caption, mono

    public var size: CGFloat {
        switch self {
        case .display:  return 28
        case .title:    return 20
        case .headline: return 16
        case .body:     return 14
        case .caption:  return 11
        case .mono:     return 13
        }
    }
}
