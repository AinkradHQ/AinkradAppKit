// design-lint: allow-file hex-color,raw-color,font-size,opacity-literal,radius-literal the prototype's fixed figure colours and prop glyph sizes, scaled with the figure (Designs/citadel/figures/orb.js)
import SwiftUI

/// One frame of the orb, drawn into a `Canvas`. Layers back → front: plate ·
/// harness arc · halo · burst · ripples · orbit dots (back) · body · currents,
/// specular and dim (clipped to the body) · rim sweep · comet · eyes · orbit
/// dots (front) · props · status dot. Units: the prototype's 100-unit viewBox.
struct FigureScene {
    var pose: FigurePose
    /// State-local time (props, ripples, orbit).
    var t: Double
    /// Wall time for the status dot's pulse / spin.
    var dotTime: Double
    var state: AinkradFigureState
    var size: CGFloat
    var palette: AinkradFigurePalette
    var harness: AinkradFigureHarness?
    var showsEyes: Bool
    var showsPlate: Bool
    var glass: Bool
    var increasedContrast: Bool
    var dotOutline: Color
    var image: Image?

    /// The canvas overhangs the layout frame so sparkles and the "?" can
    /// leave the 100-unit box the way SVG `overflow: visible` lets them.
    static let overhang: CGFloat = 1.2

    private var tier: AinkradFigureTier { AinkradFigureTier(size: size) }
    private var small: Bool { size <= 24 }
    /// One screen pixel in viewBox units.
    private var px: CGFloat { 100 / size }

    func draw(_ ctx: inout GraphicsContext, _ canvas: CGSize) {
        ctx.translateBy(x: canvas.width / 2, y: canvas.height / 2)
        ctx.scaleBy(x: size / 100, y: size / 100)
        drawPlate(&ctx)
        if let image {
            var c = ctx
            // Inset inside the harness arc (r 47.5) so the arc stays visible.
            let disc = Path(ellipseIn: CGRect(x: -44, y: -44, width: 88, height: 88))
            c.clip(to: disc)
            c.draw(c.resolve(image.resizable()), in: disc.boundingRect)
        } else {
            drawOrb(&ctx)
        }
        drawDot(&ctx)
    }

    private func drawPlate(_ ctx: inout GraphicsContext) {
        guard showsPlate else { return }
        if !increasedContrast {
            let tint = glass ? Color.white.opacity(0.045) : figureColor(0x22d3ee, opacity: 0.05)
            ctx.fill(Path(ellipseIn: CGRect(x: -48, y: -48, width: 96, height: 96)), with: .color(tint))
        }
        if let harness, size > 16 {
            ctx.stroke(
                arc(radius: 47.5, from: 110, to: 200), with: .color(harness.color),
                style: StrokeStyle(lineWidth: px * 2, lineCap: .round))
        }
    }

