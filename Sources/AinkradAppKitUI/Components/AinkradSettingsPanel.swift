import AinkradAppKitContract
import SwiftUI

/// One settings choice: a spoken title, an optional sentence saying what the
/// user will see change, and the control.
///
/// Extracted from the setup wizard's Appearance step so the wizard and
/// Settings cannot drift into two visual languages for the same setting.
///
/// No all-caps header, no border and no rule above it — the groups are
/// separated by the recessed surface alone, per the design language's
/// no-separator rule. `AinkradSectionFrame` keeps the HUD idiom (accent tick,
/// tracked caps) for catalog-declared groups; this is deliberately the other
/// one, for panes that carry prose.
public struct AinkradSettingsPanel<Content: View>: View {
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    private let title: String
    private let hint: String?
    private let content: Content

    /// The hint is capped where the CONTENT below is not: the content fills so
    /// grids like the theme cards can use the room, but a one-line hint
    /// stretched across a 1400pt panel is unreadable.
    ///
    /// A constant rather than the wizard's
    /// `SetupStageLayout.readingWidth(inGroupOf:)`, which derives from the
    /// wizard stage's group width — Settings has no equivalent of that.
    public static var hintReadingWidth: CGFloat { 560 }

    public init(title: String, hint: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.hint = hint
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.sm) {
            VStack(alignment: .leading, spacing: AinkradSpacing.xs) {
                Text(title)
                    .font(AinkradFontResolver.font(.headline, weight: .medium, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.95))
                if let hint {
                    Text(hint)
                        .font(AinkradFontResolver.font(.caption, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.55))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: Self.hintReadingWidth, alignment: .leading)
                }
            }

            content
        }
        .padding(AinkradSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ChamferShape(cut: AinkradRadius.md)
                .fill(theme.surfaceElevated.opacity(0.32)))
    }
}
