import SwiftUI

/// A rich picker button: an icon tile, a caption over the value, and a chevron that turns, with an "on" ring when a
/// filter is applied. Its `menu` (an `AinkradRichMenu`) drops from the trailing edge in the window while `isOpen`;
/// the screen adds a tap-away layer under it and lifts the bar with `zIndex` so the menu draws over the page.
public struct AinkradRichPicker<Icon: View, Menu: View>: View {
    private let caption: String
    private let value: String
    private let isOn: Bool
    @Binding private var isOpen: Bool
    private let icon: Icon
    private let menu: Menu
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(
        caption: String, value: String, isOn: Bool, isOpen: Binding<Bool>, @ViewBuilder icon: () -> Icon,
        @ViewBuilder menu: () -> Menu
    ) {
        self.caption = caption
        self.value = value
        self.isOn = isOn
        self._isOpen = isOpen
        self.icon = icon()
        self.menu = menu()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s16, style: .continuous)
        let tile = RoundedRectangle(cornerRadius: skin.size.s12, style: .continuous)
        let accent = skin.color(skin.palette.accentPrimary)
        AinkradTapArea(action: { isOpen.toggle() }) {
            HStack(spacing: skin.size.s10) {
                icon
                    .foregroundStyle(skin.color(isOn ? .palette("foreground", 1) : skin.text.muted))
                    .frame(width: skin.size.s40, height: skin.size.s40)
                    .background {
                        if isOn {
                            tile.fill(
                                LinearGradient(
                                    colors: [
                                        accent.opacity(skin.opacity.o30),
                                        skin.color(skin.palette.accentViolet).opacity(skin.opacity.o25),
                                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        } else {
                            tile.fill(
                                skin.color(.palette("foreground", hovering ? skin.opacity.o09 : skin.opacity.o05)))
                        }
                    }
                VStack(alignment: .leading, spacing: skin.size.s1) {
                    Text(skin.labelCased(caption).uppercased()).kitFont("t10").tracking(skin.size.s1 / 2)
                        .foregroundStyle(skin.color(skin.text.faint))
                    Text(value).kitFont("t12_5", weight: "semibold").foregroundStyle(skin.color(skin.text.primary))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.down").kitFont("t11", weight: "semibold")
                    .foregroundStyle(skin.color(isOpen ? skin.text.primary : skin.text.faint))
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
            }
            .padding(.leading, skin.size.s6)
            .padding(.trailing, skin.size.s12)
            .padding(.vertical, skin.size.s5)
            .frame(minWidth: skin.size.s168, minHeight: skin.size.s52)
            .background(
                shape.fill(
                    skin.color(.palette("background", hovering ? skin.opacity.o80 : skin.opacity.o72)))
            )
            .overlay(
                shape.strokeBorder(
                    isOn || isOpen
                        ? accent.opacity(skin.opacity.o35) : skin.color(.palette("foreground", skin.opacity.o07)),
                    lineWidth: 1)
            )
            .background(
                shape.stroke(accent.opacity(isOn || isOpen ? skin.opacity.o12 : 0), lineWidth: skin.size.s3)
            )
            .contentShape(shape)
        }
        .fixedSize()
        .offset(y: hovering && !reduceMotion ? -skin.size.s1 : 0)
        .onHover { hovering = $0 }
        .animation(skin.animation(AinkradAnimationToken(curve: "spring", response: 0.3, damping: 0.7)), value: isOpen)
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .overlay(alignment: .topTrailing) {
            if isOpen {
                menu
                    .offset(y: skin.size.s52 + skin.size.s6)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .scale(scale: 0.94, anchor: .topTrailing).combined(with: .opacity))
            }
        }
    }
}

/// The rich picker's menu panel: a header label and its rows, scrolling past a set height.
public struct AinkradRichMenu<Content: View>: View {
    private let header: String
    private let content: Content
    @Environment(\.ainkradSkin) private var skin

    public init(header: String, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s16, style: .continuous)
        ScrollView {
            VStack(alignment: .leading, spacing: skin.size.s1) {
                Text(header).kitFont("t11", weight: "semibold").foregroundStyle(skin.color(skin.text.faint))
                    .padding(.horizontal, skin.size.s10)
                    .padding(.top, skin.size.s6)
                    .padding(.bottom, skin.size.s4)
                content
            }
            .padding(skin.size.s6)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: skin.size.s340)
        .frame(maxHeight: skin.size.s460)
        .fixedSize(horizontal: false, vertical: true)
        .background(shape.fill(skin.color(.palette("surface", skin.opacity.o96))))
        .overlay(shape.strokeBorder(skin.color(.palette("foreground", skin.opacity.o10)), lineWidth: 1))
        .clipShape(shape)
        .shadow(color: skin.color(.palette("black", skin.opacity.o50)), radius: skin.size.s30, y: skin.size.s24)
    }
}

/// A divider between a menu's lead row ("Everyone") and the rest.
public struct AinkradRichMenuSeparator: View {
    @Environment(\.ainkradSkin) private var skin

