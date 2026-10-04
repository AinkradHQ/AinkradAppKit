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

    @Environment(\.ainkradTheme) private var theme
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
        HStack(spacing: AinkradSpacing.xs) {
            if let systemName {
                Image(systemName: systemName).font(.system(size: 10, weight: .semibold))
            }
            Text(label)
                .font(AinkradFontResolver.font(.caption, typography: typo))
            if isRemovable {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .padding(3)
                    .contentShape(Rectangle())
                    .onTapGesture { onRemove?() }
            }
        }
        .foregroundStyle(theme.foreground.opacity(0.85))
        .padding(.horizontal, AinkradSpacing.sm)
        .padding(.vertical, AinkradSpacing.xs)
        .background(ChamferShape(cut: 5).fill(theme.surfaceElevated.opacity(hovering ? 0.65 : 0.45)))
        .overlay(ChamferShape(cut: 5).strokeBorder(theme.accentSecondary.opacity(hovering ? 0.6 : 0.3), lineWidth: 1))
        .scaleEffect(hovering && !reduceMotion ? 1.03 : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// Small chamfered color swatch — the leading dot shared by color-labeled
/// picker rows (`AinkradSelect`/`AinkradMultiSelect`'s `swatch:` overloads) and
/// `AinkradSwatchChip`. Internal; not part of the plugin ABI surface.
struct ColorSwatchDot: View {
    let color: Color
    var size: CGFloat = 10

    @Environment(\.ainkradTheme) private var theme

    var body: some View {
        ChamferShape(cut: 2, corners: .all)
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                ChamferShape(cut: 2, corners: .all)
                    .strokeBorder(theme.foreground.opacity(0.25), lineWidth: 0.5)
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

    @Environment(\.ainkradTheme) private var theme
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

    private var borderColor: Color { isOn ? theme.accentPrimary : theme.accentSecondary }

    public var body: some View {
        let content = HStack(spacing: AinkradSpacing.xs) {
            ColorSwatchDot(color: swatch)
            Text(label)
                .font(AinkradFontResolver.font(.caption, typography: typo))
        }
        .foregroundStyle(theme.foreground.opacity(isOn ? 1 : 0.85))
        .padding(.horizontal, AinkradSpacing.sm)
        .padding(.vertical, AinkradSpacing.xs)
        .background(ChamferShape(cut: 5).fill(theme.surfaceElevated.opacity(isOn ? 0.8 : (hovering ? 0.65 : 0.45))))
        .overlay(
            ChamferShape(cut: 5).strokeBorder(
                borderColor.opacity(isOn ? 0.85 : (hovering ? 0.6 : 0.3)), lineWidth: isOn ? 1.25 : 1)
        )
        .shadow(color: theme.accentPrimary.opacity(isOn ? 0.3 : 0), radius: isOn ? 4 : 0)
        .scaleEffect(hovering && !reduceMotion ? 1.03 : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .animation(AinkradMotion.hover, value: isOn)
        .contentShape(ChamferShape(cut: 5))
        .onHover { hovering = $0 }

        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
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

    private var color: Color { tint ?? status.color(in: theme, statusColors: statusColors) }

    public var body: some View {
        Text(text.uppercased())
            .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
            .tracking(0.6)
            .foregroundStyle(color)
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs / 2)
            .background(ChamferShape(cut: 4).fill(color.opacity(0.16)))
            .overlay(ChamferShape(cut: 4).strokeBorder(color.opacity(0.55), lineWidth: 1))
    }
}

/// Keycap chip — monospaced, bracketed, for displaying a keyboard shortcut.
public struct AinkradKbd: View {
    private let key: String

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(_ key: String) {
        self.key = key
    }

    public var body: some View {
        Text("[\(key)]")
            .font(AinkradFontResolver.font(.mono, weight: .medium, typography: typo))
            .foregroundStyle(theme.foreground.opacity(0.75))
            .padding(.horizontal, AinkradSpacing.xs + 2)
            .padding(.vertical, 2)
            .background(ChamferShape(cut: 3).fill(theme.surfaceElevated.opacity(0.55)))
            .overlay(ChamferShape(cut: 3).strokeBorder(theme.foreground.opacity(0.2), lineWidth: 1))
    }
}
