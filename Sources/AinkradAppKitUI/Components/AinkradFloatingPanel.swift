import AinkradAppKitContract
import AppKit
import SwiftUI

/// Positions a floating panel relative to an anchor rect, both in SCREEN
/// coordinates (AppKit convention: origin bottom-left, y grows upward).
/// Prefers directly below the anchor, left-aligned; flips above the anchor
/// if there isn't room below; then clamps into `screenVisibleFrame` on both
/// axes so the panel never overflows above the menu bar or below the dock.
/// If `contentSize.height` exceeds the visible frame's entire height (so no
/// clamp can fit it), the top edge is pinned to the visible frame's top and
/// the excess is left to scroll off the bottom (the caller wraps oversized
/// content in a `ScrollView`). Pure — unit tested without AppKit/SwiftUI.
public func floatingPanelFrame(
    anchorScreenRect: CGRect,
    contentSize: CGSize,
    screenVisibleFrame: CGRect,
    gap: CGFloat = 4
) -> CGRect {
    let belowY = anchorScreenRect.minY - gap - contentSize.height
    let tallerThanScreen = contentSize.height > screenVisibleFrame.height
    var originY: CGFloat
    if belowY >= screenVisibleFrame.minY {
        originY = belowY
    } else {
        // No room below — try flipping above the trigger.
        let aboveY = anchorScreenRect.maxY + gap
        if aboveY + contentSize.height <= screenVisibleFrame.maxY {
            originY = aboveY
        } else if tallerThanScreen {
            // Content can't fit within the visible frame at all: pin the top
            // edge to the visible top and let it scroll past the bottom.
            originY = screenVisibleFrame.maxY - contentSize.height
        } else {
            // Fits within the visible height but not at either preferred
            // position — clamp fully inside below.
            originY = belowY
        }
    }

    var originX = anchorScreenRect.minX
    if originX + contentSize.width > screenVisibleFrame.maxX {
        originX = screenVisibleFrame.maxX - contentSize.width
    }
    if originX < screenVisibleFrame.minX {
        originX = screenVisibleFrame.minX
    }

    // Only clamp vertically when the content could actually fit inside the
    // visible frame — otherwise clamping would undo the top-pin above.
    if !tallerThanScreen {
        if originY + contentSize.height > screenVisibleFrame.maxY {
            originY = screenVisibleFrame.maxY - contentSize.height
        }
        if originY < screenVisibleFrame.minY {
            originY = screenVisibleFrame.minY
        }
    }

    return CGRect(x: originX, y: originY, width: contentSize.width, height: contentSize.height)
}

/// Where a floating panel opens relative to its trigger.
public enum AinkradPanelPlacement: Sendable, Equatable {
    /// Below the trigger, flipping above when there is no room (the default).
    case below
    /// Beside the trigger, top-aligned with it: to its right, or its left when
    /// the right has no room. For triggers in a vertical rail or sidebar.
    case trailing
}

/// `.trailing` placement: right of the anchor (left if that overflows),
/// top edges aligned, then slid up or down to stay inside `bounds`. Pure —
/// unit tested without AppKit/SwiftUI.
public func floatingPanelFrameTrailing(
    anchorScreenRect: CGRect,
    contentSize: CGSize,
    bounds: CGRect,
    gap: CGFloat = 6
) -> CGRect {
    var originX = anchorScreenRect.maxX + gap
    if originX + contentSize.width > bounds.maxX {
        originX = max(bounds.minX, anchorScreenRect.minX - gap - contentSize.width)
    }
    var originY = anchorScreenRect.maxY - contentSize.height
    if originY < bounds.minY { originY = bounds.minY }
    if originY + contentSize.height > bounds.maxY { originY = max(bounds.minY, bounds.maxY - contentSize.height) }
    return CGRect(x: originX, y: originY, width: contentSize.width, height: contentSize.height)
}

/// The region a floating panel is placed within: the parent window's part of
/// the screen when the panel fits there, so a trigger near the window's bottom
/// flips its panel up instead of hanging it below the app. A window too small
/// for the panel (a shrunken tile, a short pane) falls back to the whole
/// visible screen rather than squeezing the panel. Pure — unit tested.
///
/// The window is inset by `margin` first: its frame includes the window's own
/// border, and a panel flush with it reads as hanging off the edge.
func floatingPanelBounds(
    windowFrame: CGRect, screenVisibleFrame: CGRect, contentSize: CGSize,
    margin: CGFloat = AinkradSpacing.sm
) -> CGRect {
    let inWindow = windowFrame.insetBy(dx: margin, dy: margin).intersection(screenVisibleFrame)
    guard !inWindow.isNull, inWindow.width >= contentSize.width, inWindow.height >= contentSize.height else {
        return screenVisibleFrame
    }
    return inWindow
}

/// The width a floating panel's content should be laid out at: never below
/// `minWidth`, always at least the content's natural width, and — when
/// `matchAnchorWidth` is set — at least the trigger's own width, so a
/// dropdown is never narrower than the field that opened it (it only ever
/// grows to match, never shrinks). Pure — unit tested without AppKit/SwiftUI.
public func floatingPanelContentWidth(
    natural: CGFloat,
    anchorWidth: CGFloat,
    matchAnchorWidth: Bool,
    minWidth: CGFloat = 160
) -> CGFloat {
    max(natural, matchAnchorWidth ? anchorWidth : 0, minWidth)
}

