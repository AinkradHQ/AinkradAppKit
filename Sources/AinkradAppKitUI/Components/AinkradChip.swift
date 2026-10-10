import AinkradAppKitContract
import SwiftUI

/// Semantic status used by `AinkradBadge` (and available to any component
/// that needs a status→color mapping). `.neutral` maps onto `HostThemeTokens`;
/// the other cases map onto the ABI-safe `AinkradStatusColors` channel.
public enum AinkradStatus: CaseIterable, Sendable {
    case neutral, success, warning, danger

    /// The color this status maps to. Pure — unit-testable without a view.
    public func color(in theme: HostThemeTokens, statusColors: AinkradStatusColors) -> Color {
        switch self {
        case .neutral: return theme.foreground
        case .success: return statusColors.success
        case .warning: return statusColors.warning
        case .danger: return statusColors.danger
        }
    }

}

/// Pill/chamfer tag — optional leading icon, optional custom-drawn remove (✕)
/// affordance (never a native button chrome).
public struct AinkradChip: View {
    private let label: String
    private let systemName: String?
    private let onRemove: (() -> Void)?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(label: String, systemName: String? = nil, onRemove: (() -> Void)? = nil) {
        self.label = label
        self.systemName = systemName
        self.onRemove = onRemove
    }

    /// Whether this chip shows a remove affordance.
    public var isRemovable: Bool { onRemove != nil }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: a glass capsule tag with a borderless remove.
            HStack(spacing: skin.spacing.xs) {
                if let systemName { Image(systemName: systemName) }
                Text(label)
                if isRemovable {
                    Button {
                        onRemove?()
                    } label: {
                        Image(systemName: "xmark").imageScale(.small)
                    }
                    .buttonStyle(.borderless)
                    .help("Remove")
                }
            }
            .font(.callout)
            .padding(.horizontal, skin.spacing.sm)
            .padding(.vertical, skin.spacing.xs)
            .glassEffect(.regular, in: .capsule)
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let chip = skin.components.chip
        let shape = AinkradSkinShape(token: chip.shape)
        return HStack(spacing: skin.spacing.xs) {
            if let systemName {
                Image(systemName: systemName).font(skin.font(chip.iconFont, typography: typo))
            }
            Text(label)
                .font(skin.font(chip.labelFont, typography: typo))
            if isRemovable {
                Image(systemName: "xmark")
                    .font(skin.font(chip.removeFont, typography: typo))
                    .padding(chip.removePadding)
                    .contentShape(Rectangle())
                    .onTapGesture { onRemove?() }
            }
        }
        .foregroundStyle(skin.color(chip.fg, state: state))
        .padding(.horizontal, skin.spacing.sm)
        .padding(.vertical, skin.spacing.xs)
        .background(shape.fill(skin.color(chip.fill, state: state)))
        .overlay(
            shape.strokeBorder(
                skin.color(chip.stroke.color, state: state), lineWidth: chip.stroke.width.resolve(state))
        )
        .scaleEffect(hovering && !reduceMotion ? chip.hoverScale : 1.0)
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .onHover { hovering = $0 }
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if hovering { state.insert(.hover) }
        return state
    }
}

/// Small chamfered color swatch — the leading dot shared by color-labeled
/// picker rows (`AinkradSelect`/`AinkradMultiSelect`'s `swatch:` overloads) and
/// `AinkradSwatchChip`. Internal; not part of the plugin ABI surface.
struct ColorSwatchDot: View {
    let color: Color
    var size: CGFloat = 10

    @Environment(\.ainkradSkin) private var skin

    var body: some View {
        let swatch = skin.components.swatchChip
        let shape = AinkradSkinShape(token: swatch.swatchShape)
        shape
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                shape.strokeBorder(
                    skin.color(swatch.swatchStroke.color), lineWidth: swatch.swatchStroke.width.resolve([]))
            )
    }
}

/// Chip carrying a leading color swatch — for GitHub-label filter bars. Renders
/// a `ColorSwatchDot` before the label; when `onTap` is supplied it behaves as a
/// toggle chip (`isOn` drives the lit/selected treatment). NEW public type,
/// purely additive — old plugins never reference it.
public struct AinkradSwatchChip: View {
    private let label: String
    private let swatch: Color
    private let isOn: Bool
    private let onTap: (() -> Void)?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(label: String, swatch: Color, isOn: Bool = false, onTap: (() -> Void)? = nil) {
        self.label = label
        self.swatch = swatch
        self.isOn = isOn
        self.onTap = onTap
    }

    /// Whether this chip behaves as a tappable toggle (vs. a static tag).
    public var isToggle: Bool { onTap != nil }

