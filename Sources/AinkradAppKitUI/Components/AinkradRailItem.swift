import SwiftUI

/// Icon-only tile for a vertical rail: chamfered fill, glowing accent edge,
/// hover lift, an unread badge and an optional corner glyph.
public struct AinkradRailItem: View {
    private let systemName: String
    private let help: String
    private let isSelected: Bool
    private let unread: Int
    private let isDimmed: Bool
    private let cornerSymbol: String?
    private let namespace: Namespace.ID?
    private let action: (() -> Void)?

    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// `action == nil` leaves the click to an enclosing control (a menu button's label).
    public init(
        systemName: String, help: String, isSelected: Bool,
        unread: Int = 0, isDimmed: Bool = false, cornerSymbol: String? = nil,
        action: (() -> Void)?
    ) {
        self.systemName = systemName
        self.help = help
        self.isSelected = isSelected
        self.unread = unread
        self.isDimmed = isDimmed
        self.cornerSymbol = cornerSymbol
        self.namespace = nil
        self.action = action
    }

    /// The same tile, with the selection indicator sliding between items.
    public init(
        systemName: String, help: String, isSelected: Bool,
        unread: Int = 0, isDimmed: Bool = false, cornerSymbol: String? = nil,
        selectionNamespace: Namespace.ID, action: (() -> Void)?
    ) {
        self.systemName = systemName
        self.help = help
        self.isSelected = isSelected
        self.unread = unread
        self.isDimmed = isDimmed
        self.cornerSymbol = cornerSymbol
        self.namespace = selectionNamespace
        self.action = action
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if isSelected { state.insert(.selected) }
        if hovering { state.insert(.hover) }
        return state
    }

    private var glyphColor: Color {
        let tile = skin.components.railItem
        if isDimmed && state.isEmpty { return skin.color(tile.glyphDimmedColor) }
        return skin.color(tile.glyphColor, state: state)
    }

    public var body: some View {
        let tile = skin.components.railItem
        let shape = AinkradSkinShape(token: tile.shape)
        Image(systemName: systemName)
            .font(skin.font(isSelected ? tile.glyphSelectedFont : tile.glyphFont, typography: typo))
            .foregroundStyle(glyphColor)
            .shadow(
                color: skin.color(tile.glyphGlow.color, state: state), radius: tile.glyphGlow.radius.resolve(state)
            )
            .frame(width: tile.size, height: tile.size)
            .background(shape.fill(skin.color(tile.fill, state: state)))
            .overlay(
                shape.strokeBorder(
                    skin.color(tile.stroke.color, state: state), lineWidth: tile.stroke.width.resolve(state))
            )
            .shadow(color: skin.color(tile.glow.color, state: state), radius: tile.glow.radius.resolve(state))
            .overlay(alignment: .topTrailing) {
                if let text = ainkradRailBadgeText(unread) {
                    AinkradBadge(text: text, status: .danger)
                        .fixedSize()
                        .scaleEffect(tile.badgeScale, anchor: .topTrailing)
                        .offset(x: tile.badgeOffsetX, y: tile.badgeOffsetY)
                        .opacity(tile.badgeOpacity.resolve(state))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let cornerSymbol {
                    Image(systemName: cornerSymbol)
                        .font(skin.font(tile.cornerFont, typography: typo))
                        .foregroundStyle(skin.color(tile.cornerColor))
                        .padding(tile.cornerPadding)
                        .background(Circle().fill(skin.color(tile.cornerFill)))
                        .offset(x: tile.cornerOffset, y: tile.cornerOffset)
                }
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) { edge(tile) }
            .scaleEffect(hovering && !isSelected && !reduceMotion ? tile.hoverScale : 1)
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .modifier(RailItemTap(action: action))
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: isSelected)
            .help(help)
            .accessibilityLabel(help)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private func edge(_ tile: RailItemTokens) -> some View {
        let capsule = Capsule().fill(skin.color(tile.edgeColor))
            .frame(width: tile.edgeWidth, height: tile.edgeHeight.resolve(state))
            .shadow(color: skin.color(tile.edgeGlow.color, state: state), radius: tile.edgeGlow.radius.resolve(state))
        if let namespace, isSelected {
            capsule.matchedGeometryEffect(id: railItemEdgeID, in: namespace)
        } else {
            capsule
        }
    }
}

private let railItemEdgeID = "ainkradRailItemEdge"

/// Attaches a tap only when there is one, so a tile used as a button's label
/// leaves the click to that button.
private struct RailItemTap: ViewModifier {
    let action: (() -> Void)?
    func body(content: Content) -> some View {
        if let action { content.onTapGesture(perform: action) } else { content }
    }
}

/// Unread count as shown on the badge: `nil` for none, `"99+"` above 99.
func ainkradRailBadgeText(_ unread: Int) -> String? {
    guard unread > 0 else { return nil }
    return unread > 99 ? "99+" : "\(unread)"
}
