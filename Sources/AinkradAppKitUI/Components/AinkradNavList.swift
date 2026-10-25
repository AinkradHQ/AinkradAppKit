import SwiftUI

/// Sidebar-style navigation list — single-select rows, an accent bar leading
/// the selected row, and no divider lines between rows.
public struct AinkradNavList<T: Hashable>: View {
    private let items: [T]
    @Binding private var selection: T
    private let icon: (T) -> String?
    private let label: (T) -> String
    /// Set by `counts(_:)`.
    var count: ((T) -> AinkradNavCount?)?
    /// Set by `sections(_:)`.
    var section: ((T) -> String?)?
    /// Set by `glidingSelection()`.
    var glides = false

    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Namespace private var pill

    /// A trailing count or badge per row; `nil` shows none for that row.
    public func counts(_ count: @escaping (T) -> AinkradNavCount?) -> Self {
        var copy = self
        copy.count = count
        return copy
    }

    /// A group label above the first row of each run of rows sharing a non-nil section.
    public func sections(_ section: @escaping (T) -> String?) -> Self {
        var copy = self
        copy.section = section
        return copy
    }

    /// One soft accent pill that glides between rows instead of a filled selected row (Citadel sidebar). Rows are
    /// 30 pt with tinted line icons; a count bumps when it changes.
    public func glidingSelection() -> Self {
        var copy = self
        copy.glides = true
        return copy
    }

    public init(items: [T], selection: Binding<T>, icon: @escaping (T) -> String?, label: @escaping (T) -> String) {
        self.items = items
        self._selection = selection
        self.icon = icon
        self.label = label
    }

    public var body: some View {
        let rows = navListRows(items: items, selected: selection)
        VStack(alignment: .leading, spacing: glides ? skin.size.s1 : AinkradSpacing.xs / 2) {
            ForEach(Array(rows.enumerated()), id: \.element.item) { index, row in
                if let title = section?(row.item), index == 0 || section?(rows[index - 1].item) != title {
                    Text(title)
                        .font(skin.font(AinkradFontToken(sizeKey: "t10_5", weight: "semibold"), typography: typo))
                        .foregroundStyle(skin.color(skin.text.faint))
                        .padding(.top, skin.size.s14)
                        .padding(.bottom, skin.size.s5)
                        .padding(.horizontal, skin.size.s12)
                }
                AinkradNavListRow(
                    icon: icon(row.item), label: label(row.item), count: count?(row.item), isSelected: row.isSelected,
                    pill: glides ? pill : nil
                ) {
                    if reduceMotion {
                        selection = row.item
                    } else if glides {
                        withAnimation(
                            skin.animation(AinkradAnimationToken(curve: "spring", response: 0.34, damping: 0.8))
                        ) {
                            selection = row.item
                        }
                    } else {
                        withAnimation(AinkradMotion.materialize) { selection = row.item }
                    }
                }
            }
        }
    }
}

private struct AinkradNavListRow: View {
    let icon: String?
    let label: String
    let count: AinkradNavCount?
    let isSelected: Bool
    var pill: Namespace.ID?
    let action: () -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var bumped = false

    @ViewBuilder private var countView: some View {
        if let count {
            let font = skin.font(
                AinkradFontToken(sizeKey: "t10", weight: count.tone == nil ? nil : "semibold", mono: "family"))
            if let tone = count.tone {
                let fill = tone.color(skin)
                Text(count.text).font(font).foregroundStyle(fill.contrastingText)
                    .padding(.horizontal, skin.size.s6)
                    .background(fill, in: Capsule())
            } else {
                Text(count.text).font(font).foregroundStyle(skin.color(skin.text.faint))
            }
        }
    }

    var body: some View {
        if let pill { glidingBody(pill) } else { standardBody }
    }

    /// The Citadel sidebar row: 30 pt, tinted line icon, white when selected over the shared gliding pill.
    private func glidingBody(_ pill: Namespace.ID) -> some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s8, style: .continuous)
        let iconTint = skin.color(skin.palette.accentPrimary)
        return Button(action: action) {
            HStack(spacing: skin.size.s10) {
                if let icon {
                    Image(systemName: icon)
                        .font(skin.font(AinkradFontToken(sizeKey: "t14", weight: "regular"), typography: typo))
                        .foregroundStyle(
                            isSelected
                                ? skin.color(.palette("foreground", 1))
                                : iconTint.opacity(hovering ? skin.opacity.o95 : skin.opacity.o75)
                        )
                        .frame(width: skin.size.s18)
                }
                Text(label)
                    .font(skin.font(AinkradFontToken(sizeKey: "t13", weight: "medium"), typography: typo))
                    .foregroundStyle(
                        skin.color(.palette("foreground", isSelected || hovering ? 1 : skin.opacity.o82)))
                Spacer(minLength: 0)
                countView
                    .scaleEffect(bumped ? 1.18 : 1)
                    .brightness(bumped ? skin.opacity.o20 : 0)
            }
            .padding(.horizontal, skin.size.s10)
            .frame(height: skin.size.s30)
            .background {
                if isSelected {
                    shape.fill(iconTint.opacity(skin.opacity.o25)).matchedGeometryEffect(id: "selection", in: pill)
                } else if hovering {
                    shape.fill(skin.color(.palette("foreground", skin.opacity.o05)))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(label)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
        .onChange(of: count?.text) { old, new in
            guard old != nil, new != nil, !reduceMotion else { return }
            withAnimation(skin.animation(AinkradAnimationToken(curve: "spring", response: 0.25, damping: 0.45))) {
                bumped = true
            } completion: {
                withAnimation(skin.animation(skin.motion.hover)) { bumped = false }
            }
        }
    }

    private var standardBody: some View {
        let nav = skin.components.navListRow
        let tick = skin.roles.accentTick
        let shape = AinkradSkinShape(token: nav.shape)
        var state: AinkradControlState = []
        if isSelected { state.insert(.selected) }
        if hovering { state.insert(.hover) }

        return Button(action: action) {
            HStack(spacing: skin.spacing.sm) {
                Rectangle()
                    .fill(skin.color(tick.fill))
                    .frame(width: skin.usesNativeGlass ? 0 : nav.tickWidth)
                    .opacity(isSelected && !skin.usesNativeGlass ? 1 : 0)
                    .shadow(
                        color: skin.color(tick.glow.color, state: isSelected ? [.selected] : []),
                        radius: tick.glow.radius.rest)
                if let icon {
                    Image(systemName: icon)
                        .font(skin.font(nav.glyphFont, typography: typo))
                        .frame(width: nav.glyphWidth)
                }
                Text(label)
                    .font(skin.font(isSelected ? nav.bodySelectedFont : nav.bodyFont, typography: typo))
                Spacer(minLength: 0)
                countView
            }
            .foregroundStyle(
                skin.usesNativeGlass
                    ? (isSelected
                        ? skin.color(skin.palette.accentPrimary).contrastingText : skin.color(skin.text.primary))
                    : skin.color(nav.fg, state: state)
            )
            .padding(.vertical, skin.spacing.sm)
            .padding(.horizontal, skin.spacing.sm)
            .background {
                if skin.usesNativeGlass {
                    NativeSelectionBackground(
                        isSelected: isSelected, isHovered: hovering, accent: skin.color(skin.palette.accentPrimary))
                } else {
                    shape.fill(skin.color(nav.fill, state: state))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}
