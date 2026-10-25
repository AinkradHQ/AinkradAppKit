import SwiftUI

/// A selectable card for single, multi and toggle choices: a faint glass tile that washes accent when `isOn`, a
/// dashed "add" variant, and a hover state when it has an `action`. `height` fixes the card's height, `minHeight` only
/// floors it; `axis` stacks the content (a glyph over a title) or lays it in a row.
public struct AinkradChoiceCard<Content: View>: View {
    private let isOn: Bool
    private let isAdd: Bool
    private let height: CGFloat?
    private let minHeight: CGFloat?
    private let axis: Axis
    private let action: (() -> Void)?
    private let content: Content
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(
        isOn: Bool = false, isAdd: Bool = false, height: CGFloat? = nil, minHeight: CGFloat? = nil,
        axis: Axis = .horizontal, action: (() -> Void)? = nil, @ViewBuilder content: () -> Content
    ) {
        self.isOn = isOn
        self.isAdd = isAdd
        self.height = height
        self.minHeight = minHeight
        self.axis = axis
        self.action = action
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s10, style: .continuous)
        let accent = skin.color(skin.palette.accentPrimary)
        let fg = skin.color(.palette("foreground", 1))
        let fill: Color =
            isOn
            ? accent.opacity(skin.opacity.o14)
            : isAdd
                ? (hovering ? accent.opacity(skin.opacity.o06) : .clear)
                : fg.opacity(hovering ? skin.opacity.o07 : skin.opacity.o05)
        let rim: Color =
            isOn
            ? accent.opacity(skin.opacity.o50)
            : isAdd && hovering
                ? accent.opacity(skin.opacity.o45) : fg.opacity(hovering ? skin.opacity.o13 : skin.opacity.o07)
        Group {
            if axis == .horizontal {
                HStack(spacing: skin.size.s10) { content }
                    .frame(
                        maxWidth: .infinity, minHeight: minHeight ?? height, maxHeight: height, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: skin.size.s3) { content }
                    .frame(
                        maxWidth: .infinity, minHeight: minHeight ?? height, maxHeight: height,
                        alignment: .topLeading)
            }
        }
        .padding(.horizontal, skin.size.s12)
        .padding(.vertical, axis == .horizontal ? 0 : skin.size.s10)
        .background(shape.fill(fill))
        .overlay(
            shape.strokeBorder(rim, style: StrokeStyle(lineWidth: 1, dash: isAdd ? [skin.size.s4, skin.size.s3] : []))
        )
        .contentShape(shape)
        .onHover { hovering = action != nil && $0 }
        .onTapGesture { action?() }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: isOn)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// A card's two-line body: a bold title over a faint caption. `compact` steps both lines down a size.
public struct AinkradChoiceText: View {
    private let title: String
    private let caption: String?
    private let mono: Bool
    private let wraps: Bool
    private let compact: Bool
    @Environment(\.ainkradSkin) private var skin

    public init(
        title: String, caption: String? = nil, mono: Bool = false, wraps: Bool = false, compact: Bool = false
    ) {
        self.title = title
        self.caption = caption
        self.mono = mono
        self.wraps = wraps
        self.compact = compact
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: compact ? skin.size.s2 : skin.size.s1) {
            Text(title).kitFont(compact ? "t12_5" : "t13", weight: "semibold", mono: mono)
                .foregroundStyle(skin.color(skin.text.primary))
                .lineLimit(1)
            if let caption {
                Text(caption).kitFont(compact ? "t11" : "t10_5").foregroundStyle(skin.color(skin.text.faint))
                    .lineLimit(wraps ? 2 : 1).fixedSize(horizontal: false, vertical: wraps)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The glyph tile at a card's left: an SF Symbol or a text glyph, accent-tinted until its card is on.
public struct AinkradChoiceGlyph: View {
    private let glyph: String
    private let isSymbol: Bool
    private let isOn: Bool
    private let size: CGFloat?
    @Environment(\.ainkradSkin) private var skin

    public init(_ glyph: String, isSymbol: Bool = true, isOn: Bool = false, size: CGFloat? = nil) {
        self.glyph = glyph
        self.isSymbol = isSymbol
        self.isOn = isOn
        self.size = size
    }

    public var body: some View {
        let side = size ?? skin.size.s28
        let accent = skin.color(skin.palette.accentPrimary)
        Group {
            if isSymbol { Image(systemName: glyph) } else { Text(glyph) }
        }
        .kitFont("t12", weight: "semibold")
        .foregroundStyle(isOn ? skin.color(skin.palette.white) : accent)
        .frame(width: side, height: side)
        .background(
            isOn ? accent.opacity(skin.opacity.o30) : skin.color(.palette("foreground", skin.opacity.o06)),
            in: RoundedRectangle(cornerRadius: side * 0.28, style: .continuous))
    }
}

/// The check box of a multi-choice card.
public struct AinkradCheckBox: View {
    private let isOn: Bool
    @Environment(\.ainkradSkin) private var skin

    public init(isOn: Bool) { self.isOn = isOn }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s5, style: .continuous)
        Image(systemName: "checkmark").kitFont("t10", weight: "bold")
            .foregroundStyle(skin.color(skin.palette.white)).opacity(isOn ? 1 : 0)
            .frame(width: skin.size.s18, height: skin.size.s18)
            .background(shape.fill(isOn ? skin.color(skin.palette.accentPrimary) : .clear))
            .overlay(
                shape.strokeBorder(skin.color(.palette("foreground", skin.opacity.o25)), lineWidth: 1.5).opacity(
                    isOn ? 0 : 1))
    }
}

/// `▬▬▬▭`: `value` of `of` short bars lit (a quality or speed rating).
public struct AinkradDotMeter: View {
    private let value: Int
    private let total: Int
    @Environment(\.ainkradSkin) private var skin

