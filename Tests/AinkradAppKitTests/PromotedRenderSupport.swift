import AppKit
import SwiftUI

@testable import AinkradAppKitUI

/// Renders a promoted Citadel component on the standard skin and says whether it drew anything: the bitmap exists
/// and holds more than one distinct pixel.
@MainActor
enum PromotedRender {
    static func draws(_ view: some View, width: CGFloat = 360, height: CGFloat = 200) -> Bool {
        let skin = AinkradSkin.standard
        let framed =
            view
            .padding(16)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(skin.color(skin.palette.background))
            .ainkradSkin(skin)
            .environment(\.colorScheme, .dark)
        guard let rep = SkinParityRenderer.render(framed, width: width, height: height) else { return false }
        var seen = Set<UInt32>()
        for x in stride(from: 0, to: rep.pixelsWide, by: 3) {
            for y in stride(from: 0, to: rep.pixelsHigh, by: 3) {
                guard let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                let key =
                    UInt32(color.redComponent * 255) << 16 | UInt32(color.greenComponent * 255) << 8
                    | UInt32(color.blueComponent * 255)
                seen.insert(key)
                if seen.count > 1 { return true }
            }
        }
        return false
    }
}
