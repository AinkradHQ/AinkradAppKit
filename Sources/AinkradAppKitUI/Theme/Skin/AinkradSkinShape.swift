// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal theme layer — skin shape implementation
import CoreGraphics
import SwiftUI

public struct AinkradSkinShape: InsettableShape {
    public var token: AinkradShapeToken
    private var insetAmount: CGFloat = 0
    /// Set by `init(cut:corners:style:)`; wins over `token.corners` for a chamfer.
    private var chamferCorners: ChamferCorners?

    public init(token: AinkradShapeToken) {
        self.token = token
    }

    /// A direct caller's shape: under `chamfer` exactly `ChamferShape(cut:corners:)`;
    /// under `continuous`/`circular`, `cut` is the corner radius and all four corners round.
    public init(cut: CGFloat, corners: ChamferCorners = .diagonal, style: String) {
        self.token = AinkradShapeToken(style: style, cut: Double(cut))
        self.chamferCorners = corners
    }

    public func inset(by amount: CGFloat) -> AinkradSkinShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    public func path(in rect: CGRect) -> Path {
        let style = token.style
        let cutVal: CGFloat
        if let ratio = token.cutRatio {
            let computed = ratio * min(rect.width, rect.height)
            cutVal = max(token.minCut ?? 0, computed)
        } else {
            cutVal = CGFloat(token.cut ?? 8)
        }

        let corners: ChamferCorners
        if let chamferCorners {
            corners = chamferCorners
        } else if let cornersStr = token.corners {
            switch cornersStr {
            case "all": corners = .all
            case "top": corners = [.topLeft, .topRight]
            case "diagonal": corners = .diagonal
            default: corners = .diagonal
            }
        } else {
            corners = .diagonal
        }

        if style == "chamfer" {
            var chamfer = ChamferShape(cut: cutVal, corners: corners)
            if insetAmount != 0 {
                chamfer = chamfer.inset(by: insetAmount)
            }
            return chamfer.path(in: rect)
        } else if style == "continuous" {
            let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
            return RoundedRectangle(cornerRadius: cutVal, style: .continuous).path(in: insetRect)
        } else {
            let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
            return RoundedRectangle(cornerRadius: cutVal, style: .circular).path(in: insetRect)
        }
    }
}