/// True when `point` (in SCREEN coordinates) falls outside both the panel's
/// frame and the trigger's anchor rect. Used to distinguish a genuine
/// outside click (which should dismiss the panel) from a click back on the
/// trigger itself (which must be left for the trigger's own Button action to
/// toggle — otherwise the outside-click monitor would dismiss first and the
/// Button's action would immediately reopen it). Pure — unit tested without
/// AppKit/SwiftUI.
public func isClickOutside(point: CGPoint, panelFrame: CGRect, triggerFrame: CGRect) -> Bool {
    !panelFrame.contains(point) && !triggerFrame.contains(point)
}

/// A borderless, non-activating panel that can still become key. By default
/// `.nonactivatingPanel` windows report `canBecomeKey == false`, which means
/// SwiftUI `@FocusState` (the search field in `AinkradSearchableSelect`) and
/// our own Esc-key monitor never receive input. Overriding `canBecomeKey`
/// fixes that while `.nonactivatingPanel` still does its job of not forcing
/// the host app to activate/steal focus from other apps.
final class AinkradKeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Zero-footprint `NSView` bridge used only to obtain the trigger's
/// underlying `NSView` (for window + screen-coordinate lookups). Sized to
/// match its SwiftUI parent via `.background`, so its bounds mirror the
/// trigger's bounds; it draws nothing and never intercepts hit-testing.
private struct AinkradFloatingPanelAnchor: NSViewRepresentable {
    let controller: AinkradFloatingPanelController
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        controller.anchorView = view
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        controller.anchorView = nsView
    }
}

private struct AinkradFloatingPanelModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var maxHeight: CGFloat
    var autofocusTextField: Bool = false
    var matchAnchorWidth: Bool = false
    var placement: AinkradPanelPlacement = .below
    @ViewBuilder var panelContent: () -> PanelContent

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradSkinStorage) private var skinStorage

    @State private var controller = AinkradFloatingPanelController()

    func body(content: Content) -> some View {
        content
            .background(AinkradFloatingPanelAnchor(controller: controller))
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    present()
                } else {
                    controller.dismiss()
                }
            }
            .onDisappear { controller.dismiss() }
    }

    private func present() {
        // NSHostingView doesn't inherit the SwiftUI environment from the call
        // site, so the theme/typography/status-color environment is captured
        // here and re-injected onto the hosted content explicitly.
        let theme = theme
        let typo = typo
        let statusColors = statusColors
        let skinStorage = skinStorage
        controller.present(
            maxHeight: maxHeight, autofocusTextField: autofocusTextField,
            matchAnchorWidth: matchAnchorWidth, placement: placement
        ) {
            panelContent()
                .environment(\.ainkradSkinStorage, skinStorage)
                .environment(\.ainkradTheme, theme)
                .environment(\.ainkradTypography, typo)
                .environment(\.ainkradStatusColors, statusColors)
        } onDismiss: {
            isPresented = false
        }
    }
}

extension View {
    /// Presents `content` in a top-level, custom-drawn floating panel
    /// anchored just below this view — mirrors `.popover`'s ergonomics but
    /// renders in an app-level `NSPanel` instead of an in-view `.overlay`, so
    /// it is never clipped by an ancestor's bounds and floats above every
    /// other window/plugin surface. Content is capped at `maxHeight` and
    /// scrolls if taller. Dismisses on selection (caller sets `isPresented`
    /// false), Esc, an outside click, or the parent window losing key/moving.
    public func ainkradFloatingPanel<PanelContent: View>(
        isPresented: Binding<Bool>,
        maxHeight: CGFloat = 320,
        autofocusTextField: Bool = false,
        @ViewBuilder content: @escaping () -> PanelContent
    ) -> some View {
        modifier(
            AinkradFloatingPanelModifier(
                isPresented: isPresented, maxHeight: maxHeight, autofocusTextField: autofocusTextField,
                panelContent: content))
    }

    /// Variant that additionally floors the panel's width to the trigger's own
    /// width (`matchAnchorWidth`), so a dropdown never renders narrower than
    /// the field that opened it. NEW additive overload — the label-free
    /// existing overload is byte-unchanged, keeping its exported symbol stable.
    public func ainkradFloatingPanel<PanelContent: View>(
        isPresented: Binding<Bool>,
        maxHeight: CGFloat = 320,
        autofocusTextField: Bool = false,
        matchAnchorWidth: Bool,
        @ViewBuilder content: @escaping () -> PanelContent
    ) -> some View {
        modifier(
            AinkradFloatingPanelModifier(
                isPresented: isPresented, maxHeight: maxHeight, autofocusTextField: autofocusTextField,
                matchAnchorWidth: matchAnchorWidth, panelContent: content))
    }

    /// Variant that chooses where the panel opens — `.trailing` puts it beside
    /// the trigger, for triggers in a vertical rail. NEW additive overload
    /// (`placement:` has no default), so the existing symbols are unchanged.
    public func ainkradFloatingPanel<PanelContent: View>(
        isPresented: Binding<Bool>,
        maxHeight: CGFloat = 320,
        placement: AinkradPanelPlacement,
        @ViewBuilder content: @escaping () -> PanelContent
    ) -> some View {
        modifier(
            AinkradFloatingPanelModifier(
                isPresented: isPresented, maxHeight: maxHeight,
                placement: placement, panelContent: content))
    }
}
