import AinkradAppKitContract
import AppKit
import SwiftUI

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
            // 53 is the Esc key code.
            guard let self, self.panel === panel, event.keyCode == 53 else { return event }
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
