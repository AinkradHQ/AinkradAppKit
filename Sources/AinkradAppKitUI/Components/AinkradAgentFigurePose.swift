import Foundation

// The orb's motion, ported number for number from the approved prototype
// (Designs/citadel/figures/orb.js + core.js). Pure: no SwiftUI, so every
// state's pose and the state clock are unit-testable. Units are the
// prototype's 100 × 100 viewBox centred on the origin, y down.

let figureTau = Double.pi * 2

func figureClamp(_ v: Double, _ lo: Double = 0, _ hi: Double = 1) -> Double { max(lo, min(hi, v)) }
func figureLerp(_ a: Double, _ b: Double, _ k: Double) -> Double { a + (b - a) * k }
func figureEaseOut(_ k: Double) -> Double { 1 - pow(1 - figureClamp(k), 3) }
func figureEaseInOut(_ k: Double) -> Double {
    let k = figureClamp(k)
    return k < 0.5 ? 4 * k * k * k : 1 - pow(-2 * k + 2, 3) / 2
}
func figureWave(_ t: Double, _ period: Double) -> Double { sin(figureTau * t / period) }
/// The prototype's `hash`: a stable pseudo-random number in `0..<1`.
func figureHash(_ n: Double) -> Double {
    let s = sin(n * 127.1 + 311.7) * 43758.5453
    return s - floor(s)
}
/// `a % b` that never goes negative.
func figureMod(_ a: Double, _ b: Double) -> Double { a - b * floor(a / b) }

/// Saccade gaze: hold a random target per slot, jump to the next in ~0.18 s.
func figureSaccade(_ t: Double, period: Double, seed: Double, spread: Double) -> (x: Double, y: Double) {
    let i = floor(t / period)
    let u = (t - i * period) / 0.18
    func target(_ k: Double) -> (Double, Double) {
        ((figureHash(k + seed) - 0.5) * 2 * spread, (figureHash(k * 1.7 + seed) - 0.5) * spread)
    }
    let a = target(i - 1)
    let b = target(i)
    let k = figureEaseOut(u)
    return (figureLerp(a.0, b.0, k), figureLerp(a.1, b.1, k))
}

/// Blink: a 140 ms closure every 3.6–6 s, sometimes doubled. 0 open … 1 shut.
func figureBlink(_ t: Double, seed: Double) -> Double {
    let period = 3.6 + figureHash(seed) * 2.4
    let i = floor(t / period)
    let u = t - i * period
    func one(_ s: Double) -> Double { s >= 0 && s < 0.14 ? sin(Double.pi * s / 0.14) : 0 }
    return max(one(u), figureHash(i + seed) > 0.75 ? one(u - 0.26) : 0)
}

/// Where the figure looks: `x`/`y` in −1…1 (y up), `weight` 0…1.
struct FigureLook: Equatable {
    var x = 0.0, y = 0.0, weight = 0.0
}

/// Everything one frame of the orb needs. Every field blends linearly during
/// the 280 ms state morph.
struct FigurePose: Equatable {
    var scale = 1.0, r = 31.0, w2 = 0.025, w3 = 0.018, w5 = 0.008
    var spin = 0.0, swirlR = 9.0, haloO = 0.35, haloR = 1.0, dim = 0.0
    var rimO = 0.0, rimA = 0.0, cometO = 0.0, cometA = 0.0, rippleO = 0.0, orbitO = 0.0
    var burst = 0.0, burstO = 0.0
    var ew = 5.0, eh = 10.0, ex = 7.5, eLs = 1.0, eRs = 1.0, happy = 0.0, closed = 0.0
    var gx = 0.0, gy = 0.0, follow = 0.8
    var zO = 0.0, sparkO = 0.0, qO = 0.0

    // Immutable; key paths just are not marked Sendable.
    nonisolated(unsafe) static let fields: [WritableKeyPath<FigurePose, Double>] = [
        \.scale, \.r, \.w2, \.w3, \.w5, \.spin, \.swirlR, \.haloO, \.haloR, \.dim, \.rimO, \.rimA, \.cometO,
        \.cometA, \.rippleO, \.orbitO, \.burst, \.burstO, \.ew, \.eh, \.ex, \.eLs, \.eRs, \.happy, \.closed,
        \.gx, \.gy, \.follow, \.zO, \.sparkO, \.qO,
    ]

    func blended(to target: FigurePose, _ k: Double) -> FigurePose {
        var out = target
        for f in Self.fields { out[keyPath: f] = figureLerp(self[keyPath: f], target[keyPath: f], k) }
        return out
    }

