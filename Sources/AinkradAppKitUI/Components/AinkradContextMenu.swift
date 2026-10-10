import AinkradAppKitContract
import AppKit
import SwiftUI

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

    public init(
        title: String, systemName: String? = nil, shortcut: String? = nil,
        isDestructive: Bool = false, action: @escaping () -> Void
    ) {
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

    @Environment(\.ainkradSkin) private var skin

    var body: some View {
        VStack(alignment: .leading, spacing: skin.components.contextMenu.rowGap) {
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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradTypography) private var typo
    @State private var hovering = false

    private var tint: Color {
        item.isDestructive ? statusColors.danger : skin.color(skin.components.contextMenu.tint)
    }

    var body: some View {
        let menu = skin.components.contextMenu
        let shape = AinkradSkinShape(token: menu.rowShape)
        Button(action: onSelect) {
            HStack(spacing: skin.spacing.sm) {
                if let systemName = item.systemName {
                    Image(systemName: systemName).font(skin.font(menu.glyphFont, typography: typo))
                }
                Text(item.title)
                    .font(skin.font(menu.bodyFont, typography: typo))
                Spacer(minLength: skin.spacing.md)
                if let shortcut = item.shortcut {
                    AinkradKbd(shortcut)
                }
            }
            .foregroundStyle(tint)
            .padding(.horizontal, skin.spacing.sm)
            .padding(.vertical, skin.spacing.xs)
            .background(shape.fill(hovering ? skin.color(menu.rowHoverFill) : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .onHover { hovering = $0 }
    }
}

private struct AinkradContextMenuModifier: ViewModifier {
    let items: [AinkradMenuItem]

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradSkinStorage) private var skinStorage
    @Environment(\.ainkradSurfaceOpacity) private var surfaceOpacity
    @Environment(\.ainkradSurfaceBlur) private var surfaceBlur
    @Environment(\.ainkradSkin) private var skin
    @State private var controller = AinkradFloatingPanelController()

    func body(content: Content) -> some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: a real `NSMenu`, which macOS draws as glass.
            content.contextMenu { NativeMenuItems(items: items) }
        } else {
            // OVERLAY, not background — see `AinkradRightClickCatcherView`. The
            // catcher is hit-test-transparent to everything but a right-click, so
            // being on top costs the content nothing.
            content.overlay(
                AinkradContextMenuCatcher(controller: controller, onRightClick: present)
            )
        }
    }

    private func present(at screenPoint: CGPoint) {
        let theme = theme
        let typo = typo
        let statusColors = statusColors
        let skinStorage = skinStorage
        let surfaceOpacity = surfaceOpacity
        let surfaceBlur = surfaceBlur
        controller.present(
            maxHeight: 320,
            anchorScreenRectOverride: CGRect(origin: screenPoint, size: .zero)
        ) {
            AinkradContextMenuList(items: items, dismiss: { controller.dismiss() })
                .ainkradMenuEnvironment(
                    theme: theme, typography: typo,
                    statusColors: statusColors,
                    skinStorage: skinStorage,
                    surfaceOpacity: surfaceOpacity,
                    surfaceBlur: surfaceBlur)
        } onDismiss: {
        }
    }
}

extension View {
    /// Presents a CUSTOM right-click context menu — chamfer list, hover
    /// scan, optional icons, destructive styling — via `AinkradFloatingPanel`
    /// positioned at the cursor. Deliberately not a native AppKit/SwiftUI
    /// context-menu API: this renders the same borderless, non-activating
    /// floating panel used by the kit's selects/comboboxes, just anchored at
    /// the right-click point instead of below a fixed trigger view.
    public func ainkradContextMenu(_ items: [AinkradMenuItem]) -> some View {
        modifier(AinkradContextMenuModifier(items: items))
    }
}

extension View {
    /// Carries the design environment across a window boundary.
    ///
    /// Every menu here is drawn in a floating panel, which is its OWN
    /// `NSPanel`. SwiftUI's environment does not cross that boundary, so a
    /// value the app set at its root is simply absent inside the menu: without
    /// this the menu falls back to the neutral dark fallback theme and, since
    /// the surface settings landed, ignores Appearance -> Overlays while every
    /// panel around it obeys.
    fileprivate func ainkradMenuEnvironment(
        theme: HostThemeTokens,
        typography: AinkradTypography,
        statusColors: AinkradStatusColors,
        skinStorage: AinkradSkin,
        surfaceOpacity: Double?,
        surfaceBlur: Bool
    ) -> some View {
        self.environment(\.ainkradSkinStorage, skinStorage)
            .environment(\.ainkradTheme, theme)
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
    private var placement: AinkradPanelPlacement = .below
    private let label: Label

    @State private var isPresented = false
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradSkinStorage) private var skinStorage
    @Environment(\.ainkradSurfaceOpacity) private var surfaceOpacity
    @Environment(\.ainkradSurfaceBlur) private var surfaceBlur
    @Environment(\.ainkradSkin) private var skin

    public init(
        items: [AinkradMenuItem],
        maxHeight: CGFloat = 320,
        @ViewBuilder label: () -> Label
    ) {
        self.items = items
        self.maxHeight = maxHeight
        self.label = label()
    }

    /// Chooses where the menu opens; `.trailing` opens it beside the button,
    /// for a button in a vertical rail. NEW overload (`placement:` has no
    /// default), so `init(items:maxHeight:label:)` keeps its symbol.
    public init(
        items: [AinkradMenuItem],
        maxHeight: CGFloat = 320,
        placement: AinkradPanelPlacement,
        @ViewBuilder label: () -> Label
    ) {
        self.items = items
        self.maxHeight = maxHeight
        self.placement = placement
        self.label = label()
    }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple's pull-down menu behind the caller's label.
            Menu {
                NativeMenuItems(items: items)
            } label: {
                label
            }
            // `.button` + `.plain`, not `.borderlessButton`: the borderless
            // style flattens a custom label to its title text, which dropped
            // Thrall's engine status dot and the label's own capsule.
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        Button {
            isPresented.toggle()
        } label: {
            label
        }
        .buttonStyle(.plain)
        .ainkradFloatingPanel(isPresented: $isPresented, maxHeight: maxHeight, placement: placement) {
            AinkradContextMenuList(items: items, dismiss: { isPresented = false })
                .ainkradMenuEnvironment(
                    theme: theme, typography: typo,
                    statusColors: statusColors,
                    skinStorage: skinStorage,
                    surfaceOpacity: surfaceOpacity,
                    surfaceBlur: surfaceBlur)
        }
    }
}

