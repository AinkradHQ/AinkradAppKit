import SwiftUI

/// One option of an `AinkradOptionGrid`: a title and detail, over an SF Symbol tile or a `leading` view of the
/// caller's.
public struct AinkradOption<ID: Hashable>: Identifiable {
    public let id: ID
    public var title: String
    public var detail: String
    public var systemImage: String?
    public var leading: AnyView?
    /// The selected wash and rim; the accent when nil.
    public var tint: Color?
    public var isEnabled: Bool
    public var help: String?

    public init(
        id: ID, title: String, detail: String = "", systemImage: String? = nil, leading: AnyView? = nil,
        tint: Color? = nil, isEnabled: Bool = true, help: String? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.leading = leading
        self.tint = tint
        self.isEnabled = isEnabled
        self.help = help
    }
}

/// A grid of tall option tiles (a provider, an account kind, a scope): `isOn` marks the chosen ones (one or many),
/// `pick` answers a tap. The chosen tile washes in its tint with a soft glow. `centered` centres the content (provider
/// tiles) instead of leading-aligning it.
public struct AinkradOptionGrid<ID: Hashable>: View {
    private let options: [AinkradOption<ID>]
    private let columns: Int
    private let centered: Bool
    private let isOn: (ID) -> Bool
    private let pick: (ID) -> Void
    @Environment(\.ainkradSkin) private var skin

    public init(
        options: [AinkradOption<ID>], columns: Int = 3, centered: Bool = false, isOn: @escaping (ID) -> Bool,
        pick: @escaping (ID) -> Void
    ) {
        self.options = options
        self.columns = columns
        self.centered = centered
        self.isOn = isOn
        self.pick = pick
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: skin.size.s8), count: columns),
            spacing: skin.size.s8
        ) {
            ForEach(options) { option in
                OptionTile(option: option, centered: centered, isOn: isOn(option.id)) { pick(option.id) }
            }
        }
    }
}

private struct OptionTile<ID: Hashable>: View {
    let option: AinkradOption<ID>
    let centered: Bool
    let isOn: Bool
    let pick: () -> Void
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        let tint = option.tint ?? skin.color(skin.palette.accentPrimary)
        let shape = RoundedRectangle(cornerRadius: skin.size.s14, style: .continuous)
        AinkradTapArea(help: option.help, action: { if option.isEnabled { pick() } }) {
            VStack(alignment: centered ? .center : .leading, spacing: skin.size.s6) {
                if let leading = option.leading {
                    leading
                } else if let image = option.systemImage {
                    Image(systemName: image).kitFont("t13", weight: "medium")
                        .foregroundStyle(skin.color(skin.palette.accentPrimary))
                        .frame(width: skin.size.s30, height: skin.size.s30)
                        .background(
                            skin.color(skin.palette.accentPrimary).opacity(skin.opacity.o14),
                            in: RoundedRectangle(cornerRadius: skin.size.s9, style: .continuous))
                }
                Text(option.title).kitFont("t12_5", weight: "semibold")
                    .foregroundStyle(skin.color(skin.text.primary))
                if !option.detail.isEmpty {
                    Text(option.detail).kitFont(centered ? "t10_5" : "t11")
                        .foregroundStyle(skin.color(skin.text.faint))
                        .multilineTextAlignment(centered ? .center : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(centered ? skin.size.s14 : skin.size.s12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: centered ? .top : .topLeading)
            .background(
                shape.fill(isOn ? tint.opacity(skin.opacity.o12) : skin.color(.palette("black", skin.opacity.o18)))
            )
            .overlay(
                shape.strokeBorder(
                    isOn ? tint.opacity(skin.opacity.o55) : skin.color(.palette("foreground", skin.opacity.o06)),
                    lineWidth: 1)
            )
            .shadow(color: isOn ? tint.opacity(skin.opacity.o15) : .clear, radius: skin.size.s12, y: skin.size.s8)
            .contentShape(shape)
        }
        .opacity(option.isEnabled ? 1 : skin.opacity.o45)
        .offset(y: hovering && option.isEnabled && !reduceMotion ? -skin.size.s2 : 0)
        .onHover { hovering = $0 }
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .animation(skin.animation(skin.motion.hover), value: isOn)
    }
}
