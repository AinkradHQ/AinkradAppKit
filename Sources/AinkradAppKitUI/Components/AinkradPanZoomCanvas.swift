import AppKit
import SwiftUI

/// The camera over an `AinkradPanZoomCanvas` world: the scale, the world's top-left in the viewport, and whether it
/// still follows Fit. Keep it in the screen's state; `zoom(by:)` and `fit()` are the zoom buttons.
public struct AinkradPanZoomCamera: Equatable, Sendable {
    public static let minScale: CGFloat = 0.35
    public static let maxScale: CGFloat = 2

    public var scale: CGFloat
    public var offset: CGSize
    public var fits: Bool
    /// The viewport and world sizes, as the canvas last laid them out.
    public var viewport: CGSize
    public var world: CGSize

    public init(
        scale: CGFloat = 1, offset: CGSize = .zero, fits: Bool = true, viewport: CGSize = .zero,
        world: CGSize = .zero
    ) {
        self.scale = scale
        self.offset = offset
        self.fits = fits
        self.viewport = viewport
        self.world = world
    }

    /// Everything in view, never above 100%, centred, `margin` from the top and sides, with `bottom` extra kept
    /// clear below (a legend row).
    public mutating func fit(margin: CGFloat = 48, bottom: CGFloat = 30) {
        guard world.width > 0, world.height > 0, viewport.width > 0 else { return }
        scale = max(
            Self.minScale,
            min(1, (viewport.width - margin * 2) / world.width, (viewport.height - margin * 2 - bottom) / world.height))
        offset = CGSize(width: (viewport.width - world.width * scale) / 2, height: margin)
        fits = true
    }

    /// Zooms to `scale × factor` keeping `point` (viewport coordinates, the centre by default) where it is.
    public mutating func zoom(by factor: CGFloat, at point: CGPoint? = nil) {
        let p = point ?? CGPoint(x: viewport.width / 2, y: viewport.height / 2)
        let next = min(Self.maxScale, max(Self.minScale, scale * factor))
        offset = CGSize(
            width: p.x - (p.x - offset.width) * next / scale, height: p.y - (p.y - offset.height) * next / scale)
        scale = next
        fits = false
    }

    public mutating func pan(_ delta: CGSize) {
        offset.width += delta.width
        offset.height += delta.height
        fits = false
    }

    /// The scale as a whole percentage.
    public var percent: Int { Int((scale * 100).rounded()) }
}

/// A pan and zoom world (an org chart): `world`, laid out at `worldSize` at zoom 1, drawn through `camera`. It re-fits
/// on resize until moved; a drag on empty space pans, two-finger scroll pans, ⌘-scroll and pinch zoom at the pointer.
/// Nodes in the world keep their own taps.
public struct AinkradPanZoomCanvas<World: View>: View {
    @Binding private var camera: AinkradPanZoomCamera
    private let worldSize: CGSize
    private let world: () -> World
    @State private var dragStart: CGSize?
    @State private var pinchStart: CGFloat?
    @State private var pointer: CGPoint?
    @State private var wheel = WheelMonitor()

    public init(
        camera: Binding<AinkradPanZoomCamera>, worldSize: CGSize, @ViewBuilder world: @escaping () -> World
    ) {
        self._camera = camera
        self.worldSize = worldSize
        self.world = world
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Color.clear.contentShape(Rectangle()).gesture(pan)
                world()
                    .frame(width: worldSize.width, height: worldSize.height, alignment: .topLeading)
                    .scaleEffect(camera.scale, anchor: .topLeading)
                    .offset(camera.offset)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(pinch)
            .onContinuousHover { phase in
                if case .active(let location) = phase { pointer = location } else { pointer = nil }
            }
            .onAppear { layout(geo.size) }
            .onChange(of: geo.size) { _, size in layout(size) }
            .onChange(of: worldSize) { _, _ in layout(geo.size) }
        }
        .onAppear {
            wheel.install { event in
                guard let at = pointer else { return false }
                if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) {
                    camera.zoom(
                        by: exp(-event.scrollingDeltaY * (event.hasPreciseScrollingDeltas ? 0.01 : 0.1)), at: at)
                } else {
                    camera.pan(CGSize(width: event.scrollingDeltaX, height: event.scrollingDeltaY))
                }
                return true
            }
        }
        .onDisappear { wheel.remove() }
    }

    private func layout(_ size: CGSize) {
        camera.viewport = size
        camera.world = worldSize
        if camera.fits { camera.fit() }
    }

    private var pan: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let start = dragStart ?? camera.offset
                dragStart = start
                camera.offset = CGSize(
                    width: start.width + value.translation.width, height: start.height + value.translation.height)
                camera.fits = false
            }
            .onEnded { _ in dragStart = nil }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStart ?? camera.scale
                pinchStart = start
                camera.zoom(by: start * value.magnification / camera.scale, at: value.startLocation)
            }
            .onEnded { _ in pinchStart = nil }
    }
}

/// Scroll-wheel events while the pointer is over the canvas (SwiftUI has no wheel gesture on macOS 14); the
/// handler returns whether it used the event.
@MainActor
private final class WheelMonitor {
    private var token: Any?

    func install(_ handler: @escaping @MainActor (NSEvent) -> Bool) {
        remove()
        token = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            nonisolated(unsafe) let box = event
            let used = MainActor.assumeIsolated { handler(box) }
            return used ? nil : event
        }
    }

    func remove() {
        if let token { NSEvent.removeMonitor(token) }
        token = nil
    }
}
