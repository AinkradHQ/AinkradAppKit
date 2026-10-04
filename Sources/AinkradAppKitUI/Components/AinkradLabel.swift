import AinkradAppKitContract
import SwiftUI

/// Body-role text row with an optional leading icon. The plain-text
/// counterpart to `AinkradChip`/`AinkradBadge` for non-interactive labels.
public struct AinkradLabel: View {
    private let text: String
    private let systemName: String?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(_ text: String, systemName: String? = nil) {
        self.text = text
        self.systemName = systemName
    }

    public var body: some View {
        HStack(spacing: AinkradSpacing.xs) {
            if let systemName {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.accentSecondary)
            }
            Text(text)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground)
        }
    }
}

/// Dimmed caption-role text.
public struct AinkradCaption: View {
    private let text: String

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(AinkradFontResolver.font(.caption, typography: typo))
            .foregroundStyle(theme.foreground.opacity(0.55))
    }
}
