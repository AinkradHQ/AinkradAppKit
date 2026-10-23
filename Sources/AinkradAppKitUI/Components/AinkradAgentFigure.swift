// design-lint: allow-file motion-literal the 150 ms Reduce Motion cross-fade the approved figure spec names (Designs/citadel/figures/page.js)
import AinkradAppKitContract
import AppKit
import SwiftUI

/// The animated agent figure — Citadel's "B · Orb" (decisions #61 and #63): a
/// living gradient orb whose surface, inner currents, halo and props show what
/// the agent is doing, with optional eyes that follow the cursor.
///
/// Size sets the detail and the frame rate:
/// - ≥ 64 pt — every layer and cursor gaze; 60 fps at 128 pt and up or while
///   hovered / `isActive`, otherwise ~15 fps.
/// - 32–48 pt — every layer (props from 48), ~15 fps; full rate on hover.
/// - 20–24 pt — the state's key frame, simplified, never animated.
/// - 16 pt — still body and status dot, no harness arc.
///
/// Motion obeys `AinkradMotionBudget`: frozen windows draw the key frame, an
/// inactive app pauses the clock, and the kit's Reduce Motion (`ainkradReduceMotion`,
/// like every kit component — not the system flag directly) freezes
/// every figure on its key frame with a 150 ms cross-fade between states.
/// Each figure carries a phase derived from `name`, so a board never breathes
/// in sync. `success` hops once and returns to idle after ~3 s on its own.
public struct AinkradAgentFigure: View {
    private let name: String
    private let state: AinkradFigureState
    private let palette: AinkradFigurePalette
    private let harness: AinkradFigureHarness?
    private let size: CGFloat
    private let showsEyes: Bool
    private let showsPlate: Bool
    private let isActive: Bool
    private let image: Image?
    private let listeningLevel: Double?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradMotionBudget) private var budget
    @Environment(\.ainkradReduceMotion) private var kitReduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    @State private var clock: FigureClock
    @State private var settled = false
    @State private var isHovering = false
    @State private var isOnScreen = true
    @State private var gaze = FigureGaze()

    /// - Parameters:
    ///   - name: the agent's name — the VoiceOver label and the phase seed.
    ///   - harness: the harness arc at the lower left; `nil` draws none.
    ///   - size: the figure's side in points.
    ///   - showsEyes: eyes are on by default (decision #63).
    ///   - showsPlate: the faint disc behind the orb that carries the harness arc.
    ///   - isActive: selected or on stage — runs at full rate and follows the cursor.
    ///   - image: an uploaded picture that replaces the orb; the arc and dot stay.
    ///   - listeningLevel: live input level (0…1) for `listening`; `nil` simulates one.
    public init(
        name: String, state: AinkradFigureState, palette: AinkradFigurePalette = .neonTide,
        harness: AinkradFigureHarness? = nil, size: CGFloat = 64, showsEyes: Bool = true, showsPlate: Bool = true,
        isActive: Bool = false, image: Image? = nil, listeningLevel: Double? = nil
    ) {
        self.name = name
        self.state = state
        self.palette = palette
        self.harness = harness
        self.size = size
        self.showsEyes = showsEyes
        self.showsPlate = showsPlate
        self.isActive = isActive
        self.image = image
        self.listeningLevel = listeningLevel
        _clock = State(initialValue: FigureClock(state: state, since: Date().timeIntervalSinceReferenceDate))
    }

    private var tier: AinkradFigureTier { AinkradFigureTier(size: size) }
    private var active: Bool { isActive || isHovering }
    private var seedNumber: Double { figureSeed(name) }
    private var phase: Double { figureHash(seedNumber) * 10 }
    private var seed: Double { seedNumber * 13.7 }
    /// The state as shown: `success` reads as idle once it has settled.
    private var shownState: AinkradFigureState { state == .success && settled ? .idle : state }

    private var isStill: Bool {
        !tier.animates || kitReduceMotion || budget.reduceMotion || !budget.isAnimating
    }

    /// Frame interval: 60 fps for the hero / hovered / selected figure while
    /// the budget runs at its normal rate, ~15 fps for the rest, never faster
    /// than a degraded budget allows.
    private var isFast: Bool { (tier == .full && (active || size >= 128)) || (tier == .ambient && active) }

    private var interval: Double {
        let allowed = budget.minimumInterval ?? 1
        if isFast { return allowed <= AinkradMotionBudget.full.minimumInterval ?? 0 ? 1.0 / 60 : allowed }
        return max(1.0 / 15, allowed)
    }

    public var body: some View {
        content
            .frame(width: size, height: size)
            .background(FigureGazeProbe(gaze: gaze))
            .onHover { isHovering = $0 }
            .modifier(FigureScrollVisibility(isOnScreen: $isOnScreen))
            .onChange(of: state) { _, newValue in
                let now = Date().timeIntervalSinceReferenceDate
                let current = clock.resolved(at: now)
                clock = FigureClock(state: newValue, since: now, previous: current.state, previousSince: current.since)
            }
            .task(id: state) {
                settled = false
                guard state == .success else { return }
                try? await Task.sleep(for: .seconds(FigureClock.successHold))
                if !Task.isCancelled { settled = true }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(name), \(shownState.spokenName)")
            .accessibilityAddTraits(.isImage)
    }

    @ViewBuilder private var content: some View {
        if isStill {
            canvas(stillScene)
                .id(shownState)
                .transition(.opacity)
                .animation(.linear(duration: 0.15), value: shownState)
        } else {
            let paused = !budget.isAppActive || !isOnScreen
            if isFast {
                TimelineView(.animation(minimumInterval: interval, paused: paused)) { tl in
                    canvas(liveScene(at: tl.date.timeIntervalSinceReferenceDate))
                }
            } else {
                // Ambient figures tick on one shared, wall-clock-aligned grid, so a
                // board of 100 wakes once per frame instead of 100 times.
                TimelineView(FigureAmbientSchedule(interval: interval, paused: paused)) { tl in
                    canvas(liveScene(at: tl.date.timeIntervalSinceReferenceDate))
                }
            }
        }
    }

    private func canvas(_ scene: FigureScene) -> some View {
        Canvas { ctx, canvasSize in scene.draw(&ctx, canvasSize) }
            .frame(width: size * FigureScene.overhang, height: size * FigureScene.overhang)
            .allowsHitTesting(false)
    }

    private var stillScene: FigureScene {
        let s = shownState
        let pose = FigurePose.make(
            s, t: s.keyTime, seed: seed, still: true, small: size <= 24, look: FigureLook(), level: listeningLevel)
        return scene(pose: pose, t: s.keyTime, dotTime: 0.35, state: s)
    }

    private func liveScene(at now: Double) -> FigureScene {
        let follows = tier == .full || active
        let look = gaze.update(now: now, follows: follows, size: size)
        let c = clock.resolved(at: now)
        let pose = clock.pose(at: now, phase: phase, seed: seed, small: size <= 24, look: look, level: listeningLevel)
        let t = FigureClock.localTime(c.state, since: c.since, now: now, phase: phase)
        return scene(pose: pose, t: t, dotTime: now, state: c.state == .idle && state == .success ? .idle : state)
    }

    private func scene(pose: FigurePose, t: Double, dotTime: Double, state: AinkradFigureState) -> FigureScene {
        FigureScene(
            pose: pose, t: t, dotTime: dotTime, state: state, size: size, palette: palette,
            harness: tier == .glyph ? nil : harness, showsEyes: showsEyes, showsPlate: showsPlate,
            glass: skin.usesNativeGlass, increasedContrast: contrast == .increased,
            dotOutline: skin.color(skin.text.primary), image: image)
    }
}

