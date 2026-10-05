import SwiftUI

/// The brand chevron — the upward arrow from the Ainkrad logo mark, drawn as a
/// path so it can be filled, stroked, glowed and themed natively. Apex at top
/// center, feet at the bottom corners, with a notch cut upward into the bottom
/// center (the "A"). Carries no tokens: call sites fill it with an accent color.
public struct AinkradBrandChevron: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w * 0.68, y: h))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.42))
        path.addLine(to: CGPoint(x: w * 0.32, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}
