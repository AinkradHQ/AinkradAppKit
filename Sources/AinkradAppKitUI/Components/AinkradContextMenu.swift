import SwiftUI
import AppKit
import AinkradAppKitContract

/// One row of a `.ainkradContextMenu(_:)` — a title, optional leading SF
/// Symbol, an optional keyboard shortcut, an optional destructive style, and
/// the action to run on selection.
public struct AinkradMenuItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let systemName: String?
    /// The chord that does the same thing, rendered as an `AinkradKbd` keycap
    /// in a right-aligned column. `nil` where no chord does exactly this — do
    /// NOT show an approximate one, since a menu that teaches the wrong key is
    /// worse than one that teaches none.
    ///
    /// Pass the glyphs, not words: `"\u{2318}R"`, not `"Cmd+R"`.
    public let shortcut: String?
    public let isDestructive: Bool
    public let action: () -> Void

    public init(title: String, systemName: String? = nil, shortcut: String? = nil,
                isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemName = systemName
        self.shortcut = shortcut
        self.isDestructive = isDestructive
        self.action = action
    }
}

/// Zero-footprint `NSView` that reports right mouse-down events (in SCREEN
/// coordinates, matching `NSEvent.mouseLocation` used throughout
/// `AinkradFloatingPanelController`) via `onRightClick`, then forwards the
/// event via `super` so normal right-click behavior elsewhere is undisturbed.
/// This — deliberately not any AppKit/SwiftUI native context-menu API — is
/// how `.ainkradContextMenu(_:)` detects a right-click; the menu itself is
/// drawn entirely by `AinkradContextMenuList` inside a floating panel.
///
/// It lives in an OVERLAY, above the modified content. In the background —
/// where it used to be — it never receives the event at all if the content
/// draws anything opaque and interactive on top of it (a `contentShape` plus a
/// tap gesture is enough), so right-click silently did nothing on exactly the
/// rows most likely to want a menu. That cost three broken builds in the host's
/// file manager before the cause was found.
///
/// Overlaying an `NSView` normally breaks everything underneath it, because it
/// would swallow every left click. `hitTest` is what makes the overlay safe:
/// the view is invisible to hit-testing for any event that is not a
/// right-click, so selection, drags and double-clicks reach the content
/// untouched.
private final class AinkradRightClickCatcherView: NSView {
    var onRightClick: ((CGPoint) -> Void)?

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let event = NSApp.currentEvent else { return nil }
        switch event.type {
        case .rightMouseDown, .rightMouseUp, .rightMouseDragged:
            return super.hitTest(point)
        // ctrl-click IS a right-click on macOS, and it is how a trackpad user
        // without a configured secondary click opens a menu at all.
        case .leftMouseDown where event.modifierFlags.contains(.control):
            return super.hitTest(point)
        default:
            return nil
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(NSEvent.mouseLocation)
        super.rightMouseDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            onRightClick?(NSEvent.mouseLocation)
        } else {
            super.mouseDown(with: event)
        }
    }
}

private struct AinkradContextMenuCatcher: NSViewRepresentable {
    let controller: AinkradFloatingPanelController
    let onRightClick: (CGPoint) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = AinkradRightClickCatcherView()
        view.onRightClick = onRightClick
        controller.anchorView = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? AinkradRightClickCatcherView else { return }
        view.onRightClick = onRightClick
        controller.anchorView = view
    }
}

/// The chamfer floating-panel content for `.ainkradContextMenu(_:)` — hover
/// scan per row, optional leading icons, destructive rows tinted with
/// `ainkradStatusColors.danger`. Selecting a row runs its action then
/// dismisses.
private struct AinkradContextMenuList: View {
    let items: [AinkradMenuItem]
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(items) { item in
                AinkradContextMenuRow(item: item) {
                    item.action()
                    dismiss()
                }
            }
        }
        .padding(AinkradSpacing.xs)
        // `.behindWindow`, not the default: this list is ALWAYS presented in a
        // floating panel, which is its own window. A `.withinWindow` blur has
        // nothing to sample there, so the menu rendered as a flat opaque slab
        // instead of the glass every other surface in the language uses.
        .ainkradPanel(blending: .behindWindow)
    }
}

private struct AinkradContextMenuRow: View {
    let item: AinkradMenuItem
    let onSelect: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradTypography) private var typo
    @State private var hovering = false

    private var tint: Color { item.isDestructive ? statusColors.danger : theme.foreground.opacity(0.9) }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AinkradSpacing.sm) {
                if let systemName = item.systemName {
                    Image(systemName: systemName).font(.system(size: 12, weight: .semibold))
                }
                Text(item.title)
                    .font(AinkradFontResolver.font(.body, typography: typo))
                Spacer(minLength: AinkradSpacing.md)
                // The chord as a real keycap, in its own right-aligned column:
                // the menu teaches the keyboard rather than replacing it.
                if let shortcut = item.shortcut {
                    AinkradKbd(shortcut)
                }
            }
            .foregroundStyle(tint)
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs)
            .background(ChamferShape(cut: 4).fill(hovering ? theme.accentSecondary.opacity(0.14) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The panel gives its first button keyboard focus, and SwiftUI's
        // default focus ring is a heavy system rectangle with nothing to do
        // with this design language. Hover is the only highlight here.
        .focusEffectDisabled()
        .onHover { hovering = $0 }
    }
}

