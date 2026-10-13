import AinkradAppKitContract
import SwiftUI

/// A small text toggle that sits inside a field — Forge's search options `Aa`
/// (match case), `⌶` (whole word), `✱` (regular expression) and `AB` (preserve
/// case), the mockups' `.sfield .tg`. Use it in
/// `AinkradSearchField.trailingAccessory(_:)`. Off it is faint mono text; on,
/// under Neon, foreground text on a primary-accent wash and, under Glass,
/// foreground text on a light capsule.
public struct AinkradFieldToggle: View {
    private let title: String
    @Binding private var isOn: Bool
    private let help: String

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    /// `help` is the hover tooltip naming the option ("Match case").
    public init(_ title: String, isOn: Binding<Bool>, help: String) {
        self.title = title
        self._isOn = isOn
        self.help = help
    }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            toggle(glass: true).help(help)
        } else {
            toggle(glass: false).ainkradTooltip(help)
        }
    }

    private func toggle(glass: Bool) -> some View {
        Button {
            isOn.toggle()
        } label: {
            Text(title)
                .font(AinkradFontResolver.font(size: 11, mono: true, typography: typo))
                .foregroundStyle(isOn || hovering ? theme.foreground : skin.color(skin.text.faint))
                .padding(.horizontal, glass ? skin.size.s7 : skin.size.s5)
                .padding(.vertical, glass ? skin.size.s2 : skin.size.s1)
                .background { wash(glass: glass) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: hovering)
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: isOn)
        .accessibilityLabel(help)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder private func wash(glass: Bool) -> some View {
        if glass {
            Capsule()
                .fill(theme.foreground.opacity(isOn ? skin.opacity.o22 : 0))
                .overlay(alignment: .top) {
                    // The Glass `.tg.on` inset highlight along the top edge.
                    Capsule().strokeBorder(theme.foreground.opacity(isOn ? skin.opacity.o30 : 0), lineWidth: 1)
                        .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .center))
                }
        } else {
            RoundedRectangle(cornerRadius: skin.size.s4)
                .fill(isOn ? theme.accentPrimary.opacity(skin.opacity.o40) : .clear)
        }
    }
}
