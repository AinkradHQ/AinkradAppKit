import AinkradAppKitContract
import SwiftUI

/// Visual treatment for `AinkradButton`. Pure mapping to fill/border/danger
/// intent so the logic is unit-testable without instantiating any SwiftUI view.
public enum AinkradButtonStyle: CaseIterable, Sendable {
    case primary, secondary, ghost, danger

    /// Whether this style paints a solid accent-tinted fill (vs. border-only).
    public var usesAccentFill: Bool {
        switch self {
        case .primary, .danger: return true
        case .secondary, .ghost: return false
        }
    }

    /// Opacity of the background fill; `0` for border-only styles (e.g. `ghost`).
    public var fillOpacity: Double {
        switch self {
        case .primary: return 0.9
        case .secondary: return 0.5
        case .ghost: return 0
        case .danger: return 0.85
        }
    }

    /// Whether this style should read using the theme's `danger` color.
    public var isDanger: Bool {
        self == .danger
    }
}

/// Cardinal HUD action button — chamfered silhouette, accent glow, hover
/// brighten, and a subtle press scale. Reads all color from
/// `@Environment(\.ainkradTheme)`; `danger` uses `ainkradStatusColors.danger`.
public struct AinkradButton: View {
    private let title: String
    private let style: AinkradButtonStyle
    private let icon: String?
    private let action: () -> Void
    /// When `true`, the label crossfades to an in-place `AinkradSpinner` and the
    /// button is disabled. Additive stored field with a default so the existing
    /// `init(title:style:icon:action:)` stays byte-unchanged — see the
    /// `isLoading:`-carrying overload below.
    private var isLoading: Bool = false

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var pressed = false

    public init(
        title: String, style: AinkradButtonStyle = .primary, icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.action = action
    }

    /// Loading-capable variant. When `isLoading` is `true` the label crossfades
    /// in place to an `AinkradSpinner` tinted to the button's foreground and the
    /// button is disabled. NEW overload — `isLoading:` has NO default, so this is
    /// a distinct symbol from `init(title:style:icon:action:)`, which is untouched.
    public init(
        title: String, style: AinkradButtonStyle = .primary, icon: String? = nil,
        isLoading: Bool, action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    private var accentColor: Color {
        skin.color(style.isDanger ? skin.palette.danger : skin.palette.accentPrimary)
    }
    private var foreground: Color { style.usesAccentFill ? accentColor.contrastingText : accentColor }

    public var body: some View {
        let btn = skin.components.button
        let shape = AinkradSkinShape(token: btn.shape)
        Button(action: action) {
            ZStack {
                // Both mounted; only opacity toggles so the label and spinner
                // crossfade in place (no layout jump).
                labelContent
                    .foregroundStyle(foreground)
                    .opacity(isLoading ? 0 : 1)
                AinkradSpinner(size: btn.spinnerSize, tint: foreground)
                    .opacity(isLoading ? 1 : 0)
            }
            .padding(.horizontal, skin.spacing.lg)
            .padding(.vertical, skin.spacing.sm)
            .background(
                shape.fill(style.usesAccentFill ? accentColor.opacity(style.fillOpacity) : .clear)
            )
            .overlay(
                shape.strokeBorder(
                    skin.color(btn.stroke.color, tint: accentColor, state: state),
                    lineWidth: btn.stroke.width.resolve(state)
                )
            )
            .shadow(
                color: skin.color(btn.glow.color, tint: accentColor, state: state),
                radius: btn.glow.radius.resolve(state)
            )
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: isLoading)
        .scaleEffect(pressed && !reduceMotion ? btn.pressedScale : (hovering && !reduceMotion ? btn.hoverScale : 1.0))
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .animation(skin.animation(skin.motion.hover), value: pressed)
        .onHover { hovering = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }

    private var labelContent: some View {
        let btn = skin.components.button
        return HStack(spacing: skin.spacing.xs) {
            if let icon {
                Image(systemName: icon).font(skin.font(btn.iconFont, typography: typo))
            }
            Text(title.uppercased())
                .font(skin.font(btn.labelFont, typography: typo))
                .tracking(btn.labelFont.tracking ?? 0)
        }
    }
    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if hovering { state.insert(.hover) }
        if pressed { state.insert(.pressed) }
        return state
    }
}
