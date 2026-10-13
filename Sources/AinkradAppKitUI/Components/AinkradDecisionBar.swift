import AinkradAppKitContract
import SwiftUI

/// Docked decision bar shown just above a composer while something awaits the
/// user's decision (a gated tool call, an agent-authored plan). The details stay
/// in the transcript; this bar carries only the decision, so it is always
/// visible without scrolling. Seamless elevated surface with an accent cue —
/// matches the composer it sits above.
public struct AinkradDecisionBar: View {
    /// Which theme accent the leading glyph takes.
    public enum IconTint: Equatable, Sendable { case primary, secondary }

    /// One button on the bar, drawn as a kit `AinkradButton` in `style` —
    /// `.primary` for the affirmative decision, `.ghost` for the others.
    public struct Action {
        public let title: String
        public let style: AinkradButtonStyle
        public let perform: () -> Void
        /// Set by `borderless()`.
        var isBorderless = false
        /// Set by `secondaryAccent()`.
        var usesSecondaryAccent = false
        /// Set by `detail(_:)`.
        var detail: String?

        public init(title: String, style: AinkradButtonStyle, perform: @escaping () -> Void) {
            self.title = title
            self.style = style
            self.perform = perform
        }

        /// Draws this action's button with `AinkradButton.borderless()` — no
        /// rim or glow — as approval mockup 04's ghost "Deny…".
        public func borderless() -> Action {
            var copy = self
            copy.isBorderless = true
            return copy
        }

        /// Draws this action's button with `AinkradButton.secondaryAccent()`,
        /// the mockups' cyan `.btn` text (mockup 04's "Deny…" and
        /// "Always allow").
        public func secondaryAccent() -> Action {
            var copy = self
            copy.usesSecondaryAccent = true
            return copy
        }

        /// A faint mono suffix after the title, kept as written — the CLI's
        /// rule in approval mockup 04's "Always allow `git push *`" (GP23).
        public func detail(_ text: String) -> Action {
            var copy = self
            copy.detail = text
            return copy
        }

        /// The kit button for this action, its opt-ins applied.
        @MainActor var button: AinkradButton {
            var button = AinkradButton(title: title, style: style, action: perform)
            if isBorderless { button = button.borderless() }
            if usesSecondaryAccent { button = button.secondaryAccent() }
            button.detail = detail
            return button
        }
    }

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typography
    @Environment(\.ainkradTheme) private var theme
    private let icon: String
    private let iconTint: IconTint
    private let caption: String
    private let title: String
    private let actions: [Action]
    /// Set by `labelCasedCaption()`.
    var casesCaption = false
    /// Set by `iconGlyph(_:)`.
    var textGlyph: String?

    /// `icon` is an SF Symbol name; `caption` is the small accent line
    /// ("Approval required"), `title` the one-line subject under it.
    public init(icon: String, iconTint: IconTint, caption: String, title: String, actions: [Action]) {
        self.icon = icon
        self.iconTint = iconTint
        self.caption = caption
        self.title = title
        self.actions = actions
    }

    /// Draws the caption in the skin's label case — "APPROVAL REQUIRED" under
    /// Neon, as written under Glass — like every other kit caption and
    /// Grimoire's approval mockup. Without it the caption is drawn as passed.
    public func labelCasedCaption() -> Self {
        var copy = self
        copy.casesCaption = true
        return copy
    }

    /// Draws a text glyph (`"⌁"`) in place of the SF Symbol `icon`, at the
    /// approval mockup's 16 pt, in the same `iconTint` (GP28).
    public func iconGlyph(_ glyph: String) -> Self {
        var copy = self
        copy.textGlyph = glyph
        return copy
    }

    @ViewBuilder private var iconView: some View {
        if let textGlyph {
            Text(textGlyph).font(skin.font(AinkradFontToken(sizeKey: "t16", scaled: false)))
        } else {
            Image(systemName: icon).font(skin.font(AinkradFontToken(sizeKey: "t12", scaled: false)))
        }
    }

    public var body: some View {
        HStack(spacing: skin.size.s10) {
            iconView
                .foregroundStyle(iconTint == .primary ? theme.accentPrimary : theme.accentSecondary)
            VStack(alignment: .leading, spacing: skin.size.s1) {
                Text(casesCaption ? skin.labelCased(caption) : caption)
                    .font(AinkradFontResolver.font(size: 10, weight: .semibold, typography: typography))
                    .kerning(0.6)
                    .foregroundStyle(theme.accentPrimary.opacity(skin.opacity.o85))
                Text(title)
                    .font(AinkradFontResolver.font(size: 12, weight: .medium, typography: typography))
                    .foregroundStyle(theme.foreground.opacity(skin.opacity.o85))
                    .lineLimit(1)
            }
            Spacer(minLength: 12)
            ForEach(actions.indices, id: \.self) { index in
                actions[index].button
            }
        }
        .padding(.horizontal, skin.size.s14).padding(.vertical, skin.size.s9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(skin.shape(cut: AinkradRadius.md).fill(theme.surfaceElevated.opacity(skin.opacity.o60)))
        .overlay {
            // Glass frames controls with a neutral hairline, not an accent rim (as `PaneActivationRing`).
            skin.shape(cut: AinkradRadius.md).stroke(
                skin.material.kind == "glass"
                    ? theme.foreground.opacity(skin.opacity.o16) : theme.accentPrimary.opacity(skin.opacity.o55),
                lineWidth: 1)
        }
        .padding(.horizontal, skin.size.s14)
        .padding(.bottom, skin.spacing.xs)
    }
}
