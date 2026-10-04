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
private final class AinkradKeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// AppKit-backed presenter for a top-level, custom-drawn floating panel: a
/// borderless, non-activating `NSPanel` hosting arbitrary SwiftUI content,
/// added as a child window of the trigger's window so it tracks/dismisses
/// with it. This is the shared presentation surface for `AinkradSelect`,
/// `AinkradMultiSelect`, `AinkradCombobox`, and `AinkradSearchableSelect` —
/// it renders above ALL app content (any clipping/overlay ancestor) without
/// requiring host cooperation, and is NOT a native `Menu`/`Picker`/`.popover`.
@MainActor
final class AinkradFloatingPanelController: NSObject, NSWindowDelegate {
    /// The trigger's underlying view, supplied by `AinkradFloatingPanelAnchor`.
    /// Weak: the anchor view's lifetime is owned by SwiftUI, not us.
    weak var anchorView: NSView?

    private var panel: NSPanel?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var localKeyMonitor: Any?
    private var parentWindowObservers: [NSObjectProtocol] = []
    private weak var parentWindow: NSWindow?
    private var onDismiss: (() -> Void)?
    /// Guards against a fade-out's completion handler running twice, and
    /// against re-entering the teardown while a fade is already in flight.
    private var isDismissing = false
    /// When set, positioning uses this SCREEN-coordinate rect instead of
    /// `anchorView`'s live bounds — used by callers (e.g. a right-click
    /// context menu) that anchor at a cursor point rather than a fixed
    /// trigger view. Cleared on dismiss.
    private var anchorRectOverride: CGRect?

    func present<Content: View>(
        maxHeight: CGFloat,
        autofocusTextField: Bool = false,
        matchAnchorWidth: Bool = false,
        anchorScreenRectOverride: CGRect? = nil,
        placement: AinkradPanelPlacement = .below,
        @ViewBuilder content: @escaping () -> Content,
        onDismiss: @escaping () -> Void
    ) {
        dismiss()
        guard let anchorView, let window = anchorView.window else { return }
        self.onDismiss = onDismiss
        self.parentWindow = window
        self.anchorRectOverride = anchorScreenRectOverride

        let frame: CGRect
        let sized: AnyView
        // Measure the content's natural size first (unconstrained), then
        // decide whether it needs to scroll under `maxHeight`.
        let measuring = NSHostingView(rootView: AnyView(content()))
        let natural = measuring.fittingSize
        let anchorWidth = (anchorScreenRectOverride ?? anchorScreenRect())?.width ?? 0
        let width = floatingPanelContentWidth(
            natural: natural.width,
            anchorWidth: anchorWidth,
            matchAnchorWidth: matchAnchorWidth
        )
        let height = min(max(natural.height, 1), maxHeight)
        let needsScroll = natural.height > maxHeight

        sized =
            needsScroll
            ? AnyView(ScrollView { content() }.frame(width: width, height: height))
            : AnyView(content().frame(width: width, height: height))

        let visibleFrame =
            window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
            ?? CGRect(x: 0, y: 0, width: width, height: height)
        let anchorRect = anchorScreenRectOverride ?? anchorScreenRect() ?? .zero
        let contentSize = CGSize(width: width, height: height)
        let bounds = floatingPanelBounds(
            windowFrame: window.frame, screenVisibleFrame: visibleFrame,
            contentSize: contentSize)
        switch placement {
        case .below:
            frame = floatingPanelFrame(
                anchorScreenRect: anchorRect, contentSize: contentSize,
                screenVisibleFrame: bounds)
        case .trailing:
            frame = floatingPanelFrameTrailing(
                anchorScreenRect: anchorRect, contentSize: contentSize,
                bounds: bounds)
        }

        let hosting = NSHostingView(rootView: sized)
        hosting.frame = CGRect(origin: .zero, size: frame.size)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = .clear

        let panel = AinkradKeyablePanel(
            contentRect: frame, styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.contentView = hosting
        panel.setFrame(frame, display: true)
        panel.alphaValue = 1

        window.addChildWindow(panel, ordered: .above)
        // `.nonactivatingPanel` keeps the app from being force-activated, but
        // the panel must still become key so `@FocusState` (the search field
        // in `AinkradSearchableSelect`) and our Esc key monitor work the
        // instant the panel appears.
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
        isDismissing = false

        installMonitors(panel: panel, parentWindow: window)

        if autofocusTextField {
            // `@FocusState` across a freshly-presented `.nonactivatingPanel`
            // is unreliable the instant the panel appears — SwiftUI can lose
            // the race to actually attach the hosted view to the (now key)
            // window before it tries to move first responder. Falling back
            // to AppKit directly is reliable: hop one runloop tick (so the
            // hosted view has finished attaching), find the search field's
            // backing `NSTextField` by walking the hosting view's subviews,
            // and hand it first responder explicitly.
            DispatchQueue.main.async { [weak self, weak panel] in
                guard let panel, let self, self.panel === panel else { return }
                if let field = Self.firstTextField(in: panel.contentView) {
                    panel.makeFirstResponder(field)
                    // Defense-in-depth: disable inline text-prediction/
                    // completion on the field editor so macOS's completion
                    // service (SPCompletionListServiceViewController) never
                    // attaches a remote view here — see AinkradFormControls'
                    // AutoGrowingTextView for the primary fix and rationale.
                    if let editor = (field as? NSTextField)?.currentEditor() as? NSTextView {
                        editor.isAutomaticTextCompletionEnabled = false
                        if #available(macOS 14.0, *) { editor.inlinePredictionType = .no }
                    }
                }
            }
        }
    }

    /// Depth-first search for the first `NSTextField` in `view`'s subview
    /// tree — used to hand first responder to a hosted SwiftUI `TextField`
    /// (which AppKit backs with an `NSTextField`) directly, bypassing
    /// `@FocusState`'s unreliable timing in a freshly-presented panel.
    private static func firstTextField(in view: NSView?) -> NSView? {
        guard let view else { return nil }
        for sub in view.subviews {
            if sub is NSTextField { return sub }
            if let found = firstTextField(in: sub) { return found }
        }
        return nil
    }

    /// Removes the panel, its childWindow relationship, and all monitors/
    /// observers, then fades the panel out before ordering it away. Safe to
    /// call multiple times (including re-entrantly from a notification fired
    /// while a fade is already in flight) — every path after the first is a
    /// no-op.
    func dismiss() {
        guard let panel, !isDismissing else { return }
        isDismissing = true
        removeMonitors()
        panel.parent?.removeChildWindow(panel)
        // Only restore key focus to the parent if Ainkrad is still the
        // active app. When dismissal was triggered by the parent window
        // resigning key (cmd-tab, clicking another app), re-keying here
        // would fight the user's focus change and steal focus back.
        if NSApp.isActive {
            parentWindow?.makeKey()
        }
        self.panel = nil
        parentWindow = nil
        onDismiss = nil
        anchorRectOverride = nil

        NSAnimationContext.runAnimationGroup { context in
            context.duration = AinkradMotion.durationFast
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                panel.orderOut(nil)
                panel.contentView = nil
                panel.delegate = nil
                self?.isDismissing = false
            }
        }
    }

