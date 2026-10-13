import AinkradAppKitContract
import SwiftUI

/// Centered empty-state placeholder: icon, title, message, and an optional
/// call-to-action button. Consolidates the various "nothing here yet" views.
public struct AinkradEmptyState: View {
    /// One shortcut of a key-hint empty state: a keycap and what it does.
    public struct KeyHint: Equatable, Sendable {
        public let keys: String
        public let label: String

        public init(keys: String, label: String) {
            self.keys = keys
            self.label = label
        }
    }

    private let icon: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    // Set by `secondaryAction(_:action:)` — a modifier, not an init parameter,
    // because a defaulted parameter is not ABI-compatible.
    var secondaryTitle: String?
    var secondary: (() -> Void)?
    /// Set by `glyph(_:)` and `iconTint(_:)`.
    var textGlyph: String?
    var tint: Color?
    /// Set by `glyphSize(_:)`.
    var glyphSize: CGFloat?
    /// Set by `secondaryAccent()`.
    var usesSecondaryAccent = false
    /// Set by `init(icon:keyHints:)`.
    var keyHints: [KeyHint] = []
    /// Set by `compact()`.
    var isCompact = false
    /// Set by `buttonHeight(_:)`.
    var buttonHeight: CGFloat?
    /// Set by `plainPrimary()`.
    var usesPlainPrimary = false
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
    /// No title and no message: the icon over one line of shortcuts, each an
    /// outlined keycap and its action, joined by `·` — Forge's empty editor
    /// (mockup 19 A, FP108: `⌘P open a file · ⌘⇧P commands · ⌃⌘O switch
    /// workspace`). Under Glass the same layout, since Apple's
    /// content-unavailable view needs a title. Pair with `glyph(_:)` and
    /// `iconTint(_:)` for the faint ⚒.
    public init(icon: String, keyHints: [KeyHint]) {
        self.init(icon: icon, title: "", message: "")
        self.keyHints = keyHints
    }

    /// Whether a call-to-action button is present.
    public var hasAction: Bool { action != nil && actionTitle != nil }
    /// Whether a secondary button is present.
    public var hasSecondaryAction: Bool { secondary != nil && secondaryTitle != nil }

    /// Adds a secondary button beside the call-to-action (on its leading side,
    /// as macOS orders a pair), e.g. "Open folder…" next to "New thread".
    public func secondaryAction(_ title: String, action: @escaping () -> Void) -> Self {
        var copy = self
        copy.secondaryTitle = title
        copy.secondary = action
        return copy
    }

    /// Draws a text glyph (`"❖"`, `"⚒"`) in place of the SF Symbol `icon`,
    /// as the mockups' `.empty .glyph` (Grimoire's no-threads state, Forge's
    /// empty editor).
    public func glyph(_ glyph: String) -> Self {
        var copy = self
        copy.textGlyph = glyph
        return copy
    }

    /// Colours the icon or glyph — e.g. the secondary accent at 80 %, the
    /// mockups' cyan glyph — instead of the skin's faint foreground.
    public func iconTint(_ color: Color) -> Self {
        var copy = self
        copy.tint = color
        return copy
    }

    /// Draws the icon or glyph at `size` points instead of the skin's display
    /// size — Grimoire's no-threads ❖ at 40 (mockup 09 B), Forge's empty
    /// editor ⚒ at 34 (mockup 19). Under Glass too.
    public func glyphSize(_ size: CGFloat) -> Self {
        var copy = self
        copy.glyphSize = size
        return copy
    }

    /// Draws the buttons with `AinkradButton.secondaryAccent()`: the
    /// secondary button's text and rim in the cyan secondary accent, as
    /// Grimoire's no-threads "Open folder…" (GP44). The primary is unchanged.
    public func secondaryAccent() -> Self {
        var copy = self
        copy.usesSecondaryAccent = true
        return copy
    }

    /// The mockups' sidebar empty state (`.sempty`, mockup 19): a 26 pt
    /// glyph, a 13 pt bold title, a 12 pt message at 1.5 line height, and
    /// compact buttons, 8 pt apart, sitting a little above centre. Neon and
    /// Glass alike — Apple's content-unavailable view has no small size.
    public func compact() -> Self {
        var copy = self
        copy.isCompact = true
        return copy
    }

    /// Draws the buttons exactly `height` points tall
    /// (`AinkradButton.buttonHeight(_:)`) — mockup 19's 26 pt sidebar
    /// empty-state buttons, with `compact()`. Neon and Glass.
    public func buttonHeight(_ height: CGFloat) -> Self {
        var copy = self
        copy.buttonHeight = height
        return copy
    }

    /// Draws the call-to-action unfilled, as the mockups' plain `.btn`: a
    /// `.secondary` button in the secondary accent (cyan text and rim under
    /// Neon, Apple's untinted glass button under Glass) — mockup 19's sidebar
    /// empty states, where no button is filled. The secondary is unchanged.
    public func plainPrimary() -> Self {
        var copy = self
        copy.usesPlainPrimary = true
        return copy
    }

    /// The call-to-action button: `plainPrimary()`'s, else a `.primary`.
    private func primaryButton(_ title: String, action: @escaping () -> Void) -> AinkradButton {
        usesPlainPrimary
            ? sized(AinkradButton(title: title, style: .secondary, action: action).secondaryAccent())
            : sized(AinkradButton(title: title, style: .primary, action: action))
    }

    /// `button` at `buttonHeight(_:)`, if one is set.
    private func sized(_ button: AinkradButton) -> AinkradButton {
        var copy = button
        copy.height = buttonHeight
        return copy
    }

