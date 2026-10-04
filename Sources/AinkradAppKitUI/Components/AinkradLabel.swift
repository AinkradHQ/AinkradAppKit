import AinkradAppKitContract
import SwiftUI

/// Body-role text row with an optional leading icon. The plain-text
/// counterpart to `AinkradChip`/`AinkradBadge` for non-interactive labels.
public struct AinkradLabel: View {
    private let text: String
    private let systemName: String?

    @Environment(\.ainkradSkin) private var skin
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
                    .foregroundStyle(skin.color(skin.palette.accentSecondary))
            }
            Text(text)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(skin.color(skin.text.primary))
        }
    }
}

/// Dimmed caption-role text.
public struct AinkradCaption: View {
    private let text: String

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(AinkradFontResolver.font(.caption, typography: typo))
            .foregroundStyle(skin.color(skin.text.muted))
    }
}
