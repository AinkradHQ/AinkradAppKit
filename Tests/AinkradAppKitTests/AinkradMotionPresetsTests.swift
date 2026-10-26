import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradAnimationToken presets")
struct AinkradMotionPresetsTests {
    @Test("each preset equals the literal it replaces")
    func values() {
        #expect(AinkradAnimationToken.arrive == AinkradAnimationToken(curve: "easeOut", duration: 0.35))
        #expect(AinkradAnimationToken.arriveFlash == AinkradAnimationToken(curve: "easeOut", duration: 1.6))
        #expect(AinkradAnimationToken.grow == AinkradAnimationToken(curve: "easeOut", duration: 0.7))
        #expect(AinkradAnimationToken.fold == AinkradAnimationToken(curve: "easeOut", duration: 0.28))
        #expect(
            AinkradAnimationToken.springSnappy == AinkradAnimationToken(curve: "spring", response: 0.25, damping: 0.7))
        #expect(
            AinkradAnimationToken.springStandard == AinkradAnimationToken(curve: "spring", response: 0.3, damping: 0.75)
        )
        #expect(
            AinkradAnimationToken.springSoft == AinkradAnimationToken(curve: "spring", response: 0.5, damping: 0.75))
        #expect(AinkradAnimationToken.ambient(4) == AinkradAnimationToken(curve: "easeInOut", duration: 4))
    }

    @Test("presets survive a Codable round trip")
    func codable() throws {
        for token in [AinkradAnimationToken.arrive, .springStandard, .ambient(2.5)] {
            let data = try JSONEncoder().encode(token)
            #expect(try JSONDecoder().decode(AinkradAnimationToken.self, from: data) == token)
        }
    }

    @Test("the stagger delay is index times stagger")
    func staggerDelay() {
        #expect(ainkradStaggerDelay(index: 0, stagger: 0.06) == 0)
        #expect(abs(ainkradStaggerDelay(index: 3, stagger: 0.06) - 0.18) < 1e-9)
        #expect(ainkradStaggerDelay(index: 2, stagger: 0.1) == 0.2)
    }

    @Test("the index overload and the hover tap area construct (compile smoke)")
    @MainActor
    func constructs() {
        _ = Text("row").ainkradRiseIn(index: 2)
        _ = Text("row").ainkradRiseIn(index: 2, stagger: 0.1, distance: 4)
        _ = AinkradHoverTapArea(help: "Open", action: {}) { Text("row") }
        _ = Text("row").ainkradHoverFocus(cornerRadius: 6)
    }

    @Test("a chart regrows only when its segment set changes, not when values alone change")
    func regrowDecision() {
        #expect(!ainkradShouldRegrow(from: ["a", "b"], to: ["a", "b"]))
        #expect(ainkradShouldRegrow(from: ["a", "b"], to: ["a", "b", "c"]))
        #expect(ainkradShouldRegrow(from: ["a", "b"], to: ["a", "c"]))
        #expect(ainkradShouldRegrow(from: [1, 2], to: [2, 1]))
    }
}
