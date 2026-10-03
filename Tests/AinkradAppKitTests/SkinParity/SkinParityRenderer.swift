import AppKit
import SwiftUI
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Offscreen renderer for rendering SwiftUI views into 2x bitmap PNGs for skin parity testing.
@MainActor
public enum SkinParityRenderer {
    /// Renders a SwiftUI view into an NSBitmapImageRep at 2x scale (Retina display resolution).
    public static func render<V: View>(_ view: V, width: CGFloat = 400, height: CGFloat = 300) -> NSBitmapImageRep? {
        let envView = view
            .environment(\.ainkradMotionBudget, .frozen)
            .environment(\.ainkradTheme, .fallbackDark)
            .environment(\.ainkradStatusColors, .default)
            .environment(\.ainkradTypography, AinkradTypography(fontFamilyName: nil, scale: 1))
            .frame(width: width, height: height)
            .background(Color.black)

        let hostingView = NSHostingView(rootView: envView)
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = hostingView
        window.layoutIfNeeded()

        let targetScale: CGFloat = 2.0
        let bitmapWidth = Int(width * targetScale)
        let bitmapHeight = Int(height * targetScale)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: bitmapWidth,
            pixelsHigh: bitmapHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: bitmapWidth * 4,
            bitsPerPixel: 32
        ) else {
            return nil
        }

        rep.size = NSSize(width: width, height: height)

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context

        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

        NSGraphicsContext.restoreGraphicsState()
        return rep
    }
}
