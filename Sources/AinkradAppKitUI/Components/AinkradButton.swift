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
    /// Set by `borderless()`.
    var isBorderless = false
    /// Set by `secondaryAccent()`.
    var usesSecondaryAccent = false
    /// Set by `fullWidth()`.
    var fillsWidth = false
    /// Set by `outlined()`.
    var isOutlined = false
    /// Set by `compact()`.
    var isCompact = false
    /// Set by `tintedFill()`.
    var hasTintedFill = false
    /// Set by `buttonHeight(_:)`.
    var height: CGFloat?
    /// A faint mono suffix after the title, as written (`AinkradDecisionBar
    /// .Action.detail(_:)`) — kit-internal.
    var detail: String?

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

    /// No rim and no glow: under Neon a `.ghost` button becomes bare accent
    /// text on a chamfered hit area, as the mockups draw `.btn.ghost` (Cancel
    /// beside a primary). Glass's ghost is already Apple's borderless button,
    /// so this changes nothing there.
    public func borderless() -> Self {
        var copy = self
        copy.isBorderless = true
        return copy
    }

    /// The mockups' `.btn`: a `.ghost` or `.secondary` button's text (and,
    /// under Neon, its rim and glow) in the secondary accent — cyan — instead
    /// of the primary blue. Under Glass a ghost's text takes the secondary
    /// accent; a secondary stays Apple's untinted glass button, whose
    /// foreground text the mockup's Glass `.btn` matches. No effect on
    /// `.primary` or `.danger`.
    public func secondaryAccent() -> Self {
        var copy = self
        copy.usesSecondaryAccent = true
        return copy
    }

    /// Fills the width the parent proposes, label centred — the mockups'
    /// `flex: 1` halves (Grimoire's review footer: [Revert selected][Send 1
    /// comment], [Commit][Commit & open PR]). Under Glass the glass capsule
    /// stretches the same way.
    public func fullWidth() -> Self {
        var copy = self
        copy.fillsWidth = true
        return copy
    }

    /// A `.danger` (or `.primary`) button drawn as an outline instead of a
    /// solid fill — the mockups' `.btn.danger` "■ Stop": under Neon the text
    /// and rim in the danger colour on no fill; under Glass Apple's untinted
    /// glass capsule with a danger rim, as the Glass `.btn.danger` draws it.
    /// No effect on `.secondary` or `.ghost`, which are already unfilled.
    public func outlined() -> Self {
        var copy = self
        copy.isOutlined = true
        return copy
    }

    /// Under `outlined()`, a faint wash of the button's colour inside the rim
    /// instead of no fill — the dark-red body of the mockups' `.btn.danger`
    /// "■ Stop" under Neon (the danger colour at 30 %). Glass draws that button
    /// as an untinted glass capsule with a danger rim, so nothing changes
    /// there. No effect without `outlined()`.
    public func tintedFill() -> Self {
        var copy = self
        copy.hasTintedFill = true
        return copy
    }

    /// The mockups' small button (`padding: 3px 10px` — Replace All, the
    /// peek and commit-card buttons): tighter padding, same label. Under Glass
    /// Apple's small control size instead of large.
    public func compact() -> Self {
        var copy = self
        copy.isCompact = true
        return copy
    }

    /// Draws the button exactly `height` points tall, its label centred,
    /// instead of padding it — the mockups' 30 pt Replace All inside the
    /// replace field (08, `.btn`) and the 26 pt sidebar empty-state buttons
    /// (19). Horizontal padding and the label are unchanged, so it pairs with
    /// `compact()`. Under Glass the glass capsule grows to the same height.
    public func buttonHeight(_ height: CGFloat) -> Self {
        var copy = self
        copy.height = height
        return copy
    }

    /// What Apple's glass button adds round its label, measured on macOS 26:
    /// 6 pt at the small control size, 12 at the large.
    private var nativeChrome: CGFloat { isCompact ? 6 : 12 }

    /// Whether the solid accent fill is drawn: the style's, unless `outlined()`.
    private var fillsWithAccent: Bool { style.usesAccentFill && !isOutlined }

    /// Whether `tintedFill()` washes the inside of an `outlined()` button.
    private var outlineWash: Bool { hasTintedFill && isOutlined && style.usesAccentFill }

    private var accentColor: Color {
        if usesSecondaryAccent, !style.usesAccentFill { return skin.color(skin.palette.accentSecondary) }
        return skin.color(style.isDanger ? skin.palette.danger : skin.palette.accentPrimary)
    }
    private var foreground: Color { fillsWithAccent ? accentColor.contrastingText : accentColor }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            nativeBody
        } else {
            kitBody
        }
    }

    /// Glass on macOS 26+: Apple's own button. Primary and danger are
    /// `.glassProminent` tinted with the accent (danger: the danger colour and
    /// the destructive role), secondary is untinted `.glass`, ghost is
    /// `.borderless` accent text.
    @available(macOS 26, *)
    @ViewBuilder private var nativeBody: some View {
        let button = Button(role: style.isDanger ? .destructive : nil, action: action) {
            ZStack {
                nativeLabel.opacity(isLoading ? 0 : 1)
                ProgressView().controlSize(.small).opacity(isLoading ? 1 : 0)
            }
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(height: height.map { max(0, $0 - nativeChrome) })
        }
        .disabled(isLoading)
        .controlSize(isCompact ? .small : .large)
        // Apple's small glass button is a rounded rectangle; the mockup's stays a capsule.
        .buttonBorderShape(isCompact ? .capsule : .automatic)
        // Only the prominent styles take the tint: on `.glass` a tint fills the
        // whole capsule, which would make secondary read as primary.
        switch style {
        case .primary where isOutlined, .danger where isOutlined:
            button.buttonStyle(.glass).overlay {
                Capsule().strokeBorder(accentColor.opacity(skin.opacity.o50), lineWidth: 1).allowsHitTesting(false)
            }
        case .primary, .danger: button.buttonStyle(.glassProminent).tint(accentColor)
        case .secondary: button.buttonStyle(.glass)
        case .ghost: button.buttonStyle(.borderless).tint(accentColor)
        }
    }

    @ViewBuilder private var nativeLabel: some View {
        if let detail {
            Text(title)
                + Text(" " + detail)
                .font(AinkradFontResolver.font(size: 11, mono: true, typography: typo))
                .foregroundStyle(skin.color(skin.text.faint))
        } else if let icon {
            Label(title, systemImage: icon)
        } else {
            Text(title)
        }
    }

    private var kitBody: some View {
        let btn = skin.components.button
        let shape = AinkradSkinShape(token: btn.shape)
        return Button(action: action) {
            ZStack {
                // Both mounted; only opacity toggles so the label and spinner
                // crossfade in place (no layout jump).
                labelContent
                    .foregroundStyle(foreground)
                    .opacity(isLoading ? 0 : 1)
                AinkradSpinner(size: btn.spinnerSize, tint: foreground)
                    .opacity(isLoading ? 1 : 0)
            }
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .padding(.horizontal, isCompact ? skin.size.s10 : skin.spacing.lg)
            .modifier(FieldHeight(height: height, padding: isCompact ? skin.size.s3 : skin.spacing.sm))
            .background(
                shape.fill(
                    fillsWithAccent
                        ? accentColor.opacity(style.fillOpacity)
                        : outlineWash ? accentColor.opacity(skin.opacity.o30) : .clear)
            )
            .overlay(
                shape.strokeBorder(
                    isBorderless ? .clear : skin.color(btn.stroke.color, tint: accentColor, state: state),
                    lineWidth: btn.stroke.width.resolve(state)
                )
            )
            .shadow(
                color: isBorderless ? .clear : skin.color(btn.glow.color, tint: accentColor, state: state),
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
            Text(skin.labelCased(title))
                .font(skin.font(btn.labelFont, typography: typo))
                .tracking(btn.labelFont.tracking ?? 0)
            if let detail {
                Text(detail)
                    .font(AinkradFontResolver.font(size: 11, mono: true, typography: typo))
                    .foregroundStyle(skin.color(skin.text.faint))
            }
        }
    }
    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if hovering { state.insert(.hover) }
        if pressed { state.insert(.pressed) }
        return state
    }
}
