import AinkradAppKitContract
import SwiftUI

/// Titled chamfer-bordered container — an accent-tick, uppercase-title header
/// atop a chamfered-border body. No separator line between header and body;
/// the accent tick + spacing carry that distinction instead.
public struct AinkradSectionFrame<Content: View>: View {
    private let title: String
    private let content: Content

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.sm) {
            HStack(spacing: AinkradSpacing.xs) {
                Rectangle()
                    .fill(theme.accentSecondary)
                    .frame(width: 14, height: 2)
                    .shadow(color: theme.accentSecondary.opacity(0.6), radius: 2)
                Text(title.uppercased())
                    .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.7))
                    .tracking(1.2)
            }
            content
        }
        .padding(AinkradSpacing.md)
        .background(ChamferShape(cut: AinkradRadius.md).fill(theme.surfaceElevated.opacity(0.35)))
        .overlay(ChamferShape(cut: AinkradRadius.md).strokeBorder(theme.accentSecondary.opacity(0.35), lineWidth: 1))
    }
}
