import SwiftUI
import AinkradAppKitContract

/// Maps a type role to a Font, honoring an optional brand family + user scale.
/// Defaults to the system font when no family is injected (plugins without the
/// host's registered brand faces still render legibly).
public enum AinkradFontResolver {
    public static func pointSize(_ role: AinkradTypeRole, typography: AinkradTypography) -> CGFloat {
        role.size * typography.scale
    }
    public static func font(_ role: AinkradTypeRole, weight: Font.Weight = .regular,
                            typography: AinkradTypography) -> Font {
        let size = pointSize(role, typography: typography)
        if role == .mono {
            return .custom("JetBrains Mono", size: size).weight(weight)
        }
        if let family = typography.fontFamilyName {
            return .custom(family, size: size).weight(weight)
        }
        return .system(size: size).weight(weight)
    }
}

public extension AinkradFontResolver {
    /// Point size for an explicit size, scaled by the user's typography.
    ///
    /// The role ramp (`.caption`, `.body`, …) is the right default for a new
    /// surface, but some surfaces are tuned between its steps — the Signal feed
    /// uses 12.5/11.5/10/9.5, which sit between `.caption` (11), `.mono` (13)
    /// and `.body` (14). Rounding each to the nearest role would re-scale every
    /// label in it: a redesign disguised as a refactor, and invisible to any
    /// behavioural test. This exists so a component moved into the kit keeps
    /// its tuning.
    static func pointSize(_ size: CGFloat, typography: AinkradTypography) -> CGFloat {
        size * typography.scale
    }

    /// `mono: true` selects JetBrains Mono for readouts — timestamps, counts,
    /// identifiers. Otherwise the user's UI family, falling back to the system
    /// face: the same precedence the role-based overload uses.
    static func font(size: CGFloat, weight: Font.Weight = .regular,
                     mono: Bool = false, typography: AinkradTypography) -> Font {
        let resolved = pointSize(size, typography: typography)
        if mono { return .custom("JetBrains Mono", size: resolved).weight(weight) }
        if let family = typography.fontFamilyName {
            return .custom(family, size: resolved).weight(weight)
        }
        return .system(size: resolved).weight(weight)
    }
}
