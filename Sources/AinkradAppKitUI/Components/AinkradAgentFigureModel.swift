// design-lint: allow-file hex-color,raw-color the approved figure palettes, harness marks and state cues (Designs/citadel/figures/core.js, decision #63)
import SwiftUI

/// What an agent is doing, as the figure shows it (Citadel decision #61/#63).
public enum AinkradFigureState: String, CaseIterable, Sendable {
    case rest, idle, listening, thinking, working, success, confused, sleepy, loading
    /// A hard error: the confused pose with a red status dot (decision #63).
    /// `confused` itself is the amber "stalled / blocked" signal.
    case error

    /// The VoiceOver word for the state.
    public var spokenName: String {
        switch self {
        case .rest: "resting"
        case .idle: "idle"
        case .listening: "listening"
        case .thinking: "thinking"
        case .working: "working"
        case .success: "done"
        case .confused: "needs attention"
        case .sleepy: "asleep"
        case .loading: "starting"
        case .error: "error"
        }
    }

    /// The pose the figure takes: `error` looks like `confused`.
    var pose: AinkradFigureState { self == .error ? .confused : self }

    /// The status-dot colour — the one cue identical at every size.
    var cue: UInt32 {
        switch self {
        case .rest: 0x64748b
        case .idle: 0x94a3b8
        case .listening: 0x2dd4bf  // teal, so it differs from working's cyan at 16 px (decision #63)
        case .thinking: 0xa855f7
        case .working: 0x22d3ee
        case .success: 0x3fb950
        case .confused: 0xe3b341
        case .sleepy: 0x475569
        case .loading: 0x2563eb
        case .error: 0xf85149
        }
    }

    /// The frame every animated state freezes on (Reduce Motion, 20–24 px).
    var keyTime: Double {
        switch pose {
        case .rest: 0
        case .idle: 0.8
        case .listening: 0.4
        case .thinking: 0.45
        case .working: 0.3
        case .success: 0.22
        case .confused: 0.4
        case .sleepy: 0.5
        default: 0.7
        }
    }
}

/// A two-stop figure palette: `light` sits top-left, `deep` bottom-right.
/// Chosen once per agent and stored by `id` — never derived at render time.
public struct AinkradFigurePalette: Hashable, Sendable, Identifiable {
    public let id: String
    public let name: String
    let light: UInt32
    let deep: UInt32

    init(_ id: String, _ name: String, _ light: UInt32, _ deep: UInt32) {
        self.id = id
        self.name = name
        self.light = light
        self.deep = deep
    }

    public var lightColor: Color { figureColor(light) }
    public var deepColor: Color { figureColor(deep) }

    public static let neonTide = Self("neon-tide", "Neon Tide", 0x22d3ee, 0x2563eb)
    public static let aurora = Self("aurora", "Aurora", 0x6ee7b7, 0x10b981)
    public static let ultraviolet = Self("ultraviolet", "Ultraviolet", 0xc084fc, 0x4f46e5)
    public static let glacier = Self("glacier", "Glacier", 0xe0f2fe, 0x38bdf8)
    public static let ember = Self("ember", "Ember", 0xfbbf24, 0xf43f5e)
    public static let orchid = Self("orchid", "Orchid", 0xf0abfc, 0xa855f7)
    public static let lagoon = Self("lagoon", "Lagoon", 0x5eead4, 0x0e7490)
    public static let citrine = Self("citrine", "Citrine", 0xfde68a, 0xe3b341)
    public static let coral = Self("coral", "Coral", 0xfda4af, 0xf85149)
    public static let jade = Self("jade", "Jade", 0x86efac, 0x15803d)
    public static let abyss = Self("abyss", "Abyss", 0x22d3ee, 0x1e1b4b)
    public static let dusk = Self("dusk", "Dusk", 0xfdba74, 0x7c3aed)
    public static let copper = Self("copper", "Copper", 0xfed7aa, 0xc2410c)
    public static let limeCircuit = Self("lime-circuit", "Lime Circuit", 0xd9f99d, 0x10b981)
    public static let sakura = Self("sakura", "Sakura", 0xfce7f3, 0xec4899)
    public static let cobalt = Self("cobalt", "Cobalt", 0x93c5fd, 0x1d4ed8)
    public static let steel = Self("steel", "Steel", 0xe2e8f0, 0x64748b)
    /// Paused or terminated agents.
    public static let muted = Self("muted", "Muted", 0xa6aaad, 0x44464a)

    /// The 17 selectable palettes, in picker order (Muted is separate).
    public static let all: [Self] = [
        neonTide, aurora, ultraviolet, glacier, ember, orchid, lagoon, citrine, coral, jade, abyss, dusk, copper,
        limeCircuit, sakura, cobalt, steel,
    ]

    /// The palette stored under `id`, or `nil` for an unknown id.
    public static func named(_ id: String) -> Self? { (all + [muted]).first { $0.id == id } }
}

/// The harness an agent runs on, shown as a coloured arc at the lower left.
public struct AinkradFigureHarness: Hashable, Sendable {
    public let name: String
    let rgb: UInt32

    init(_ name: String, _ rgb: UInt32) {
        self.name = name
        self.rgb = rgb
    }

    public var color: Color { figureColor(rgb) }

    public static let claude = Self("Claude", 0xcc785c)
    public static let codex = Self("Codex", 0xcbd5e1)
    public static let openCode = Self("OpenCode", 0x10b981)
    public static let agy = Self("agy", 0x3b82f6)
}

/// How much of the figure a size draws and how often it moves.
enum AinkradFigureTier: Equatable {
    /// ≥ 64: every layer, cursor gaze.
    case full
    /// 32–48: every layer, ~15 fps; full rate on hover.
    case ambient
    /// 20–24: the key frame, simplified.
    case still
    /// 16: still body + status dot, no harness mark.
    case glyph

    init(size: CGFloat) {
        self = size >= 64 ? .full : size >= 32 ? .ambient : size >= 20 ? .still : .glyph
    }

    var animates: Bool { self == .full || self == .ambient }
}

func figureColor(_ rgb: UInt32, opacity: Double = 1) -> Color {
    Color(
        .sRGB, red: Double((rgb >> 16) & 0xff) / 255, green: Double((rgb >> 8) & 0xff) / 255,
        blue: Double(rgb & 0xff) / 255, opacity: opacity)
}

/// `a` mixed toward `b` by `k`, channel by channel (the prototype's `mixHex`).
func figureMix(_ a: UInt32, _ b: UInt32, _ k: Double) -> UInt32 {
    [16, 8, 0].reduce(UInt32(0)) { acc, shift in
        let x = Double((a >> shift) & 0xff)
        let y = Double((b >> shift) & 0xff)
        return acc | (UInt32((x + (y - x) * k).rounded()) << shift)
    }
}
