import AinkradAppKitContract
import SwiftUI

/// HUD list row — leading + trailing content flanking a title/subtitle,
/// hover scan + selected accent. Cardinal HUD never uses a divider line to
/// separate rows; the selected/hover states read via a leading accent bar and
/// subtle fill instead of a border between rows.
public struct AinkradListRow<Leading: View, Trailing: View>: View {
    private let isSelected: Bool
    private let onTap: (() -> Void)?
    private let leading: Leading
    private let title: String
    private let subtitle: String?
    private let trailing: Trailing

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var hovering = false

    public init(
        isSelected: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.isSelected = isSelected
        self.onTap = onTap
        self.leading = leading()
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        let row = skin.components.listRow
        HStack(spacing: skin.spacing.md) {
            leading
            // A row is a fixed-height object: one line of title, one of
            // subtitle. Without these limits a long value — a filesystem path
            // is the usual one — wraps, and a list whose row heights depend on
            // how long a string happens to be is as disorienting as a list
            // that reorders. Worse, the wrapping text also claims the row's
            // width, which starves `trailing`: a compressed badge does not
            // clip, it wraps one character per line and draws as a tall
            // stripe. `layoutPriority` settles that contest the other way, so
            // trailing accessories keep their intrinsic size and the title
            // column truncates instead.
            VStack(alignment: .leading, spacing: row.gap) {
                Text(title)
                    .font(skin.font(row.titleFont, typography: typo))
                    .foregroundStyle(skin.color(skin.text.primary))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(skin.font(row.subtitleFont, typography: typo))
                        .foregroundStyle(skin.color(row.subtitleColor))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: skin.spacing.sm)
            trailing
                .layoutPriority(1)
        }
        .padding(.horizontal, skin.spacing.md)
        .padding(.vertical, skin.spacing.sm)
        .ainkradRowBackground(isSelected: isSelected, isHovered: hovering)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .apply { if let onTap { $0.onTapGesture(perform: onTap) } else { $0 } }
    }
}

/// Key -> value HUD readout row (e.g. a stat panel line). The value renders
/// in the monospace type role, tinted by `status`.
public struct AinkradStatRow: View {
    private let label: String
    private let value: String
    private let status: AinkradStatus

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(label: String, value: String, status: AinkradStatus = .neutral) {
        self.label = label
        self.value = value
        self.status = status
    }

    private var color: Color {
        status.color(in: HostThemeTokens(skin: skin), statusColors: AinkradStatusColors(skin: skin))
    }

    public var body: some View {
        let row = skin.components.statRow
        HStack {
            Text(skin.labelCased(label))
                .font(skin.font(row.labelFont, typography: typo))
                .tracking(row.labelFont.tracking ?? 0)
                .foregroundStyle(skin.color(row.labelColor))
            Spacer(minLength: skin.spacing.md)
            Text(value)
                .font(skin.font(row.valueFont, typography: typo))
                .foregroundStyle(color)
        }
        .padding(.vertical, skin.spacing.xs)
    }
}

/// Themed SF Symbol glyph tile — `filled` swaps a plain outlined glyph for a
/// solid accent-filled chip (e.g. an active/selected state indicator).
public struct AinkradIconGlyph: View {
    private let systemName: String
    private let size: CGFloat
    private let filled: Bool

    @Environment(\.ainkradSkin) private var skin

    public init(systemName: String, size: CGFloat = 16, filled: Bool = false) {
        self.systemName = systemName
        self.size = size
        self.filled = filled
    }

    /// Glyph point size scaled off the frame — 8.8 at the historical 16×16.
    private var glyphSize: CGFloat { size * skin.components.iconGlyph.glyphRatio }

    public var body: some View {
        let glyph = skin.components.iconGlyph
        let shape = AinkradSkinShape(token: glyph.shape)
        Image(systemName: systemName)
            .font(
                .system(size: glyphSize, weight: .semibold)  // design-lint: allow font-size caller-sized glyph
            )
            .foregroundStyle(
                filled ? skin.color(skin.palette.accentPrimary).contrastingText : skin.color(glyph.glyphColor)
            )
            .frame(width: size, height: size)
            .background(
                shape.fill(filled ? skin.color(glyph.fill) : .clear)
            )
            .overlay(
                shape
                    .strokeBorder(
                        skin.color(glyph.stroke.color, state: state), lineWidth: glyph.stroke.width.resolve(state))
            )
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if filled { state.insert(.selected) }
        return state
    }
}