/// A stable number in 1…1000 from the agent's name (FNV-1a), the figure's
/// phase and blink seed.
func figureSeed(_ name: String) -> Double {
    var h: UInt32 = 2_166_136_261
    for byte in name.utf8 { h = (h ^ UInt32(byte)) &* 16_777_619 }
    return Double(h % 1000) + 1
}

/// Cursor gaze for one figure: reads the shared pointer through the figure's
/// own `NSView` (no hit-testing), eased with a ~100 ms time constant.
@MainActor
final class FigureGaze {
    weak var view: NSView?
    private var look = FigureLook()
    private var last: Double?

    func update(now: Double, follows: Bool, size: CGFloat) -> FigureLook {
        var target = FigureLook()
        if follows, let view, let window = view.window {
            let inWindow = window.mouseLocationOutsideOfEventStream
            if window.contentView?.bounds.contains(inWindow) ?? false {
                let p = view.convert(inWindow, from: nil)
                let n = max(80, size / 2)
                var tx = (p.x - view.bounds.midX) / n
                var ty = (p.y - view.bounds.midY) / n * (view.isFlipped ? -1 : 1)
                let len = max(1, hypot(tx, ty))
                tx /= len
                ty /= len
                target = FigureLook(x: tx, y: ty, weight: 1)
            }
        }
        let dt = min(max(now - (last ?? now), 0), 0.25)
        last = now
        let a = 1 - exp(-dt * 10)
        look = FigureLook(
            x: figureLerp(look.x, target.x, a), y: figureLerp(look.y, target.y, a),
            weight: figureLerp(look.weight, target.weight, a))
        return look
    }
}

private struct FigureGazeProbe: NSViewRepresentable {
    let gaze: FigureGaze

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        gaze.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) { gaze.view = nsView }
}

/// Pauses a figure scrolled out of view (macOS 15+; lazy stacks tear it down anyway).
private struct FigureScrollVisibility: ViewModifier {
    @Binding var isOnScreen: Bool

    func body(content: Content) -> some View {
        if #available(macOS 15, *) {
            content.onScrollVisibilityChange(threshold: 0.01) { isOnScreen = $0 }
        } else {
            content
        }
    }
}

/// Frames at whole multiples of `interval` since the reference date — every
/// ambient figure lands on the same ticks. `paused` yields the current frame only.
struct FigureAmbientSchedule: TimelineSchedule {
    let interval: Double
    let paused: Bool

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        let step = max(interval, 1.0 / 120)
        var next = ((startDate.timeIntervalSinceReferenceDate / step).rounded(.down) + 1) * step
        var first = true
        return AnyIterator {
            if paused && !first { return nil }
            defer { (first, next) = (false, next + step) }
            return first ? startDate : Date(timeIntervalSinceReferenceDate: next)
        }
    }
}