    private func installMonitors(panel: NSPanel, parentWindow: NSWindow) {
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel === panel, event.keyCode == 53 /* Esc */ else { return event }
            self.requestDismiss()
            return nil
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            guard let self, self.panel === panel else { return event }
            if event.window === panel { return event }
            if self.isOutsideTriggerAndPanel(NSEvent.mouseLocation) { self.requestDismiss() }
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            guard let self else { return }
            if self.isOutsideTriggerAndPanel(NSEvent.mouseLocation) { self.requestDismiss() }
        }

        let center = NotificationCenter.default
        parentWindowObservers = [
            center.addObserver(forName: NSWindow.didResignKeyNotification, object: parentWindow, queue: .main) {
                [weak self] _ in
                self?.requestDismiss()
            },
            center.addObserver(forName: NSWindow.willMoveNotification, object: parentWindow, queue: .main) {
                [weak self] _ in
                self?.requestDismiss()
            },
            center.addObserver(forName: NSWindow.didMoveNotification, object: parentWindow, queue: .main) {
                [weak self] _ in
                self?.requestDismiss()
            },
            // The parent window can close (e.g. its owning surface/plugin
            // window is torn down) without ever resigning key first — clean
            // up the panel in that case too.
            center.addObserver(forName: NSWindow.willCloseNotification, object: parentWindow, queue: .main) {
                [weak self] _ in
                self?.requestDismiss()
            },
        ]
    }

    /// Whether a click at `screenPoint` is outside both the panel and the
    /// trigger's current anchor rect. The trigger's rect is recomputed live
    /// (rather than cached from `present()`) so a trigger that moves while
    /// the panel is open is still honored. When the trigger itself is
    /// clicked, this returns `false` so the outside-click monitor leaves the
    /// dismissal to the trigger Button's own toggle — otherwise the monitor
    /// would dismiss first and the Button's action would immediately reopen
    /// the panel.
    private func isOutsideTriggerAndPanel(_ screenPoint: CGPoint) -> Bool {
        guard let panel else { return true }
        let triggerRect = anchorRectOverride ?? anchorScreenRect() ?? .zero
        return isClickOutside(point: screenPoint, panelFrame: panel.frame, triggerFrame: triggerRect)
    }

    private func anchorScreenRect() -> CGRect? {
        guard let anchorView, let window = anchorView.window else { return nil }
        let rectInWindow = anchorView.convert(anchorView.bounds, to: nil)
        return window.convertToScreen(rectInWindow)
    }

    private func removeMonitors() {
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        if let localKeyMonitor { NSEvent.removeMonitor(localKeyMonitor) }
        localMouseMonitor = nil
        globalMouseMonitor = nil
        localKeyMonitor = nil
        let center = NotificationCenter.default
        parentWindowObservers.forEach { center.removeObserver($0) }
        parentWindowObservers = []
    }

    /// Tells the SwiftUI side to flip `isPresented` false, which drives
    /// `dismiss()` via the modifier's `onChange`. Idempotent.
    private func requestDismiss() {
        guard panel != nil else { return }
        let callback = onDismiss
        dismiss()
        callback?()
    }

    func windowWillClose(_ notification: Notification) {
        requestDismiss()
    }
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