    private func drawOrb(_ ctx: inout GraphicsContext) {
        let p = pose
        let a = palette.light
        let b = palette.deep
        let radius = p.r * p.scale
        let hide: Double = small ? 0 : 1
        // Halo.
        let haloR = 49 * p.haloR
        ctx.fill(
            circle(0, 0, haloR),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: figureColor(a, opacity: 0.55 * p.haloO * hide), location: 0.45),
                    .init(color: figureColor(a, opacity: 0), location: 1),
                ]), center: .zero, startRadius: 0, endRadius: haloR))
        // Success burst ring.
        if p.burstO * hide > 0 {
            ctx.stroke(
                circle(0, 0, radius + p.burst * 16), with: .color(figureColor(0x3fb950, opacity: p.burstO)),
                lineWidth: 1.6)
        }
        // Listening ripples.
        if p.rippleO * hide > 0 {
            for i in 0..<3 {
                let u = figureMod(t / 2.4 + Double(i) / 3, 1)
                ctx.stroke(
                    circle(0, 0, radius + 2 + u * 15),
                    with: .color(figureColor(a, opacity: p.rippleO * (1 - u) * 0.7)), lineWidth: 1.2)
            }
        }
        drawOrbit(&ctx, front: false)
        // Body: 40 polar points → closed Catmull-Rom.
        let body = bodyPath(radius)
        let box = body.boundingRect
        ctx.fill(
            body,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: figureColor(a), location: 0),
                    .init(color: figureColor(figureMix(a, b, 0.55)), location: 0.55),
                    .init(color: figureColor(b), location: 1),
                ]), center: CGPoint(x: box.minX + 0.38 * box.width, y: box.minY + 0.32 * box.height),
                startRadius: 0, endRadius: 0.75 * (box.width + box.height) / 2))
        // Inner currents, specular and dim, clipped to the body.
        var inner = ctx
        inner.clip(to: body)
        for i in 0..<3 where !(small && i > 0) {
            let fi = Double(i)
            let ang = (p.spin * (1 + fi * 0.35) + fi * 120) * .pi / 180
            let rr = p.swirlR * (1 + fi * 0.3)
            let c = CGPoint(x: cos(ang) * rr - p.gx * (2 + fi), y: sin(ang) * rr * 0.8 + p.gy * (2 + fi))
            let r = [22.0, 20, 11][i]
            let o = [0.8, 0.9, 0.5][i]
            let rgb = [a, b, 0xffffff][i]
            inner.fill(
                circle(c.x, c.y, r),
                with: .radialGradient(
                    Gradient(colors: [figureColor(rgb, opacity: 0.9 * o), figureColor(rgb, opacity: 0)]),
                    center: c, startRadius: 0, endRadius: r))
        }
        var spec = inner
        spec.translateBy(x: -11, y: -14)
        spec.rotate(by: .degrees(-30))
        // rotate(-30) about (-11, -14), then the ellipse centre (-11 - gx·1.5, -14 + gy·1.5)
        spec.translateBy(x: -p.gx * 1.5, y: p.gy * 1.5)
        spec.scaleBy(x: 13, y: 8)
        spec.fill(
            circle(0, 0, 1),
            with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.75), Color.white.opacity(0)]), center: .zero,
                startRadius: 0, endRadius: 1))
        if p.dim > 0 {
            inner.fill(
                Path(CGRect(x: -50, y: -50, width: 100, height: 100)),
                with: .color(figureColor(0x05070c, opacity: p.dim)))
        }
        // Working rim sweep and loading comet.
        if p.rimO > 0 {
            ctx.stroke(
                arc(radius: radius + 0.6, from: p.rimA, to: p.rimA + 70), with: .color(.white.opacity(p.rimO)),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
        if p.cometO > 0 {
            ctx.stroke(
                arc(radius: radius + 6, from: p.cometA - 80, to: p.cometA),
                with: .color(figureColor(a, opacity: p.cometO)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
        }
        if showsEyes { drawEyes(&ctx) }
        drawOrbit(&ctx, front: true)
        if size >= 48 { drawProps(&ctx) }
    }

    private func bodyPath(_ radius: Double) -> Path {
        let p = pose
        let n = 40
        let pts: [CGPoint] = (0..<n).map { i in
            let a = Double(i) / Double(n) * figureTau
            let k =
                1 + p.w2 * sin(2 * a + t * 1.3) + p.w3 * sin(3 * a - t * 1.7 + 1) + p.w5 * sin(5 * a + t * 2.9)
            return CGPoint(x: cos(a) * radius * k, y: sin(a) * radius * k)
        }
        var path = Path()
        path.move(to: pts[0])
        for i in 0..<n {
            let p0 = pts[(i - 1 + n) % n]
            let p1 = pts[i]
            let p2 = pts[(i + 1) % n]
            let p3 = pts[(i + 2) % n]
            path.addCurve(
                to: p2,
                control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6))
        }
        path.closeSubpath()
        return path
    }

    /// Thinking: three dots on a tilted ellipse, in front of or behind the body by depth.
    private func drawOrbit(_ ctx: inout GraphicsContext, front: Bool) {
        let o1 = pose.orbitO * (small ? 0 : 1)
        guard o1 > 0 else { return }
        for i in 0..<3 {
            let a = t * 2.6 + Double(i) * figureTau / 3
            let z = sin(a)
            let x = cos(a) * 42
            let y = sin(a) * 9 - x * 0.22
            let r = 2.2 + z * 0.9
            guard (z > 0) == front else { continue }
            ctx.fill(circle(x, y, r), with: .color(.white.opacity(front ? o1 : o1 * 0.55)))
        }
    }

    private func drawEyes(_ ctx: inout GraphicsContext) {
        let p = pose
        var face = ctx
        face.translateBy(x: p.gx * 4, y: -p.gy * 3)
        eye(&face, cx: -p.ex, w: p.ew * p.eLs, h: p.eh * p.eLs, glint: small ? 0 : 1)
        eye(&face, cx: p.ex, w: p.ew * p.eRs, h: p.eh * p.eRs, glint: small ? 0 : 0.9)
    }

    /// A pill that crossfades to a happy ^ arc or a closed ‿ arc.
    private func eye(_ ctx: inout GraphicsContext, cx: Double, w: Double, h rawH: Double, glint: Double) {
        let p = pose
        let cy = -2.0
        let h = max(0.4, rawH)
        let ink = 0x0b1020 as UInt32
        let open = (1 - p.happy) * (1 - p.closed)
        if open > 0 {
            let rect = CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
            let rx = min(min(w, h) * 0.5, w / 2)
            let ry = min(w * 0.5, h / 2)
            ctx.fill(
                Path(roundedRect: rect, cornerSize: CGSize(width: rx, height: ry)),
                with: .color(figureColor(ink, opacity: open)))
        }
        if p.happy > 0 {
            var arcPath = Path()
            arcPath.move(to: CGPoint(x: cx - w / 2, y: cy + w * 0.2))
            arcPath.addQuadCurve(to: CGPoint(x: cx + w / 2, y: cy + w * 0.2), control: CGPoint(x: cx, y: cy - w * 0.75))
            ctx.stroke(
                arcPath, with: .color(figureColor(ink, opacity: p.happy)),
                style: StrokeStyle(lineWidth: w * 0.34, lineCap: .round))
        }
        if p.closed > 0 {
            var shut = Path()
            shut.move(to: CGPoint(x: cx - w / 2, y: cy))
            shut.addQuadCurve(to: CGPoint(x: cx + w / 2, y: cy), control: CGPoint(x: cx, y: cy + w * 0.5))
            ctx.stroke(
                shut, with: .color(figureColor(ink, opacity: p.closed)),
                style: StrokeStyle(lineWidth: w * 0.3, lineCap: .round))
        }
        let glintO = glint > 0 ? open * figureClamp(h / w - 0.4) : 0
        if glintO > 0 {
            let gx = cx - w * 0.14 + p.gx * w * 0.2
            let gy = cy - h * 0.2 - p.gy * h * 0.12
            ctx.fill(circle(gx, gy, glint), with: .color(.white.opacity(glintO)))
        }
    }

    /// z's (sleepy), sparkles (success) and "?" (confused), anchored top-right.
    private func drawProps(_ ctx: inout GraphicsContext) {
        let p = pose
        let ax = 26.0
        let ay = -34.0
        if p.zO > 0 {
            for i in 0..<3 {
                let u = figureMod(t / 3.6 + Double(i) / 3, 1)
                let fs = 7 + u * 6
                let text = ctx.resolve(
                    Text("z").font(.system(size: fs, weight: .bold)).foregroundColor(figureColor(0xcbd5e1)))
                var c = ctx
                c.opacity = p.zO * sin(Double.pi * u)
                c.draw(text, at: CGPoint(x: ax + u * 10 + sin(u * 6) * 1.5, y: ay + 8 - u * 20), anchor: .bottom)
            }
        }
        if p.sparkO > 0 {
            for i in 0..<3 {
                let fi = Double(i)
                let u = figureMod(t * 0.62 + fi * 0.33, 1)
                let a = [-150.0, -30, -95][i] * .pi / 180
                let r = 40 + u * 6
                let sc = sin(Double.pi * figureClamp(u * 1.6)) * (0.7 + fi * 0.15)
                guard sc > 0 else { continue }
                var c = ctx
                c.translateBy(x: cos(a) * r, y: sin(a) * r)
                c.scaleBy(x: sc, y: sc)
                c.rotate(by: .degrees(u * 90))
                c.fill(sparkle, with: .color(.white.opacity(p.sparkO)))
            }
        }
        if p.qO > 0 {
            var c = ctx
            c.translateBy(x: ax, y: ay)
            c.rotate(by: .degrees(sin(t * 1.3) * 10))
            c.opacity = p.qO
            let q = c.resolve(
                Text("?").font(.system(size: 17, weight: .heavy)).foregroundColor(figureColor(0xe3b341)))
            c.draw(q, at: CGPoint(x: 2, y: 2 + sin(t * 2.4) * 1.5), anchor: .bottom)
        }
    }

    private var sparkle: Path {
        var s = Path()
        s.move(to: CGPoint(x: 0, y: -6))
        s.addQuadCurve(to: CGPoint(x: 6, y: 0), control: CGPoint(x: 0.9, y: -0.9))
        s.addQuadCurve(to: CGPoint(x: 0, y: 6), control: CGPoint(x: 0.9, y: 0.9))
        s.addQuadCurve(to: CGPoint(x: -6, y: 0), control: CGPoint(x: -0.9, y: 0.9))
        s.addQuadCurve(to: CGPoint(x: 0, y: -6), control: CGPoint(x: -0.9, y: -0.9))
        return s
    }

    /// The status dot, lower right: hollow for rest, a pulse ring while
    /// thinking / working, a spinning arc while loading (≥ 32 px).
    private func drawDot(_ ctx: inout GraphicsContext) {
        let dr = min(max(size * 0.06, 3), 7) * px
        let dx = 36.0
        let dy = 36.0
        let cue = figureColor(state.cue)
        ctx.fill(circle(dx, dy, dr + px * 2), with: .color(figureColor(glass ? 0x1c1f27 : 0x0b1020)))
        if state == .rest {
            ctx.stroke(circle(dx, dy, dr), with: .color(cue), lineWidth: px * 1.6)
        } else {
            ctx.fill(circle(dx, dy, dr), with: .color(cue))
        }
        if increasedContrast {
            ctx.stroke(circle(dx, dy, dr + px * 0.5), with: .color(dotOutline), lineWidth: px)
        }
        if state == .thinking || state == .working {
            let u = figureMod(dotTime, 1.4) / 1.4
            ctx.stroke(
                circle(dx, dy, dr * (1 + u * 1.2)), with: .color(figureColor(state.cue, opacity: 0.8 * (1 - u))),
                lineWidth: px * 1.2)
        }
        if state == .loading, size >= 32 {
            let a = figureMod(dotTime * 360, 360)
            ctx.stroke(
                arc(radius: dr * 0.55, from: a, to: a + 220, cx: dx, cy: dy), with: .color(.white.opacity(0.9)),
                style: StrokeStyle(lineWidth: px * 1.4, lineCap: .round))
        }
    }

    private func circle(_ x: Double, _ y: Double, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
    }

    /// An arc in SVG degrees: 0° = +x, increasing clockwise on screen (y down).
    private func arc(radius r: Double, from a0: Double, to a1: Double, cx: Double = 0, cy: Double = 0) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: cx, y: cy), radius: r, startAngle: .degrees(a0), endAngle: .degrees(a1),
            clockwise: false)
        return path
    }
}
