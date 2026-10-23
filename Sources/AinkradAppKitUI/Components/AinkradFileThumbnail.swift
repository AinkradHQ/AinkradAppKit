import AinkradAppKitContract
import SwiftUI

/// A file an agent published, as a tile (Citadel artifacts 13): a preview
/// (the caller's — rendered first lines, an image, an icon), a type tag over
/// its corner ("png · 1440×900"), the name, and its provenance in one line —
/// the agent's avatar and name, the issues or requirements it belongs to in
/// the accent mono, and a faint detail ("run #428"). Hover lifts it 2 pt and
/// brightens it; selected, it takes an accent rim and fill. The tile is one
/// button: click or Space/Return calls `action`.
public struct AinkradFileThumbnail<Preview: View, Avatar: View>: View {
    private let name: String
    private let typeLabel: String?
    private let agent: String?
    private let references: [String]
    private let detail: String?
    private let isSelected: Bool
    private let action: () -> Void
    private let preview: Preview
    private let avatar: Avatar
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - typeLabel: the tag over the preview's corner ("report · md").
    ///   - references: issue, requirement or run keys, drawn in the accent mono.
    ///   - detail: a faint trailing fact ("run #428").
    public init(
        name: String, typeLabel: String? = nil, agent: String? = nil, references: [String] = [],
        detail: String? = nil, isSelected: Bool = false, action: @escaping () -> Void = {},
        @ViewBuilder preview: () -> Preview, @ViewBuilder avatar: () -> Avatar
    ) {
        self.name = name
        self.typeLabel = typeLabel
        self.agent = agent
        self.references = references
        self.detail = detail
        self.isSelected = isSelected
        self.action = action
        self.preview = preview()
        self.avatar = avatar()
    }

    public var body: some View {
        Button(action: action) {  // design-lint: allow raw-control the whole tile is one keyboard stop
            VStack(alignment: .leading, spacing: skin.size.s7) {
                previewWell
                Text(name)
                    .font(skin.font(AinkradFontToken(sizeKey: "t12", weight: "medium")))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.middle)
                provenance
            }
            .padding(skin.size.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .kitCardSurface(
            isSelected ? theme.accentPrimary.opacity(skin.opacity.o16) : theme.surface.opacity(skin.opacity.o96),
            glass: isSelected
                ? theme.accentPrimary.opacity(skin.opacity.o16)
                : skin.color(skin.palette.white).opacity(skin.opacity.o05),
            rim: isSelected ? theme.accentPrimary : nil
        )
        .brightness(hovering ? skin.opacity.o05 : 0)
        .offset(y: hovering && !reduceMotion ? -skin.size.s2 : 0)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var previewWell: some View {
        let shape = RoundedRectangle(
            cornerRadius: skin.usesNativeGlass ? skin.size.s8 : skin.size.s4, style: .continuous)
        return ZStack(alignment: .bottomLeading) {
            shape.fill(skin.color(skin.palette.black).opacity(skin.opacity.o30))
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(shape)
            if let typeLabel {
                Text(typeLabel)
                    .font(skin.font(AinkradFontToken(sizeKey: "t9_5", mono: "family")))
                    .foregroundStyle(skin.color(skin.text.muted))
                    .padding(.horizontal, skin.size.s5)
                    .background(
                        theme.background.opacity(skin.opacity.o80),
                        in: RoundedRectangle(cornerRadius: skin.size.s3, style: .continuous)
                    )
                    .padding(skin.size.s6)
            }
        }
        .frame(height: skin.size.s96)
        .accessibilityHidden(true)
    }

    private var provenance: some View {
        let faint = skin.color(skin.text.faint)
        var line = Text(agent ?? "").foregroundStyle(faint)
        for (index, key) in references.enumerated() {
            if index > 0 || agent != nil { line = line + Text(" · ").foregroundStyle(faint) }
            line =
                line
                + Text(key).font(skin.font(AinkradFontToken(sizeKey: "t10_5", mono: "family")))
                .foregroundStyle(theme.accentSecondary)
        }
        if let detail { line = line + Text(" · \(detail)").foregroundStyle(faint) }
        return HStack(spacing: skin.size.s6) {
            avatar
            line.font(skin.font(AinkradFontToken(sizeKey: "t10_5"))).lineLimit(1)
        }
    }

    private var accessibilityLabel: String {
        ([name, typeLabel, agent.map { "by \($0)" }] + references.map(Optional.some) + [detail])
            .compactMap { $0 }.joined(separator: ", ")
    }
}

extension AinkradFileThumbnail where Avatar == EmptyView {
    /// A tile with no avatar.
    public init(
        name: String, typeLabel: String? = nil, agent: String? = nil, references: [String] = [],
        detail: String? = nil, isSelected: Bool = false, action: @escaping () -> Void = {},
        @ViewBuilder preview: () -> Preview
    ) {
        self.init(
            name: name, typeLabel: typeLabel, agent: agent, references: references, detail: detail,
            isSelected: isSelected, action: action, preview: preview, avatar: { EmptyView() })
    }
}
