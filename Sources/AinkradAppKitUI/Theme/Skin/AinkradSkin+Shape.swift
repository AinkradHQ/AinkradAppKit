import CoreGraphics

extension AinkradSkin {
    /// The skin-aware shape for a direct caller: exact `ChamferShape(cut:corners:)`
    /// geometry under `chamfer`, a `cut`-radius rounded rect under `continuous`/`circular`.
    public func shape(cut: CGFloat, corners: ChamferCorners = .diagonal) -> AinkradSkinShape {
        AinkradSkinShape(cut: cut, corners: corners, style: shape.style)
    }
}