    @ViewBuilder public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            nativeBody
        } else {
            kitBody
        }
    }

    /// Glass on macOS 26+: a glass capsule; a toggle chip is a `.glass`
    /// button, `.glassProminent` with the accent while on (a glass tint alone
    /// was too faint to read as on).
    @available(macOS 26, *)
    @ViewBuilder private var nativeBody: some View {
        let content = HStack(spacing: skin.spacing.xs) {
            ColorSwatchDot(color: swatch, size: skin.components.swatchChip.swatchSize)
            Text(label)
        }
        .font(.callout)
        if let onTap, isOn {
            Button(action: onTap) { content }
                .buttonStyle(.glassProminent)
                .tint(skin.color(skin.palette.accentPrimary))
        } else if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.glass)
        } else if isOn {
            content
                .foregroundStyle(skin.color(skin.palette.accentPrimary).contrastingText)
                .padding(.horizontal, skin.spacing.sm)
                .padding(.vertical, skin.spacing.xs)
                .background(skin.color(skin.palette.accentPrimary), in: .capsule)
        } else {
            content
                .padding(.horizontal, skin.spacing.sm)
                .padding(.vertical, skin.spacing.xs)
                .glassEffect(.regular, in: .capsule)
        }
    }

    @ViewBuilder private var kitBody: some View {
        let chip = skin.components.chip
        let swatchTokens = skin.components.swatchChip
        let shape = AinkradSkinShape(token: swatchTokens.shape)
        let content = HStack(spacing: skin.spacing.xs) {
            ColorSwatchDot(color: swatch, size: swatchTokens.swatchSize)
            Text(label)
                .font(skin.font(chip.labelFont, typography: typo))
        }
        .foregroundStyle(skin.color(chip.fg, state: state))
        .padding(.horizontal, skin.spacing.sm)
        .padding(.vertical, skin.spacing.xs)
        .background(shape.fill(skin.color(chip.fill, state: state)))
        .overlay(
            shape.strokeBorder(
                skin.color(swatchTokens.stroke.color, state: state), lineWidth: swatchTokens.stroke.width.resolve(state)
            )
        )
        .shadow(
            color: skin.color(swatchTokens.glow.color, state: state), radius: swatchTokens.glow.radius.resolve(state)
        )
        .scaleEffect(hovering && !reduceMotion ? chip.hoverScale : 1.0)
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .animation(skin.animation(skin.motion.hover), value: isOn)
        .contentShape(shape)
        .onHover { hovering = $0 }

        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if isOn { state.insert(.selected) }
        if hovering { state.insert(.hover) }
        return state
    }
}

/// Small status pill — filled with the status color at low opacity, text in
/// the status color.
public struct AinkradBadge: View {
    private let text: String
    private let status: AinkradStatus
    /// When non-nil, the badge derives its fill/text/border straight from this
    /// tint instead of the `status`→color mapping (for accent pills like
    /// GitMage's open/merged states and AUTHOR/current badges). Stored at the
    /// END with a default so the original `init(text:status:)` is unchanged.
    private let tint: Color?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(text: String, status: AinkradStatus = .neutral) {
        self.text = text
        self.status = status
        self.tint = nil
    }

    /// Tint-driven variant — distinct symbol from `init(text:status:)`
    /// (different second label). Mirrors the status version's fill/text/border
    /// opacities, sourced from `tint`.
    public init(text: String, tint: Color) {
        self.text = text
        self.status = .neutral
        self.tint = tint
    }

    private var color: Color {
        tint ?? status.color(in: HostThemeTokens(skin: skin), statusColors: AinkradStatusColors(skin: skin))
    }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: the system tag look — a tinted capsule.
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(color)
                .padding(.horizontal, skin.spacing.sm)
                .padding(.vertical, skin.spacing.xs / 2)
                .background(color.opacity(skin.opacity.o18), in: .capsule)
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let badge = skin.components.badge
        let shape = AinkradSkinShape(token: badge.shape)
        return Text(skin.labelCased(text))
            .font(skin.font(badge.font, typography: typo))
            .tracking(badge.font.tracking ?? 0)
            .foregroundStyle(color)
            .padding(.horizontal, skin.spacing.sm)
            .padding(.vertical, skin.spacing.xs / 2)
            .background(shape.fill(skin.color(badge.fill, tint: color)))
            .overlay(
                shape.strokeBorder(
                    skin.color(badge.stroke.color, tint: color),
                    lineWidth: badge.stroke.width.resolve([])
                )
            )
    }
}

/// Keycap chip — monospaced, bracketed, for displaying a keyboard shortcut.
public struct AinkradKbd: View {
    private let key: String

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(_ key: String) {
        self.key = key
    }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: a plain keycap, the glyphs as menus show them.
            Text(key)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, kbd.paddingH)
                .padding(.vertical, kbd.paddingV)
                .background(.quaternary, in: .rect(cornerRadius: kbd.paddingH))
        } else {
            kitBody
        }
    }

    private var kbd: KbdTokens { skin.components.kbd }

    private var kitBody: some View {
        let kbd = skin.components.kbd
        let shape = AinkradSkinShape(token: kbd.shape)
        return Text("[\(key)]")
            .font(skin.font(kbd.font, typography: typo))
            .foregroundStyle(skin.color(kbd.color))
            .padding(.horizontal, kbd.paddingH)
            .padding(.vertical, kbd.paddingV)
            .background(shape.fill(skin.color(kbd.fill)))
            .overlay(
                shape.strokeBorder(
                    skin.color(kbd.stroke.color), lineWidth: kbd.stroke.width.resolve([])
                )
            )
    }
}
