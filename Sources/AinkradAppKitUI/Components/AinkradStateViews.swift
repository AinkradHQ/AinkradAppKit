import AinkradAppKitContract
import SwiftUI

/// Centered empty-state placeholder: icon, title, message, and an optional
/// call-to-action button. Consolidates the various "nothing here yet" views.
public struct AinkradEmptyState: View {
    private let icon: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(
        icon: String, title: String, message: String,
        actionTitle: String? = nil, action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    /// Whether a call-to-action button is present.
    public var hasAction: Bool { action != nil && actionTitle != nil }

    public var body: some View {
        VStack(spacing: AinkradSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: AinkradTypeRole.display.size))
                .foregroundStyle(theme.foreground.opacity(0.35))
            VStack(spacing: AinkradSpacing.xs) {
                Text(title)
                    .font(AinkradFontResolver.font(.headline, weight: .medium, typography: typo))
                    .foregroundStyle(theme.foreground)
                Text(message)
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            if hasAction, let actionTitle, let action {
                AinkradButton(title: actionTitle, style: .primary, action: action)
                    .padding(.top, AinkradSpacing.xs)
            }
        }
        .padding(AinkradSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Centered progress indicator with an optional label, using the theme's
/// accent tint.
public struct AinkradLoadingState: View {
    private let label: String?
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(label: String? = nil) { self.label = label }

    public var body: some View {
        VStack(spacing: AinkradSpacing.sm) {
            AinkradSpinner(size: 28)
            if let label {
                Text(label)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.6))
            }
        }
        .padding(AinkradSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Centered error placeholder with an optional retry action.
public struct AinkradErrorState: View {
    private let message: String
    private let retryTitle: String?
    private let retry: (() -> Void)?
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors

    public init(message: String, retryTitle: String? = nil, retry: (() -> Void)? = nil) {
        self.message = message
        self.retryTitle = retryTitle
        self.retry = retry
    }
    /// Whether a retry action is present.
    public var hasRetry: Bool { retry != nil && retryTitle != nil }

    public var body: some View {
        VStack(spacing: AinkradSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: AinkradTypeRole.title.size))
                .foregroundStyle(statusColors.danger)
                .padding(AinkradSpacing.md)
                .background(ChamferShape(cut: 8).fill(statusColors.danger.opacity(0.12)))
                .overlay(ChamferShape(cut: 8).strokeBorder(statusColors.danger.opacity(0.45), lineWidth: 1.25))
            Text(message)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.75))
                .multilineTextAlignment(.center)
            if hasRetry, let retryTitle, let retry {
                AinkradButton(title: retryTitle, style: .secondary, icon: "arrow.clockwise", action: retry)
            }
        }
        .padding(AinkradSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Uppercased caption-weight section label. No separator line — matches the
/// "no separator lines" design rule shared across the SDK.
public struct AinkradSectionHeader: View {
    private let title: String
    private let subtitle: String?
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
            HStack(spacing: AinkradSpacing.xs) {
                Rectangle()
                    .fill(theme.accentSecondary)
                    .frame(width: 12, height: 2)
                    .shadow(color: theme.accentSecondary.opacity(0.6), radius: 2)
                Text(title.uppercased())
                    .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.65))
                    .tracking(1.2)
            }
            if let subtitle {
                Text(subtitle)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.4))
                    .padding(.leading, 12 + AinkradSpacing.xs)
            }
        }
        .padding(.horizontal, AinkradSpacing.sm)
        .padding(.top, AinkradSpacing.sm)
    }
}
