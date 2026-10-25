import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("Promoted Citadel motion and canvas")
@MainActor
struct AinkradSceneMotionTests {
    @Test("fit centres the world, never above 100%, and re-arms following")
    func cameraFit() {
        var camera = AinkradPanZoomCamera(
            viewport: CGSize(width: 1000, height: 700), world: CGSize(width: 400, height: 300))
        camera.fits = false
        camera.fit()
        #expect(camera.scale == 1)
        #expect(camera.offset == CGSize(width: 300, height: 48))
        #expect(camera.fits)
        camera.world = CGSize(width: 2000, height: 300)
        camera.fit()
        #expect(abs(camera.scale - 904.0 / 2000) < 1e-9)
    }

    @Test("zoom keeps the pointer's world point still and clamps the scale")
    func cameraZoom() {
        var camera = AinkradPanZoomCamera(
            offset: CGSize(width: 10, height: 20), viewport: CGSize(width: 800, height: 600))
        let point = CGPoint(x: 200, y: 100)
        let worldPoint = CGPoint(
            x: (point.x - camera.offset.width) / camera.scale, y: (point.y - camera.offset.height) / camera.scale)
        camera.zoom(by: 1.5, at: point)
        #expect(abs((point.x - camera.offset.width) / camera.scale - worldPoint.x) < 1e-9)
        #expect(abs((point.y - camera.offset.height) / camera.scale - worldPoint.y) < 1e-9)
        #expect(!camera.fits)
        camera.zoom(by: 100)
        #expect(camera.scale == AinkradPanZoomCamera.maxScale)
        camera.zoom(by: 0.0001)
        #expect(camera.scale == AinkradPanZoomCamera.minScale)
        #expect(camera.percent == 35)
    }

    @Test("panning moves the offset and releases Fit")
    func cameraPan() {
        var camera = AinkradPanZoomCamera()
        camera.pan(CGSize(width: 5, height: -3))
        #expect(camera.offset == CGSize(width: 5, height: -3))
        #expect(!camera.fits)
    }

    @Test("a typing dot is still outside its bounce, peaks at 30% of the cycle and wraps negative times")
    func typingPhase() {
        #expect(AinkradTypingDots.phase(0) == 0)
        #expect(abs(AinkradTypingDots.phase(0.36) - 1) < 1e-9)
        #expect(AinkradTypingDots.phase(0.9) == 0)
        #expect(abs(AinkradTypingDots.phase(-0.84) - 1) < 1e-9)
    }

    @Test("the glow, the dots and a rising row draw")
    func motionDraws() {
        let view = ZStack {
            AinkradParallaxGlow(light: .blue, deep: .purple, cursor: CGPoint(x: 0.2, y: -0.1))
            VStack {
                AinkradTypingDots()
                AinkradTypingDots(bubble: false)
                Text("Row").ainkradRiseIn(delay: 0.1)
                AinkradPanZoomCanvas(
                    camera: .constant(AinkradPanZoomCamera()), worldSize: CGSize(width: 200, height: 100)
                ) {
                    Color.orange
                }
                .frame(width: 200, height: 100)
            }
        }
        #expect(PromotedRender.draws(view, width: 320, height: 260))
    }
}
