import SwiftUI

/// One tab of an `AinkradGlideTabs` bar.
public struct AinkradGlideTab<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: String
    public let systemImage: String?
    public let count: String?

    public init(_ id: ID, title: String, systemImage: String? = nil, count: String? = nil) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.count = count
    }
}

/// The Citadel section bar: equal-width tabs on a frosted track, each an icon tile + label + count, with ONE
/// highlight that glides (with a slight overshoot) to the selected tab. `tint` is the caller's colour pair (an
/// agent palette, a project's colours); the selected icon tile and the highlight take it.
public struct AinkradGlideTabs<ID: Hashable>: View {
    private let tabs: [AinkradGlideTab<ID>]
    @Binding private var selection: ID
    private let tint: (Color, Color)?
    private let height: CGFloat?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @Namespace private var glide

    public init(
        _ tabs: [AinkradGlideTab<ID>], selection: Binding<ID>, tint: (Color, Color)? = nil, height: CGFloat? = nil
    ) {
        self.tabs = tabs
        self._selection = selection
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        let track = RoundedRectangle(cornerRadius: skin.size.s16, style: .continuous)
        HStack(spacing: 0) {
            ForEach(tabs) { tab in tabView(tab) }
        }
        .padding(skin.size.s5)
        .background(track.fill(skin.color(.palette("background", skin.opacity.o72))))
        .overlay(track.strokeBorder(skin.color(.palette("foreground", skin.opacity.o07)), lineWidth: 1))
    }

    private var colors: (Color, Color) {
        tint ?? (skin.color(skin.palette.accentPrimary), skin.color(skin.palette.accentViolet))
    }

    private func tabView(_ tab: AinkradGlideTab<ID>) -> some View {
        let isOn = tab.id == selection
        let pill = RoundedRectangle(cornerRadius: skin.size.s12, style: .continuous)
        let tile = RoundedRectangle(cornerRadius: skin.size.s8, style: .continuous)
        return Button {
            guard !isOn else { return }
            if reduceMotion {
                selection = tab.id
            } else {
                withAnimation(skin.animation(AinkradAnimationToken(curve: "spring", response: 0.42, damping: 0.74))) {
                    selection = tab.id
                }
            }
        } label: {
            HStack(spacing: skin.size.s9) {
                if let image = tab.systemImage {
                    Image(systemName: image)
                        .font(skin.font(AinkradFontToken(sizeKey: "t12", weight: "medium"), typography: typo))
                        .foregroundStyle(skin.color(isOn ? .palette("foreground", 1) : skin.text.muted))
                        .frame(width: skin.size.s26, height: skin.size.s26)
                        .background {
                            if isOn {
                                tile.fill(
                                    LinearGradient(
                                        colors: [colors.0, colors.1], startPoint: .topLeading, endPoint: .bottomTrailing
                                    ))
                            } else {
                                tile.fill(skin.color(.palette("foreground", skin.opacity.o05)))
                            }
                        }
                        .scaleEffect(isOn ? 1.04 : 1)
                }
                Text(tab.title)
                    .font(
                        skin.font(
                            AinkradFontToken(sizeKey: "t12_5", weight: isOn ? "semibold" : "medium"), typography: typo)
                    )
                    .foregroundStyle(skin.color(isOn ? .palette("foreground", 1) : skin.text.muted))
                    .lineLimit(1)
                if let count = tab.count, !count.isEmpty {
                    Text(count)
                        .font(
                            skin.font(
                                AinkradFontToken(sizeKey: "t10", weight: "semibold", mono: "family"), typography: typo)
                        )
                        .foregroundStyle(skin.color(isOn ? .palette("foreground", 1) : skin.text.muted))
                        .padding(.horizontal, skin.size.s5)
                        .frame(minWidth: skin.size.s18, minHeight: skin.size.s16)
                        .background(
                            (isOn
                                ? colors.0.opacity(skin.opacity.o35)
                                : skin.color(.palette("foreground", skin.opacity.o07))),
                            in: RoundedRectangle(cornerRadius: skin.size.s6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height ?? skin.size.s40)
            .background {
                if isOn {
                    pill
                        .fill(
                            LinearGradient(
                                colors: [colors.0.opacity(skin.opacity.o25), colors.1.opacity(skin.opacity.o18)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .overlay(pill.strokeBorder(colors.0.opacity(skin.opacity.o45), lineWidth: 1))
                        .shadow(color: colors.0.opacity(skin.opacity.o22), radius: skin.size.s9, y: skin.size.s6)
                        .matchedGeometryEffect(id: "glide", in: glide)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
