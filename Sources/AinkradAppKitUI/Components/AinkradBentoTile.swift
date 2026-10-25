import SwiftUI

/// A bento tile: a 18 pt card with a faint top-lit glass fill and a hairline rim that brightens on hover. `tint`
/// washes the fill and rim in a colour; `onTap` makes it a button that lifts on hover (not under Reduce Motion).
public struct AinkradBentoTile<Content: View>: View {
    private let padding: CGFloat?
    private let tint: Color?
    private let onTap: (() -> Void)?
    private let content: Content
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(
        padding: CGFloat? = nil, tint: Color? = nil, onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.tint = tint
        self.onTap = onTap
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s18, style: .continuous)
        let base = tint ?? skin.color(.palette("foreground", 1))
        content
            .padding(padding ?? skin.size.s16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                shape.fill(
                    LinearGradient(
                        colors: [
                            base.opacity(tint == nil ? skin.opacity.o05 : skin.opacity.o10),
                            skin.color(.palette("foreground", skin.opacity.o03)),
                        ], startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                shape.strokeBorder(
                    base.opacity(tint == nil ? (hovering ? skin.opacity.o12 : skin.opacity.o07) : skin.opacity.o25),
                    lineWidth: 1)
            )
            .contentShape(shape)
            .offset(y: hovering && onTap != nil && !reduceMotion ? -skin.size.s2 : 0)
            .onHover { hovering = $0 }
            .animation(skin.animation(skin.motion.hover), value: hovering)
            .onTapGesture { onTap?() }
    }
}

/// A section heading: a muted title, an optional count badge, and an optional accent link on the right
/// (`What needs you now [8]                Open inbox →`).
public struct AinkradSectionHead: View {
    private let title: String
    private let count: String?
    private let link: String?
    private let perform: () -> Void
    @Environment(\.ainkradSkin) private var skin

    public init(title: String, count: String? = nil, link: String? = nil, perform: @escaping () -> Void = {}) {
        self.title = title
        self.count = count
        self.link = link
        self.perform = perform
    }

    public var body: some View {
        HStack(spacing: skin.size.s8) {
            Text(title).kitFont("t10_5", weight: "semibold").foregroundStyle(skin.color(skin.text.muted))
            if let count {
                Text(count).kitFont("t10", weight: "semibold", mono: true)
                    .foregroundStyle(skin.color(skin.text.primary))
                    .padding(.horizontal, skin.size.s7)
                    .padding(.vertical, skin.size.s1)
                    .background(skin.color(.palette("foreground", skin.opacity.o07)), in: Capsule())
            }
            Spacer(minLength: skin.size.s8)
            if let link {
                AinkradTapArea(action: perform) {
                    Text(link).kitFont("t11", weight: "medium").foregroundStyle(
                        skin.color(skin.palette.accentSecondary))
                }
            }
        }
    }
}

/// A small status pill with an optional leading dot, tinted by `tint`.
public struct AinkradStatePill: View {
    private let text: String
    private let tint: Color
    private let dot: Bool
    @Environment(\.ainkradSkin) private var skin

    public init(text: String, tint: Color, dot: Bool = false) {
        self.text = text
        self.tint = tint
        self.dot = dot
    }

    public var body: some View {
        HStack(spacing: skin.size.s5) {
            if dot { Circle().fill(tint).frame(width: skin.size.s6, height: skin.size.s6) }
            Text(text).kitFont("t10_5", weight: "medium")
        }
        .foregroundStyle(tint)
        .padding(.horizontal, skin.size.s8)
        .padding(.vertical, skin.size.s2)
        .background(tint.opacity(skin.opacity.o14), in: Capsule())
    }
}