    public init(value: Int, of total: Int = 4) {
        self.value = value
        self.total = total
    }

    public var body: some View {
        HStack(spacing: skin.size.s3) {
            ForEach(0..<total, id: \.self) { index in
                Capsule().fill(
                    index < value
                        ? skin.color(skin.palette.accentPrimary) : skin.color(.palette("foreground", skin.opacity.o10))
                )
                .frame(width: skin.size.s14, height: skin.size.s4)
            }
        }
    }
}

/// Three rising bars, `level` (0-based) of them lit: an effort or strength mark.
public struct AinkradLevelBars: View {
    private let level: Int
    @Environment(\.ainkradSkin) private var skin

    public init(level: Int) { self.level = level }

    public var body: some View {
        HStack(alignment: .bottom, spacing: skin.size.s3) {
            ForEach(0..<3, id: \.self) { index in
                RoundedRectangle(cornerRadius: skin.size.s2)
                    .fill(
                        index <= level
                            ? skin.color(skin.palette.accentPrimary)
                            : skin.color(.palette("foreground", skin.opacity.o14))
                    )
                    .frame(width: skin.size.s5, height: skin.size.s6 + CGFloat(index) * skin.size.s4)
            }
        }
        .frame(width: skin.size.s24, height: skin.size.s16, alignment: .bottomLeading)
    }
}

/// A label row above a card group: `Role`, `Guidelines · 5 on`.
public struct AinkradGroupLabel: View {
    private let title: String
    private let trailing: String?
    @Environment(\.ainkradSkin) private var skin

    public init(title: String, trailing: String? = nil) {
        self.title = title
        self.trailing = trailing
    }

    public var body: some View {
        HStack {
            Text(title).kitFont("t10_5", weight: "semibold").foregroundStyle(skin.color(skin.text.muted))
            Spacer(minLength: skin.size.s8)
            if let trailing {
                Text(trailing).kitFont("t11").foregroundStyle(skin.color(skin.text.faint))
            }
        }
    }
}

/// A fixed-column grid of equal cards.
public struct AinkradCardGrid<Content: View>: View {
    private let columns: Int
    private let spacing: CGFloat?
    private let content: Content
    @Environment(\.ainkradSkin) private var skin

    public init(columns: Int, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: spacing ?? skin.size.s8, alignment: .top), count: columns),
            alignment: .leading, spacing: spacing ?? skin.size.s8
        ) { content }
    }
}

/// A toggle row: a check (or `glyph` tile), the title, and the kit switch; the whole card toggles. `flash` washes the
/// card green once (a rule that just switched on).
public struct AinkradToggleCard: View {
    private let title: String
    private let isOn: Bool
    private let glyph: String?
    private let flash: Bool
    private let toggle: () -> Void
    @Environment(\.ainkradSkin) private var skin

    public init(title: String, isOn: Bool, glyph: String? = nil, flash: Bool = false, toggle: @escaping () -> Void) {
        self.title = title
        self.isOn = isOn
        self.glyph = glyph
        self.flash = flash
        self.toggle = toggle
    }

    public var body: some View {
        AinkradChoiceCard(isOn: isOn, minHeight: skin.size.s46, action: toggle) {
            if let glyph {
                AinkradChoiceGlyph(glyph, isSymbol: false, isOn: isOn).scaleEffect(0.86)
            } else {
                AinkradCheckBox(isOn: isOn)
            }
            Text(title).kitFont("t12").foregroundStyle(skin.color(skin.text.primary)).lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            AinkradToggle(isOn: Binding(get: { isOn }, set: { _ in toggle() })).fixedSize()
        }
        .background(
            RoundedRectangle(cornerRadius: skin.size.s10, style: .continuous)
                .fill(skin.color(skin.palette.success).opacity(flash ? skin.opacity.o25 : 0)))
    }
}