    @ViewBuilder private var iconView: some View {
        if let textGlyph {
            // A text glyph takes no symbol sizing (Glass): give it the display font.
            Text(textGlyph).font(glyphFont)
        } else if glyphSize != nil {
            Image(systemName: icon).font(glyphFont)
        } else {
            Image(systemName: icon)
        }
    }

    /// `glyphSize(_:)`, or the skin's display font.
    private var glyphFont: Font {
        if let glyphSize { return AinkradFontResolver.font(size: glyphSize, typography: typo) }
        if isCompact { return AinkradFontResolver.font(size: skin.size.s26, typography: typo) }
        return skin.font(skin.components.emptyState.glyphFont, typography: typo)
    }

    /// The secondary + primary buttons, in that order.
    @ViewBuilder private var actionButtons: some View {
        if hasSecondaryAction, let secondaryTitle, let secondary {
            if usesSecondaryAccent {
                sized(AinkradButton(title: secondaryTitle, style: .secondary, action: secondary).secondaryAccent())
            } else {
                sized(AinkradButton(title: secondaryTitle, style: .secondary, action: secondary))
            }
        }
        if hasAction, let actionTitle, let action {
            primaryButton(actionTitle, action: action)
        }
    }

    @ViewBuilder public var body: some View {
        if !keyHints.isEmpty {
            keyHintBody
        } else if isCompact {
            compactBody
        } else if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple's content-unavailable view.
            ContentUnavailableView {
                if textGlyph == nil, tint == nil, glyphSize == nil {
                    Label(title, systemImage: icon)
                } else {
                    Label {
                        Text(title)
                    } icon: {
                        iconView.foregroundStyle(tint ?? .secondary)
                    }
                }
            } description: {
                Text(message)
            } actions: {
                HStack(spacing: skin.spacing.sm) { actionButtons }
            }
        } else {
            kitBody
        }
    }

    private var keyHintBody: some View {
        let empty = skin.components.emptyState
        return VStack(spacing: skin.spacing.sm) {
            iconView
                .font(skin.font(empty.glyphFont, typography: typo))
                .foregroundStyle(tint ?? skin.color(empty.glyphColor))
            HStack(spacing: skin.size.s4) {
                ForEach(Array(keyHints.enumerated()), id: \.offset) { index, hint in
                    if index > 0 { Text("·").padding(.horizontal, skin.size.s2) }
                    AinkradKbd(hint.keys).outlined()
                    Text(hint.label)
                }
            }
            .font(AinkradFontResolver.font(size: 12, typography: typo))
            .foregroundStyle(skin.color(empty.messageColor))
            .lineLimit(1)
        }
        .padding(skin.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var compactBody: some View {
        let empty = skin.components.emptyState
        return VStack(spacing: skin.size.s8) {
            iconView
                .font(glyphFont)
                .foregroundStyle(tint ?? skin.color(empty.glyphColor))
            if !title.isEmpty {
                Text(title)
                    .font(AinkradFontResolver.font(size: 13, weight: .bold, typography: typo))
                    .foregroundStyle(skin.color(skin.text.primary))
            }
            if !message.isEmpty {
                Text(message)
                    .font(AinkradFontResolver.font(size: 12, typography: typo))
                    .lineSpacing(skin.size.s4)
                    .foregroundStyle(skin.color(empty.messageColor))
                    .multilineTextAlignment(.center)
            }
            if hasAction || hasSecondaryAction {
                HStack(spacing: skin.size.s8) { compactButtons }
                    .padding(.top, skin.size.s4)
            }
        }
        .padding(.horizontal, skin.size.s22)
        .padding(.bottom, skin.size.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// `actionButtons` as the mockups' small buttons.
    @ViewBuilder private var compactButtons: some View {
        if hasSecondaryAction, let secondaryTitle, let secondary {
            let button = sized(AinkradButton(title: secondaryTitle, style: .secondary, action: secondary).compact())
            usesSecondaryAccent ? button.secondaryAccent() : button
        }
        if hasAction, let actionTitle, let action {
            primaryButton(actionTitle, action: action).compact()
        }
    }

    private var kitBody: some View {
        let empty = skin.components.emptyState
        return VStack(spacing: skin.spacing.md) {
            iconView
                .font(skin.font(empty.glyphFont, typography: typo))
                .foregroundStyle(tint ?? skin.color(empty.glyphColor))
            VStack(spacing: skin.spacing.xs) {
                Text(title)
                    .font(skin.font(empty.titleFont, typography: typo))
                    .foregroundStyle(skin.color(skin.text.primary))
                Text(message)
                    .font(skin.font(empty.messageFont, typography: typo))
                    .foregroundStyle(skin.color(empty.messageColor))
                    .multilineTextAlignment(.center)
            }
            if hasAction || hasSecondaryAction {
                HStack(spacing: skin.spacing.sm) { actionButtons }
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

    @ViewBuilder public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple's content-unavailable view.
            ContentUnavailableView {
                Label(message, systemImage: "exclamationmark.triangle")
            } actions: {
                if hasRetry, let retryTitle, let retry {
                    AinkradButton(title: retryTitle, style: .secondary, icon: "arrow.clockwise", action: retry)
                }
            }
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let error = skin.components.errorState
        let shape = AinkradSkinShape(token: error.shape)
        return VStack(spacing: skin.spacing.md) {
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
    @ViewBuilder public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: a system section heading, no accent tick.
            VStack(alignment: .leading, spacing: skin.spacing.xs / 2) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, skin.spacing.sm)
            .padding(.top, skin.spacing.sm)
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let header = skin.components.sectionHeader
        return VStack(alignment: .leading, spacing: skin.spacing.xs / 2) {
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
