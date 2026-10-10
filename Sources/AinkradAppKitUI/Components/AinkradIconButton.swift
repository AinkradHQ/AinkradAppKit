import AinkradAppKitContract
import SwiftUI

/// Square, icon-only Cardinal HUD button — chamfered corners, accent glow on
/// hover. Use for compact toolbar/utility actions.
public struct AinkradIconButton: View {
    private let systemName: String
    private let action: () -> Void
    /// Button frame edge (width == height). Defaults to the historical fixed
    /// 30×30 so the original `init(systemName:action:)` keeps its exact look.
    private let size: CGFloat
    /// Self-managed hover tooltip; `nil` = no tooltip (original behavior).
    private let tooltip: String?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(systemName: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
        self.size = 30
        self.tooltip = nil
    }

    /// Tooltipped variant at the default 30×30. `tooltip` is non-defaulted, so
    /// this is a distinct mangled symbol from `init(systemName:action:)` and
    /// that existing symbol is untouched.
    ///
    /// Exists because the plain initializer takes no `tooltip:`, and the only
    /// way to get one was to also pass a `size:` — so a caller who wanted a
    /// hover hint at the default size had to restate 30 as a literal, pinning
    /// the frame against any future change to the default. Every icon-only
    /// button wants a tooltip; needing a magic number to ask for one is why
    /// callers quietly went without.
    public init(systemName: String, tooltip: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
        self.size = 30
        self.tooltip = tooltip
    }

    /// Sized (and optionally tooltipped) variant. `size` is non-defaulted, so
    /// this is a distinct mangled symbol from `init(systemName:action:)` — the
    /// existing symbol is untouched. The chamfer cut and glyph scale with `size`.
    public init(systemName: String, size: CGFloat, tooltip: String? = nil, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
        self.size = size
        self.tooltip = tooltip
    }

    /// Chamfer cut scaled off the frame — 6 at the historical 30×30.
    /// Glyph point size scaled off the frame — ~13 at the historical 30×30.
    private var glyphSize: CGFloat { size * skin.components.iconButton.glyphRatio }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            nativeBody
        } else {
            kitBody
        }
    }

    /// Glass on macOS 26+: an interactive glass circle at the caller's `size`
    /// (`.buttonStyle(.glass)` sizes itself to its label and came out 22pt at
    /// 30), with the system tooltip.
    @available(macOS 26, *)
    @ViewBuilder private var nativeBody: some View {
        let button = Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: glyphSize, weight: .medium))  // design-lint: allow font-size caller-sized glyph
                .frame(width: size, height: size)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
        if let tooltip {
            button.help(tooltip)
        } else {
            button
        }
    }

    @ViewBuilder private var kitBody: some View {
        let btn = skin.components.iconButton
        let shape = AinkradSkinShape(token: btn.shape)
        let button = Button(action: action) {
            Image(systemName: systemName)
                .font(
                    .system(size: glyphSize, weight: .semibold)  // design-lint: allow font-size caller-sized glyph
                )
                .foregroundStyle(skin.color(btn.fg, state: state))
                .frame(width: size, height: size)
                .background(shape.fill(skin.color(btn.fill, state: state)))
                .overlay(
                    shape.strokeBorder(
                        skin.color(btn.stroke.color, state: state), lineWidth: btn.stroke.width.resolve(state))
                )
                .shadow(color: skin.color(btn.glow.color, state: state), radius: btn.glow.radius.resolve(state))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? btn.hoverScale : 1.0)
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .onHover { hovering = $0 }

        if let tooltip {
            button.ainkradTooltip(tooltip)
        } else {
            button
        }
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if hovering { state.insert(.hover) }
        return state
    }
}

/// Latch-style toggle button — stays lit while `isOn` is true, distinct from
/// the switch-style `AinkradToggle`. Supply either (or both) of `systemName`
/// and `title`.
public struct AinkradToggleButton: View {
    @Binding private var isOn: Bool
    private let systemName: String?
    private let title: String?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>, systemName: String? = nil, title: String? = nil) {
        self._isOn = isOn
        self.systemName = systemName
        self.title = title
    }

    /// Mirrors the `isOn` binding — exposed for testing the latch state.
    public var isActive: Bool { isOn }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            nativeBody
        } else {
            kitBody
        }
    }

    /// Glass on macOS 26+: `.glassProminent` with the accent while latched on,
    /// `.glass` while off.
    @available(macOS 26, *)
    @ViewBuilder private var nativeBody: some View {
        let button = Button {
            isOn.toggle()
        } label: {
            if let systemName, let title {
                Label(title, systemImage: systemName)
            } else if let systemName {
                Image(systemName: systemName)
            } else if let title {
                Text(title)
            }
        }
        .controlSize(.large)
        if isActive {
            button.buttonStyle(.glassProminent).tint(skin.color(skin.palette.accentPrimary))
        } else {
            button.buttonStyle(.glass)
        }
    }

    private var kitBody: some View {
        let btn = skin.components.toggleButton
        let shape = AinkradSkinShape(token: btn.shape)
        return Button {
            isOn.toggle()
        } label: {
            HStack(spacing: skin.spacing.xs) {
                if let systemName {
                    Image(systemName: systemName).font(skin.font(btn.iconFont, typography: typo))
                }
                if let title {
                    Text(skin.labelCased(title))
                        .font(skin.font(btn.labelFont, typography: typo))
                        .tracking(btn.labelFont.tracking ?? 0)
                }
            }
            .foregroundStyle(
                isActive ? skin.color(skin.palette.accentPrimary).contrastingText : skin.color(btn.fg, state: state)
            )
            .padding(.horizontal, skin.spacing.md)
            .padding(.vertical, skin.spacing.sm)
            .background(
                shape.fill(skin.color(btn.fill, state: state))
            )
            .overlay(
                shape.strokeBorder(
                    skin.color(btn.stroke.color, state: state), lineWidth: btn.stroke.width.resolve(state))
            )
            .shadow(color: skin.color(btn.glow.color, state: state), radius: btn.glow.radius.resolve(state))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? btn.hoverScale : 1.0)
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .animation(skin.animation(skin.motion.hover), value: isActive)
        .onHover { hovering = $0 }
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if isActive { state.insert(.selected) }
        if hovering { state.insert(.hover) }
        return state
    }
}
