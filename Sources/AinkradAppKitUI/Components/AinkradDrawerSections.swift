import SwiftUI

/// A drawer's hero card: a tinted wash with a radial glow, a leading tile, a mono title over a subtitle, and a
/// trailing accessory.
public struct AinkradDrawerHero<Leading: View, Trailing: View>: View {
    private let tint: Color
    private let title: String
    private let subtitle: String
    private let leading: Leading
    private let trailing: Trailing
    @Environment(\.ainkradSkin) private var skin

    public init(
        tint: Color, title: String, subtitle: String, @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s18, style: .continuous)
        HStack(spacing: skin.size.s14) {
            leading
            VStack(alignment: .leading, spacing: skin.size.s2) {
                Text(title).kitFont("t16", weight: "bold", mono: true)
                    .foregroundStyle(skin.color(skin.text.primary)).lineLimit(1)
                Text(subtitle).kitFont("t12").foregroundStyle(skin.color(skin.text.faint)).lineLimit(2)
            }
            Spacer(minLength: skin.size.s8)
            trailing
        }
        .padding(skin.size.s16)
        .background(
            ZStack(alignment: .topLeading) {
                shape.fill(
                    LinearGradient(
                        colors: [tint.opacity(skin.opacity.o16), skin.color(.palette("foreground", skin.opacity.o03))],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                RadialGradient(
                    colors: [tint.opacity(skin.opacity.o30), .clear], center: .topLeading, startRadius: 0,
                    endRadius: skin.size.s140)
            }
            .clipShape(shape)
        )
        .overlay(shape.strokeBorder(tint.opacity(skin.opacity.o25), lineWidth: 1))
    }
}

/// A drawer section card: a bold title with a faint right-hand hint, then its content.
public struct AinkradDrawerSection<Hint: View, Content: View>: View {
    private let title: String
    private let hint: Hint
    private let content: Content
    @Environment(\.ainkradSkin) private var skin

    public init(title: String, @ViewBuilder hint: () -> Hint, @ViewBuilder content: () -> Content) {
        self.title = title
        self.hint = hint()
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s16, style: .continuous)
        VStack(alignment: .leading, spacing: skin.size.s10) {
            HStack(alignment: .firstTextBaseline, spacing: skin.size.s10) {
                Text(title).kitFont("t13", weight: "bold").foregroundStyle(skin.color(skin.text.primary))
                Spacer(minLength: skin.size.s8)
                hint.kitFont("t11").foregroundStyle(skin.color(skin.text.faint))
            }
            content
        }
        .padding(skin.size.s14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(skin.color(.palette("foreground", skin.opacity.o03))))
        .overlay(shape.strokeBorder(skin.color(.palette("foreground", skin.opacity.o05)), lineWidth: 1))
    }
}

extension AinkradDrawerSection where Hint == Text {
    public init(title: String, hint: String = "", @ViewBuilder content: () -> Content) {
        self.init(title: title, hint: { Text(hint) }, content: content)
    }
}

/// Faint explanatory copy under a drawer's sections.
public struct AinkradDrawerHint: View {
    private let text: String
    @Environment(\.ainkradSkin) private var skin

    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text).kitFont("t11").foregroundStyle(skin.color(skin.text.faint))
            .fixedSize(horizontal: false, vertical: true)
    }
}
