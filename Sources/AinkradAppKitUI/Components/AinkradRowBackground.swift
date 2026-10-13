import SwiftUI

/// Visual state of a row: selected beats hovered.
public enum AinkradRowState: Sendable, Equatable {
    case rest, hovered, selected
}

/// Collapses the two flags a row tracks into one state; selected wins.
func ainkradRowState(isSelected: Bool, isHovered: Bool) -> AinkradRowState {
    isSelected ? .selected : (isHovered ? .hovered : .rest)
}

private struct AinkradRowBackground: ViewModifier {
    let rowState: AinkradRowState

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    private var state: AinkradControlState {
        switch rowState {
        case .rest: []
        case .hovered: .hover
        case .selected: .selected
        }
    }

    @ViewBuilder func body(content: Content) -> some View {
        if skin.usesNativeGlass {
            // Glass Native: the macOS selection highlight, no accent bar.
            content
                .foregroundStyle(
                    rowState == .selected
                        ? skin.color(skin.palette.accentPrimary).contrastingText : skin.color(skin.text.primary)
                )
                .background(
                    NativeSelectionBackground(
                        isSelected: rowState == .selected, isHovered: rowState == .hovered,
                        accent: skin.color(skin.palette.accentPrimary))
                )
                .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: rowState)
        } else {
            kitBody(content)
        }
    }

    private func kitBody(_ content: Content) -> some View {
        let row = skin.components.listRow
        let shape = AinkradSkinShape(token: row.shape)
        return
            content
            .background(shape.fill(skin.color(row.fill, state: state)))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(skin.color(skin.roles.accentTick.fill))
                    .frame(width: row.edgeWidth.resolve(state))
                    .shadow(
                        color: skin.color(row.edgeGlow.color, state: state), radius: row.edgeGlow.radius.resolve(state))
            }
            .clipShape(shape)
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: rowState)
    }
}

extension View {
    /// The hover/selected wash and leading accent bar of a list row, from the
    /// `listRow` skin tokens. The caller owns hover; selected beats hovered.
    public func ainkradRowBackground(isSelected: Bool, isHovered: Bool) -> some View {
        modifier(AinkradRowBackground(rowState: ainkradRowState(isSelected: isSelected, isHovered: isHovered)))
    }
}

/// How a row draws its selection in `ainkradRowBackground(isSelected:isHovered:style:)`.
public enum AinkradRowSelectionStyle: Sendable, Equatable {
    /// Forge's file tree (`.f.sel`): a 6 pt rounded wash in the primary accent
    /// at 22 % when selected, a faint white wash on hover. The same in Neon
    /// and Glass; no accent bar.
    case fill
    /// Grimoire's thread list (`.thread.sel`): under Neon a chamfered card
    /// (8 pt cut) filled with the primary accent at 22 %; under Glass a 12 pt
    /// rounded card with the same fill and a white 12 % hairline. Hover is the
    /// faint 6 pt wash.
    case card
}

private struct AinkradStyledRowBackground: ViewModifier {
    let rowState: AinkradRowState
    let style: AinkradRowSelectionStyle

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background { background }
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: rowState)
    }

    @ViewBuilder private var background: some View {
        let selectedFill = theme.accentPrimary.opacity(skin.opacity.o22)
        switch (rowState, style) {
        case (.rest, _):
            Color.clear
        case (.hovered, _):
            RoundedRectangle(cornerRadius: skin.size.s6, style: .continuous)
                .fill(skin.color(skin.palette.white).opacity(skin.opacity.o05))
        case (.selected, .fill):
            RoundedRectangle(cornerRadius: skin.size.s6, style: .continuous).fill(selectedFill)
        case (.selected, .card) where skin.usesNativeGlass:
            RoundedRectangle(cornerRadius: skin.size.s12, style: .continuous)
                .fill(selectedFill)
                .overlay(
                    RoundedRectangle(cornerRadius: skin.size.s12, style: .continuous)
                        .strokeBorder(skin.color(skin.palette.white).opacity(skin.opacity.o12), lineWidth: 1))
        case (.selected, .card):
            skin.shape(cut: skin.cut.c8).fill(selectedFill)
        }
    }
}

extension View {
    /// A row's hover and selected background in one of the mockups'
    /// selection styles (see `AinkradRowSelectionStyle`). Unlike the plain
    /// `ainkradRowBackground(isSelected:isHovered:)` it leaves the row's text
    /// colour to the caller and draws no accent bar.
    public func ainkradRowBackground(
        isSelected: Bool, isHovered: Bool, style: AinkradRowSelectionStyle
    ) -> some View {
        modifier(
            AinkradStyledRowBackground(
                rowState: ainkradRowState(isSelected: isSelected, isHovered: isHovered), style: style))
    }
}