private struct AinkradContextMenuModifier: ViewModifier {
    let items: [AinkradMenuItem]

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradSurfaceOpacity) private var surfaceOpacity
    @Environment(\.ainkradSurfaceBlur) private var surfaceBlur
    @State private var controller = AinkradFloatingPanelController()

    func body(content: Content) -> some View {
        // OVERLAY, not background — see `AinkradRightClickCatcherView`. The
        // catcher is hit-test-transparent to everything but a right-click, so
        // being on top costs the content nothing.
        content.overlay(
            AinkradContextMenuCatcher(controller: controller, onRightClick: present)
        )
    }

    private func present(at screenPoint: CGPoint) {
        let theme = theme
        let typo = typo
        let statusColors = statusColors
        let surfaceOpacity = surfaceOpacity
        let surfaceBlur = surfaceBlur
        controller.present(
            maxHeight: 320,
            anchorScreenRectOverride: CGRect(origin: screenPoint, size: .zero)
        ) {
            AinkradContextMenuList(items: items, dismiss: { controller.dismiss() })
                .ainkradMenuEnvironment(theme: theme, typography: typo,
                                        statusColors: statusColors,
                                        surfaceOpacity: surfaceOpacity,
                                        surfaceBlur: surfaceBlur)
        } onDismiss: {}
    }
}

public extension View {
    /// Presents a CUSTOM right-click context menu — chamfer list, hover
    /// scan, optional icons, destructive styling — via `AinkradFloatingPanel`
    /// positioned at the cursor. Deliberately not a native AppKit/SwiftUI
    /// context-menu API: this renders the same borderless, non-activating
    /// floating panel used by the kit's selects/comboboxes, just anchored at
    /// the right-click point instead of below a fixed trigger view.
    func ainkradContextMenu(_ items: [AinkradMenuItem]) -> some View {
        modifier(AinkradContextMenuModifier(items: items))
    }
}

private extension View {
    /// Carries the design environment across a window boundary.
    ///
    /// Every menu here is drawn in a floating panel, which is its OWN
    /// `NSPanel`. SwiftUI's environment does not cross that boundary, so a
    /// value the app set at its root is simply absent inside the menu: without
    /// this the menu falls back to the neutral dark fallback theme and, since
    /// the surface settings landed, ignores Appearance -> Overlays while every
    /// panel around it obeys.
    func ainkradMenuEnvironment(theme: HostThemeTokens,
                                typography: AinkradTypography,
                                statusColors: AinkradStatusColors,
                                surfaceOpacity: Double?,
                                surfaceBlur: Bool) -> some View {
        self.environment(\.ainkradTheme, theme)
            .environment(\.ainkradTypography, typography)
            .environment(\.ainkradStatusColors, statusColors)
            .environment(\.ainkradSurfaceOpacity, surfaceOpacity)
            .environment(\.ainkradSurfaceBlur, surfaceBlur)
    }
}

/// A pull-down menu opened by LEFT-clicking its own label, drawn with the same
/// chamfered list, hover scan and glass backing as `.ainkradContextMenu(_:)`.
///
/// Exists because SwiftUI's `Menu` renders a stock AppKit menu — grey, system
/// corner radius, system highlight — which lands in the middle of an Ainkrad
/// HUD looking like it belongs to a different application. The kit already
/// drew a correct menu; it was just reachable only by right-click, so any
/// surface needing a click-to-open menu had no option but the native one.
public struct AinkradMenuButton<Label: View>: View {
    private let items: [AinkradMenuItem]
    private let maxHeight: CGFloat
    private let label: Label

    @State private var isPresented = false
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradSurfaceOpacity) private var surfaceOpacity
    @Environment(\.ainkradSurfaceBlur) private var surfaceBlur

    public init(items: [AinkradMenuItem],
                maxHeight: CGFloat = 320,
                @ViewBuilder label: () -> Label) {
        self.items = items
        self.maxHeight = maxHeight
        self.label = label()
    }

    public var body: some View {
        Button { isPresented.toggle() } label: { label }
            .buttonStyle(.plain)
            .ainkradFloatingPanel(isPresented: $isPresented, maxHeight: maxHeight) {
                AinkradContextMenuList(items: items, dismiss: { isPresented = false })
                    .ainkradMenuEnvironment(theme: theme, typography: typo,
                                            statusColors: statusColors,
                                            surfaceOpacity: surfaceOpacity,
                                            surfaceBlur: surfaceBlur)
            }
    }
}
