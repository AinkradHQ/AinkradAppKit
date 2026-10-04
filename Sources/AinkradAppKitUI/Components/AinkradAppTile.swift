import AinkradAppKitContract
import SwiftUI

/// Chamfer app icon tile with hover/selected glow — the kit's portable
/// version of the host's NeonAppTile, for use by plugins that need an
/// app-launcher-style icon grid.
public struct AinkradAppTile: View {
    private let symbol: String
    private let title: String?
    private let size: CGFloat
    private let isSelected: Bool

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(symbol: String, title: String? = nil, size: CGFloat = 44, isSelected: Bool = false) {
        self.symbol = symbol
        self.title = title
        self.size = size
        self.isSelected = isSelected
    }

    private var borderColor: Color { isSelected ? theme.accentPrimary : theme.accentSecondary }
    private var borderOpacity: Double { isSelected ? 0.9 : (hovering ? 0.65 : 0.3) }
    private var glowOpacity: Double { isSelected ? 0.5 : (hovering ? 0.4 : 0) }

    public var body: some View {
        VStack(spacing: AinkradSpacing.xs) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(theme.foreground)
                .frame(width: size, height: size)
                .background(ChamferShape(cut: size * 0.22).fill(theme.surfaceElevated.opacity(0.85)))
                .overlay(
                    ChamferShape(cut: size * 0.22)
                        .strokeBorder(borderColor.opacity(borderOpacity), lineWidth: isSelected ? 1.5 : 1)
                )
                .shadow(color: theme.accentPrimary.opacity(glowOpacity), radius: hovering || isSelected ? 8 : 0)
                .scaleEffect(hovering && !reduceMotion ? 1.05 : 1.0)
            if let title {
                Text(title)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(theme.foreground.opacity(0.75))
                    .lineLimit(1)
            }
        }
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}
