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

    func body(content: Content) -> some View {
        let row = skin.components.listRow
        let shape = AinkradSkinShape(token: row.shape)
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