    /// The pose of `state` at state-local time `t`. `small` is the 20–24 / 16 px
    /// simplification; `level` (0…1) drives listening, `nil` simulates one.
    static func make(
        _ state: AinkradFigureState, t: Double, seed: Double, still: Bool, small: Bool, look: FigureLook,
        level: Double? = nil
    ) -> FigurePose {
        var p = FigurePose()
        p.spin = t * 30
        let bl = still ? 0 : figureBlink(t, seed: seed)
        func breathe(_ period: Double, _ amount: Double) { p.scale = 1 + amount * figureWave(t, period) }
        switch state.pose {
        case .rest:
            breathe(5, 0.01)
            (p.w2, p.w3, p.spin, p.dim, p.haloO, p.eh, p.follow, p.gy) = (0.008, 0.006, t * 6, 0.3, 0.12, 3, 0, -0.3)
        case .idle:
            breathe(3.2, 0.025)
            let wander = figureSaccade(t, period: 2.8, seed: seed, spread: 0.35)
            (p.spin, p.gx, p.gy) = (t * 18, wander.x, wander.y)
        case .listening:
            let lvl = level.map { figureClamp($0) } ?? 0.5 + 0.5 * abs(sin(t * 7.1) * sin(t * 2.3 + 1))
            (p.scale, p.w2, p.w3, p.w5) = (1 + 0.05 * lvl, 0.02 + 0.03 * lvl, 0.03 * lvl, 0.02 * lvl)
            (p.spin, p.haloO, p.rippleO, p.eh, p.ew, p.follow, p.gx) = (t * 40, 0.35 + 0.3 * lvl, 1, 12, 5.5, 1, 0.2)
        case .thinking:
            breathe(2.8, 0.015)
            (p.r, p.spin, p.swirlR, p.orbitO, p.haloO) = (28, t * 12, 5, 1, 0.25)
            (p.gx, p.gy, p.eLs, p.follow) = (0.5, 0.7, 0.9, 0.15)
        case .working:
            breathe(1.2, 0.012)
            (p.spin, p.swirlR, p.rimO, p.rimA, p.haloO) = (t * 150, 13, 0.55, figureMod(t * 200, 360), 0.45)
            (p.eh, p.ew, p.gy, p.follow) = (5, 6, -0.5, 0.1)
        case .success:
            // One hop: 0.6 s bloom + 1.1 s ring burst, then it holds until the
            // figure settles back to idle at 3 s (`FigureClock`).
            let u = figureClamp(t / 2)
            let pop = u < 0.3 ? sin(Double.pi * u / 0.3) : 0
            (p.scale, p.haloO, p.burst, p.burstO) = (1 + 0.12 * pop, 0.35 + 0.4 * pop, u, u < 0.55 ? 1 - u / 0.55 : 0)
            (p.happy, p.ew, p.spin, p.sparkO, p.follow) = (1, 6, t * 60, 1, 0.4)
        case .confused, .error:
            let j: Double = sin(t * 3.1) > 0.6 ? 1 : 0  // a hitch: two lumps, held, then released
            (p.w2, p.w3, p.w5, p.spin, p.dim) = (0.06 * j + 0.02, 0.045, 0.01, t * 10 + j * 40, 0.12)
            (p.eLs, p.eRs, p.gx, p.qO, p.follow) = (1.15, 0.7, sin(t * 1.3) > 0 ? 0.5 : -0.5, 1, 0.3)
        case .sleepy:
            breathe(6, 0.035)
            (p.w2, p.w3, p.spin, p.dim, p.haloO) = (0.01, 0.008, t * 3, 0.42, 0.1)
            (p.closed, p.zO, p.follow) = (1, 1, 0)
        case .loading:
            let lap = floor(t / 1.4) + figureEaseInOut(figureMod(t, 1.4) / 1.4)
            (p.r, p.dim, p.haloO, p.cometO, p.cometA, p.spin) = (27, 0.3, 0.15, 1, lap * 360, t * 20)
            (p.ew, p.eh, p.follow) = (4, 4, 0)
            (p.gx, p.gy) = (cos(figureTau * lap) * 0.5, -sin(figureTau * lap) * 0.4)
        }
        p.eh *= 1 - bl
        let w = look.weight * p.follow
        p.gx = figureLerp(p.gx, look.x, w)
        p.gy = figureLerp(p.gy, look.y, w)
        if small {
            (p.w2, p.w3, p.w5, p.r, p.scale) = (0, 0, 0, 34, 1)
            p.ew *= 1.3
            p.eh = max(3.5, p.eh * 1.3)
            (p.cometO, p.rimO) = (0, 0)
        }
        return p
    }
}

/// When the state changed and what it changed from — enough to replay the
/// 280 ms morph and the success → idle return without per-frame storage.
struct FigureClock: Equatable {
    var state: AinkradFigureState
    /// When `state` began (seconds, any epoch shared with the frame time).
    var since: Double
    var previous: AinkradFigureState?
    var previousSince = 0.0

    static let morph = 0.28
    /// How long `success` shows before the figure returns to idle.
    static let successHold = 3.0

    /// `success` turns into `idle` after `successHold`, morphing like any change.
    func resolved(at now: Double) -> FigureClock {
        guard state == .success, now - since >= Self.successHold else { return self }
        return FigureClock(state: .idle, since: since + Self.successHold, previous: .success, previousSince: since)
    }

    /// State-local time: success and loading start at 0 so the hop and the
    /// first lap play from the top; everything else carries the per-figure
    /// phase so a board never breathes in sync.
    static func localTime(_ state: AinkradFigureState, since: Double, now: Double, phase: Double) -> Double {
        now - since + (state == .success || state.pose == .loading ? 0 : phase)
    }

    /// The pose at `now`, morphing (cubic ease-out) out of the previous state.
    func pose(at now: Double, phase: Double, seed: Double, small: Bool, look: FigureLook, level: Double?) -> FigurePose
    {
        let c = resolved(at: now)
        let target = FigurePose.make(
            c.state, t: Self.localTime(c.state, since: c.since, now: now, phase: phase), seed: seed, still: false,
            small: small, look: look, level: level)
        let k = figureEaseOut((now - c.since) / Self.morph)
        guard let prev = c.previous, k < 1 else { return target }
        let from = FigurePose.make(
            prev, t: Self.localTime(prev, since: c.previousSince, now: c.since, phase: phase), seed: seed,
            still: false, small: small, look: look, level: level)
        return from.blended(to: target, k)
    }
}
