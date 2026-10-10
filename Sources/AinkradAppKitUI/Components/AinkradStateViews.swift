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
    @Environment(\.ainkradSkin) private var skin
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
        let empty = skin.components.emptyState
        VStack(spacing: skin.spacing.md) {
            Image(systemName: icon)
                .font(skin.font(empty.glyphFont, typography: typo))
                .foregroundStyle(skin.color(empty.glyphColor))
            VStack(spacing: skin.spacing.xs) {
                Text(title)
                    .font(skin.font(empty.titleFont, typography: typo))
                    .foregroundStyle(skin.color(skin.text.primary))
                Text(message)
                    .font(skin.font(empty.messageFont, typography: typo))
                    .foregroundStyle(skin.color(empty.messageColor))
                    .multilineTextAlignment(.center)
            }
            if hasAction, let actionTitle, let action {
                AinkradButton(title: actionTitle, style: .primary, action: action)
                    .padding(.top, skin.spacing.xs)
            }
        }
        .padding(skin.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Centered progress indicator with an optional label, using the theme's
/// accent tint.
public struct AinkradLoadingState: View {
    private let label: String?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(label: String? = nil) { self.label = label }

    public var body: some View {
        let loading = skin.components.loadingState
        VStack(spacing: skin.spacing.sm) {
            AinkradSpinner(size: loading.spinnerSize)
            if let label {
                Text(label)
                    .font(skin.font(loading.captionFont, typography: typo))
                    .foregroundStyle(skin.color(loading.captionColor))
            }
        }
        .padding(skin.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Centered error placeholder with an optional retry action.
public struct AinkradErrorState: View {
    private let message: String
    private let retryTitle: String?
    private let retry: (() -> Void)?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(message: String, retryTitle: String? = nil, retry: (() -> Void)? = nil) {
        self.message = message
        self.retryTitle = retryTitle
        self.retry = retry
    }
    /// Whether a retry action is present.
    public var hasRetry: Bool { retry != nil && retryTitle != nil }

    public var body: some View {
        let error = skin.components.errorState
        let shape = AinkradSkinShape(token: error.shape)
        VStack(spacing: skin.spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(skin.font(error.glyphFont, typography: typo))
                .foregroundStyle(skin.color(error.glyphColor))
                .padding(skin.spacing.md)
                .background(shape.fill(skin.color(error.fill)))
                .overlay(
                    shape.strokeBorder(
                        skin.color(error.stroke.color), lineWidth: error.stroke.width.resolve([])))
            Text(message)
                .font(skin.font(error.messageFont, typography: typo))
                .foregroundStyle(skin.color(error.messageColor))
                .multilineTextAlignment(.center)
            if hasRetry, let retryTitle, let retry {
                AinkradButton(title: retryTitle, style: .secondary, icon: "arrow.clockwise", action: retry)
            }
        }
        .padding(skin.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Uppercased caption-weight section label. No separator line — matches the
/// "no separator lines" design rule shared across the SDK.
public struct AinkradSectionHeader: View {
    private let title: String
    private let subtitle: String?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    public var body: some View {
        let header = skin.components.sectionHeader
        VStack(alignment: .leading, spacing: skin.spacing.xs / 2) {
            HStack(spacing: skin.spacing.xs) {
                Rectangle()
                    .fill(skin.color(skin.roles.accentTick.fill))
                    .frame(width: header.tickWidth, height: header.tickHeight)
                    .shadow(
                        color: skin.color(skin.roles.accentTick.glow.color),
                        radius: skin.roles.accentTick.glow.radius.resolve([]))
                Text(skin.labelCased(title))
                    .font(skin.font(header.titleFont, typography: typo))
                    .foregroundStyle(skin.color(header.titleColor))
                    .tracking(header.titleFont.tracking ?? 0)
            }
            if let subtitle {
                Text(subtitle)
                    .font(skin.font(header.subtitleFont, typography: typo))
                    .foregroundStyle(skin.color(header.subtitleColor))
                    .padding(.leading, header.tickWidth + skin.spacing.xs)
            }
        }
        .padding(.horizontal, skin.spacing.sm)
        .padding(.top, skin.spacing.sm)
    }
}
