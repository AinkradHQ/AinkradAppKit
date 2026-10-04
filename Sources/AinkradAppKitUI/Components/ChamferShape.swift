import AinkradAppKitContract
import CoreGraphics
import SwiftUI

/// Which corners of a rect get the Cardinal HUD chamfer (cut-corner) treatment.
public struct ChamferCorners: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let topLeft = ChamferCorners(rawValue: 1 << 0)
    public static let topRight = ChamferCorners(rawValue: 1 << 1)
    public static let bottomLeft = ChamferCorners(rawValue: 1 << 2)
    public static let bottomRight = ChamferCorners(rawValue: 1 << 3)

    /// All four corners chamfered.
    public static let all: ChamferCorners = [.topLeft, .topRight, .bottomLeft, .bottomRight]
    /// The signature Cardinal HUD diagonal: top-left + bottom-right only.
    public static let diagonal: ChamferCorners = [.topLeft, .bottomRight]
}

/// Walks `rect` clockwise from the top-left, inserting two points per
/// chamfered corner (the bevel) and a single point for each untouched corner.
/// Exposed standalone (not just via `ChamferShape`) so the geometry is
/// unit-testable without going through SwiftUI's `Path`.
public func chamferPoints(in rect: CGRect, cut: CGFloat, corners: ChamferCorners) -> [CGPoint] {
    let c = max(0, min(cut, min(rect.width, rect.height) / 2))
    let minX = rect.minX
    let maxX = rect.maxX
    let minY = rect.minY
    let maxY = rect.maxY

    var points: [CGPoint] = []

    // Top-left
    if corners.contains(.topLeft) {
        points.append(CGPoint(x: minX, y: minY + c))
        points.append(CGPoint(x: minX + c, y: minY))
    } else {
        points.append(CGPoint(x: minX, y: minY))
    }

    // Top-right
    if corners.contains(.topRight) {
        points.append(CGPoint(x: maxX - c, y: minY))
        points.append(CGPoint(x: maxX, y: minY + c))
    } else {
        points.append(CGPoint(x: maxX, y: minY))
    }

    // Bottom-right
    if corners.contains(.bottomRight) {
        points.append(CGPoint(x: maxX, y: maxY - c))
        points.append(CGPoint(x: maxX - c, y: maxY))
    } else {
        points.append(CGPoint(x: maxX, y: maxY))
    }

    // Bottom-left
    if corners.contains(.bottomLeft) {
        points.append(CGPoint(x: minX + c, y: maxY))
        points.append(CGPoint(x: minX, y: maxY - c))
    } else {
        points.append(CGPoint(x: minX, y: maxY))
    }

    return points
}

/// Chamfered (cut-corner) rectangle — the base silhouette for Cardinal HUD
/// panels, buttons, and framing. `cut` is the bevel size in points; `corners`
/// selects which corners are chamfered (default `.diagonal`, the signature
/// HUD look). Insettable so accent borders/strokes stay crisp.
public struct ChamferShape: InsettableShape {
    public var cut: CGFloat
    public var corners: ChamferCorners
    private var insetAmount: CGFloat = 0

    public init(cut: CGFloat = 10, corners: ChamferCorners = .diagonal) {
        self.cut = cut
        self.corners = corners
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let points = chamferPoints(in: insetRect, cut: cut, corners: corners)
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }

    public func inset(by amount: CGFloat) -> ChamferShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
