import AinkradAppKitContract
import AppKit
import SwiftUI

public struct AinkradFormRow<Control: View>: View {
    public let title: String
    public let help: String?
    /// Short uppercase tags rendered beside the title — e.g. ADVANCED,
    /// RESTART REQUIRED. Empty by default so existing call sites are unchanged.
    public let badges: [String]
    /// Fixed width for the control, so every control in a form shares one
    /// vertical rail. `nil` keeps the previous behaviour: the control sizes
    /// itself and right-aligns after a Spacer.
    public let controlWidth: CGFloat?
    private let control: Control
    private let accessory: AnyView?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(
        title: String,
        help: String? = nil,
        badges: [String] = [],
        controlWidth: CGFloat? = nil,
        accessory: (() -> AnyView)? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.help = help
        self.badges = badges
        self.controlWidth = controlWidth
        self.accessory = accessory?()
        self.control = control()
    }

    public var body: some View {
        // `.center`, not `.firstTextBaseline`: with a two-line label (title +
        // help) baseline alignment pins the control to the title's line,
        // floating it at the top of the row instead of the middle of the
        // label block. `.center` centres the control against the whole
        // label block regardless of how many lines it has, and degrades to
        // the same visual result as baseline alignment for a single-line
        // label (title only) since there's only one line to center against.
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
                HStack(spacing: AinkradSpacing.xs) {
                    Rectangle()
                        .fill(theme.accentSecondary.opacity(0.55))
                        .frame(width: 2, height: 12)
                    Text(title)
                        .font(AinkradFontResolver.font(.body, typography: typo))
                        .foregroundStyle(theme.foreground)
                    ForEach(badges, id: \.self) { badge in
                        AinkradBadge(text: badge, tint: theme.accentSecondary)
                    }
                    if let accessory { accessory }
                }
                if let help {
                    Text(help)
                        .font(AinkradFontResolver.font(.caption, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.55))
                        .padding(.leading, AinkradSpacing.xs + 2)
                }
            }
            Spacer(minLength: AinkradSpacing.lg)
            if let controlWidth {
                control.frame(width: controlWidth, alignment: .trailing)
            } else {
                control
            }
        }
    }
}
