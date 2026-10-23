import AppKit
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("Kit agent figure")
@MainActor
struct AinkradAgentFigureTests {
    @Test("17 palettes plus Muted, unique ids, found by id")
    func palettes() {
        #expect(AinkradFigurePalette.all.count == 17)
        #expect(Set(AinkradFigurePalette.all.map(\.id)).count == 17)
        #expect(AinkradFigurePalette.named("lime-circuit") == .limeCircuit)
        #expect(AinkradFigurePalette.named("muted") == .muted)
        #expect(AinkradFigurePalette.named("nope") == nil)
        #expect(figureMix(0x000000, 0xffffff, 0.5) == 0x808080)
    }

    @Test("size tiers follow the prototype cutoffs")
    func tiers() {
        #expect(AinkradFigureTier(size: 256) == .full)
        #expect(AinkradFigureTier(size: 64) == .full)
        #expect(AinkradFigureTier(size: 48) == .ambient)
        #expect(AinkradFigureTier(size: 32) == .ambient)
        #expect(AinkradFigureTier(size: 24) == .still)
        #expect(AinkradFigureTier(size: 20) == .still)
        #expect(AinkradFigureTier(size: 16) == .glyph)
    }

    @Test("decision #63 cues: listening teal, error is the confused pose with a red dot")
    func cues() {
        #expect(AinkradFigureState.listening.cue == 0x2dd4bf)
        #expect(AinkradFigureState.working.cue == 0x22d3ee)
        #expect(AinkradFigureState.confused.cue == 0xe3b341)
        #expect(AinkradFigureState.error.cue == 0xf85149)
        #expect(AinkradFigureState.error.pose == .confused)
        let look = FigureLook()
        #expect(
            FigurePose.make(.error, t: 1, seed: 1, still: true, small: false, look: look)
                == FigurePose.make(.confused, t: 1, seed: 1, still: true, small: false, look: look))
    }

    @Test("every state's key frame is a distinct pose")
    func distinctKeyFrames() {
        let poses = AinkradFigureState.allCases.filter { $0 != .error }.map {
            FigurePose.make($0, t: $0.keyTime, seed: 13.7, still: true, small: false, look: FigureLook())
        }
        for i in poses.indices {
            for j in poses.indices where j > i { #expect(poses[i] != poses[j]) }
        }
    }

    @Test("a state change morphs over 280 ms with a cubic ease-out")
    func morph() {
        let clock = FigureClock(state: .thinking, since: 10, previous: .idle, previousSince: 0)
        let look = FigureLook()
        let start = clock.pose(at: 10, phase: 0, seed: 1, small: false, look: look, level: nil)
        let end = clock.pose(at: 10.28, phase: 0, seed: 1, small: false, look: look, level: nil)
        #expect(abs(start.r - 31) < 0.001)
        #expect(abs(end.r - 28) < 0.001)
        let mid = clock.pose(at: 10.14, phase: 0, seed: 1, small: false, look: look, level: nil)
        #expect(abs(mid.r - (31 - 3 * 0.875)) < 0.001)
    }

    @Test("success hops once, then returns to idle after 3 s")
    func successSettles() {
        let clock = FigureClock(state: .success, since: 5)
        #expect(clock.resolved(at: 7.9).state == .success)
        let settled = clock.resolved(at: 8)
        #expect(settled.state == .idle)
        #expect(settled.previous == .success)
        #expect(settled.since == 8)
        let look = FigureLook()
        let hop = FigurePose.make(.success, t: 0.3, seed: 1, still: false, small: false, look: look)
        #expect(hop.scale > 1.1)
        let after = FigurePose.make(.success, t: 2.5, seed: 1, still: false, small: false, look: look)
        #expect(after.scale == 1 && after.burstO == 0)
    }

    @Test("the phase seed is stable per name and differs between names")
    func seeds() {
        #expect(figureSeed("Mira") == figureSeed("Mira"))
        #expect(figureSeed("Mira") != figureSeed("Toma"))
        #expect((1...1000).contains(figureSeed("")))
    }

    @Test("small figures drop the wobble, comet and rim; eyes grow")
    func smallSimplification() {
        let p = FigurePose.make(.loading, t: 0.7, seed: 1, still: true, small: true, look: FigureLook())
        #expect(p.w2 == 0 && p.cometO == 0 && p.r == 34)
        #expect(p.eh >= 3.5)
    }

    @Test("VoiceOver reads the name and the state")
    func accessibility() {
        #expect(AinkradFigureState.success.spokenName == "done")
        #expect(AinkradFigureState.confused.spokenName == "needs attention")
        #expect(AinkradFigureState.loading.spokenName == "starting")
    }

    @Test("every state renders at every tier without trapping")
    func renders() {
        for state in AinkradFigureState.allCases {
            for size in [256.0, 64, 32, 24, 16] {
                let view = AinkradAgentFigure(name: "Mira", state: state, harness: .claude, size: size)
                    .environment(\.ainkradMotionBudget, .frozen)
                #expect(ImageRenderer(content: view).cgImage != nil)
            }
        }
    }
}
