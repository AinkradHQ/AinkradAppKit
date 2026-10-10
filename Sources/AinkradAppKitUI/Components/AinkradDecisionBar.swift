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

        public init(title: String, style: AinkradButtonStyle, perform: @escaping () -> Void) {
            self.title = title
            self.style = style
            self.perform = perform
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

    /// `icon` is an SF Symbol name; `caption` is the small accent line
    /// ("Approval required"), `title` the one-line subject under it.
    public init(icon: String, iconTint: IconTint, caption: String, title: String, actions: [Action]) {
        self.icon = icon
        self.iconTint = iconTint
        self.caption = caption
        self.title = title
        self.actions = actions
    }

    public var body: some View {
        HStack(spacing: skin.size.s10) {
            Image(systemName: icon)
                .font(skin.font(AinkradFontToken(sizeKey: "t12", scaled: false)))
                .foregroundStyle(iconTint == .primary ? theme.accentPrimary : theme.accentSecondary)
            VStack(alignment: .leading, spacing: skin.size.s1) {
                Text(caption)
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
                AinkradButton(title: actions[index].title, style: actions[index].style, action: actions[index].perform)
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