/// Kit menu items as native menu buttons: icon, destructive role, and the
/// item's shortcut glyphs shown as the menu's key equivalent.
private struct NativeMenuItems: View {
    let items: [AinkradMenuItem]

    var body: some View {
        ForEach(items) { item in
            let button = Button(role: item.isDestructive ? .destructive : nil, action: item.action) {
                if let systemName = item.systemName {
                    Label(item.title, systemImage: systemName)
                } else {
                    Text(item.title)
                }
            }
            if let shortcut = item.shortcut.flatMap(ainkradKeyboardShortcut) {
                button.keyboardShortcut(shortcut)
            } else {
                button
            }
        }
    }
}

/// Parses an `AinkradMenuItem.shortcut` glyph string ("⌘R", "⇧⌘K", "⌥↩")
/// into a `KeyboardShortcut`, so a native menu shows it as the key equivalent.
/// Nil for a string it cannot read: better no shortcut than a wrong one.
func ainkradKeyboardShortcut(_ glyphs: String) -> KeyboardShortcut? {
    var modifiers: EventModifiers = []
    var rest = Substring(glyphs.trimmingCharacters(in: .whitespaces))
    let flags: [Character: EventModifiers] = ["⌘": .command, "⌥": .option, "⇧": .shift, "⌃": .control]
    while let first = rest.first, let flag = flags[first] {
        modifiers.insert(flag)
        rest = rest.dropFirst()
    }
    let named: [String: KeyEquivalent] = [
        "↩": .return, "⏎": .return, "⌫": .delete, "⌦": .deleteForward, "⎋": .escape, "⇥": .tab,
        "←": .leftArrow, "→": .rightArrow, "↑": .upArrow, "↓": .downArrow, "Space": .space, "␣": .space,
    ]
    let key: KeyEquivalent
    if let special = named[String(rest)] {
        key = special
    } else if rest.count == 1, let character = rest.first {
        key = KeyEquivalent(Character(character.lowercased()))
    } else {
        return nil
    }
    return KeyboardShortcut(key, modifiers: modifiers)
}
