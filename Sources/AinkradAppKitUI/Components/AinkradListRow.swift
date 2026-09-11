import SwiftUI
import AinkradAppKitContract

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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
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

    private var accentWidth: CGFloat { isSelected || hovering ? 2 : 0 }

    public var body: some View {
        HStack(spacing: AinkradSpacing.md) {
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
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AinkradFontResolver.font(.body, weight: .medium, typography: typo))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(AinkradFontResolver.font(.caption, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.55))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: AinkradSpacing.sm)
            trailing
                .layoutPriority(1)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 6).fill(rowFill))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(theme.accentSecondary)
                .frame(width: accentWidth)
                .shadow(color: theme.accentSecondary.opacity(isSelected ? 0.6 : 0), radius: 3)
        }
        .clipShape(ChamferShape(cut: 6))
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: hovering)
        .apply { if let onTap { $0.onTapGesture(perform: onTap) } else { $0 } }
    }

    private var rowFill: Color {
        if isSelected { return theme.accentPrimary.opacity(0.16) }
        if hovering { return theme.surfaceElevated.opacity(0.5) }
        return .clear
    }
}

/// Key -> value HUD readout row (e.g. a stat panel line). The value renders
/// in the monospace type role, tinted by `status`.
public struct AinkradStatRow: View {
    private let label: String
    private let value: String
    private let status: AinkradStatus

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradTypography) private var typo

    public init(label: String, value: String, status: AinkradStatus = .neutral) {
        self.label = label
        self.value = value
        self.status = status
    }

    private var color: Color { status.color(in: theme, statusColors: statusColors) }

    public var body: some View {
        HStack {
            Text(label.uppercased())
                .font(AinkradFontResolver.font(.caption, typography: typo))
                .tracking(0.6)
                .foregroundStyle(theme.foreground.opacity(0.6))
            Spacer(minLength: AinkradSpacing.md)
            Text(value)
                .font(AinkradFontResolver.font(.mono, weight: .medium, typography: typo))
                .foregroundStyle(color)
        }
        .padding(.vertical, AinkradSpacing.xs)
    }
}

/// Themed SF Symbol glyph tile — `filled` swaps a plain outlined glyph for a
/// solid accent-filled chip (e.g. an active/selected state indicator).
public struct AinkradIconGlyph: View {
    private let systemName: String
    private let size: CGFloat
    private let filled: Bool

    @Environment(\.ainkradTheme) private var theme

    public init(systemName: String, size: CGFloat = 16, filled: Bool = false) {
        self.systemName = systemName
        self.size = size
        self.filled = filled
    }

    public var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(filled ? theme.accentPrimary.contrastingText : theme.accentSecondary)
            .frame(width: size, height: size)
            .background(
                ChamferShape(cut: max(2, size * 0.2)).fill(filled ? theme.accentPrimary.opacity(0.85) : .clear)
            )
            .overlay(
                ChamferShape(cut: max(2, size * 0.2))
                    .strokeBorder(theme.accentSecondary.opacity(filled ? 0 : 0.4), lineWidth: 1)
            )
    }
}
