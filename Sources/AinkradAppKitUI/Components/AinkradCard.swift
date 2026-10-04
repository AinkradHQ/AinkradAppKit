import AinkradAppKitContract
import SwiftUI

/// Surface-elevated rounded container with hover + selected states.
/// Consolidates AppStoreCard / ToolCallCard / connection rows.
public struct AinkradCard<Content: View>: View {
    private let isSelected: Bool
    private let onTap: (() -> Void)?
    private let content: Content
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(
        isSelected: Bool = false, onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.onTap = onTap
        self.content = content()
    }
    /// Whether the card routes taps (drives accessibility + hit testing).
    public var isInteractive: Bool { onTap != nil }

    public var body: some View {
        content
            .padding(AinkradSpacing.md)
            .background(ChamferShape(cut: AinkradRadius.md).fill(theme.surface.opacity(0.9)))
            .overlay(
                ChamferShape(cut: AinkradRadius.md)
                    .strokeBorder(borderColor.opacity(borderOpacity), lineWidth: isSelected ? 1.5 : 1)
            )
            .apply { hovering && !reduceMotion ? AnyView($0.cornerBrackets(length: 10, inset: -2)) : AnyView($0) }
            .scaleEffect(hovering && !reduceMotion ? 1.015 : 1.0)
            .animation(AinkradMotion.hover, value: hovering)
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .apply { if let onTap { $0.onTapGesture(perform: onTap) } else { $0 } }
    }
    private var borderColor: Color { isSelected ? theme.accentPrimary : theme.accentSecondary }
    private var borderOpacity: Double { isSelected ? 0.85 : (hovering ? 0.6 : 0.25) }
}

// Small helper so the conditional tap gesture stays readable.
extension View { @ViewBuilder func apply<V: View>(@ViewBuilder _ t: (Self) -> V) -> some View { t(self) } }
