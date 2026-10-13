import SwiftUI

/// The coding agents Forge and Grimoire tell apart, each with an identity
/// colour. Not a skin key on purpose: a new skin key needs a theme `format`
/// bump, and these are brand colours a theme has no business restyling. The
/// Neon/Glass split mirrors the mockups — Neon's light glow tints for text on
/// dark chamfers, Glass's solid brand hues for dots and pills on material.
public enum AinkradAgent: String, CaseIterable, Sendable {
    case claude, codex, opencode, agy, unknown

    /// Lenient match on a harness or CLI name ("Claude Code", "claude-code",
    /// "OpenCode", "antigravity"…). Anything else is `.unknown`.
    public init(identifier: String) {
        let key = identifier.lowercased().filter { $0.isLetter || $0.isNumber }
        if key.hasPrefix("claude") {
            self = .claude
        } else if key.hasPrefix("codex") {
            self = .codex
        } else if key.hasPrefix("opencode") {
            self = .opencode
        } else if key.hasPrefix("agy") || key.hasPrefix("antigravity") {
            self = .agy
        } else {
            self = .unknown
        }
    }

    /// The colour token for this agent. Pure, so it is unit-testable; views use
    /// `AinkradSkin.agentColor(_:)`. Codex and unknown follow the theme's
    /// foreground (Codex's identity is "the neutral one"; unknown is muted).
    public func colorToken(glass: Bool) -> AinkradColorToken {
        switch (self, glass) {
        case (.claude, false): .hex(0xE3 / 255.0, 0xA0 / 255.0, 0x7F / 255.0, 1.0)
        case (.claude, true): .hex(0xCC / 255.0, 0x78 / 255.0, 0x5C / 255.0, 1.0)
        case (.codex, false): .hex(0xCB / 255.0, 0xD5 / 255.0, 0xE1 / 255.0, 1.0)
        case (.codex, true): .palette("foreground", 0.85)
        case (.opencode, false): .hex(0xA7 / 255.0, 0xF3 / 255.0, 0xD0 / 255.0, 1.0)
        case (.opencode, true): .hex(0x10 / 255.0, 0xB9 / 255.0, 0x81 / 255.0, 1.0)
        case (.agy, false): .hex(0x93 / 255.0, 0xC5 / 255.0, 0xFD / 255.0, 1.0)
        case (.agy, true): .hex(0x3B / 255.0, 0x82 / 255.0, 0xF6 / 255.0, 1.0)
        case (.unknown, _): .palette("foreground", 0.55)
        }
    }
}

extension AinkradSkin {
    /// An agent's identity colour in this skin — Glass values when the skin
    /// renders native Glass, Neon values otherwise.
    public func agentColor(_ agent: AinkradAgent) -> Color {
        color(agent.colorToken(glass: usesNativeGlass))
    }
}