    public init() {}

    public var body: some View {
        Rectangle().fill(skin.color(.palette("foreground", skin.opacity.o07))).frame(height: skin.size.s1)
            .padding(.horizontal, skin.size.s8).padding(.vertical, skin.size.s4)
    }
}

/// One menu row: a leading view, a bold title over a faint line, optional extras, a count badge and a check. Rows
/// stagger in by `index` and slide a little on hover.
public struct AinkradRichMenuRow<Leading: View, Extra: View>: View {
    private let title: String
    private let subtitle: String
    private let count: Int?
    private let isChecked: Bool
    private let index: Int
    private let action: () -> Void
    private let leading: Leading
    private let extra: Extra
    @State private var hovering = false
    @State private var shown = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(
        title: String, subtitle: String, count: Int? = nil, isChecked: Bool = false, index: Int = 0,
        action: @escaping () -> Void, @ViewBuilder leading: () -> Leading, @ViewBuilder extra: () -> Extra
    ) {
        self.title = title
        self.subtitle = subtitle
        self.count = count
        self.isChecked = isChecked
        self.index = index
        self.action = action
        self.leading = leading()
        self.extra = extra()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s11, style: .continuous)
        AinkradTapArea(action: action) {
            HStack(spacing: skin.size.s10) {
                leading
                VStack(alignment: .leading, spacing: skin.size.s1) {
                    Text(title).kitFont("t12_5", weight: "semibold").foregroundStyle(skin.color(skin.text.primary))
                    Text(subtitle).kitFont("t11").foregroundStyle(skin.color(skin.text.faint)).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                extra
                if let count {
                    Text("\(count)").kitFont("t10_5", weight: "semibold", mono: true)
                        .foregroundStyle(skin.color(skin.text.muted))
                        .padding(.horizontal, skin.size.s6)
                        .frame(minWidth: skin.size.s24, minHeight: skin.size.s20)
                        .background(
                            skin.color(.palette("foreground", skin.opacity.o07)),
                            in: RoundedRectangle(cornerRadius: skin.size.s6))
                }
                Image(systemName: "checkmark").kitFont("t11", weight: "bold")
                    .foregroundStyle(skin.color(skin.palette.accentSecondary))
                    .frame(width: skin.size.s18)
                    .opacity(isChecked ? 1 : 0)
            }
            .padding(.horizontal, skin.size.s8)
            .padding(.vertical, skin.size.s6)
            .background {
                if hovering {
                    shape.fill(
                        LinearGradient(
                            colors: [
                                skin.color(skin.palette.accentPrimary).opacity(skin.opacity.o22),
                                skin.color(skin.palette.accentViolet).opacity(skin.opacity.o12),
                            ], startPoint: .leading, endPoint: .trailing))
                }
            }
            .contentShape(shape)
        }
        .offset(x: reduceMotion ? 0 : (shown ? (hovering ? skin.size.s2 : 0) : skin.size.s10))
        .opacity(shown || reduceMotion ? 1 : 0)
        .onHover { hovering = $0 }
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .onAppear {
            withAnimation(
                skin.animation(AinkradAnimationToken(curve: "spring", response: 0.3, damping: 0.8))
                    .delay(Double(index) * 0.026)
            ) { shown = true }
        }
    }
}

extension AinkradRichMenuRow where Extra == EmptyView {
    public init(
        title: String, subtitle: String, count: Int? = nil, isChecked: Bool = false, index: Int = 0,
        action: @escaping () -> Void, @ViewBuilder leading: () -> Leading
    ) {
        self.init(
            title: title, subtitle: subtitle, count: count, isChecked: isChecked, index: index, action: action,
            leading: leading, extra: { EmptyView() })
    }
}
