import SwiftUI

/// The tone of an `AinkradDockButton`.
public enum AinkradDockTone: Sendable {
    case plain, primary, warning, success, danger
}

/// The hero "dock" button of the Citadel screens: an icon and a label on a soft glass tile that lifts on hover and
/// presses in. `primary` is the accent-washed call to action; `warning`, `success` and `danger` tint the label (and,
/// for danger, the tile) for Pause, Resume, Stop and Terminate. Three modifiers widen it: `tinted(_:busyTitle:)` is a
/// call to action in any colour (with a busy state that swaps the label for a spinner), `toggled(_:tint:)` gives it an
/// on state (Follow live, a Grid / List switch), and `icon(_:)` replaces the symbol with any view (an agent figure).
public struct AinkradDockButton: View {
    private let title: String
    private let systemImage: String?
    private let tone: AinkradDockTone
    private let isEnabled: Bool
    private let height: CGFloat?
    private let fillsWidth: Bool
    private let action: () -> Void
    private var tint: Color?
    private var busyTitle: String?
    private var isOn: Bool?
    private var onTint: Color?
    private var helpText: String?
    private var iconView: AnyView?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(
        _ title: String, systemImage: String? = nil, tone: AinkradDockTone = .plain, isEnabled: Bool = true,
        height: CGFloat? = nil, fillsWidth: Bool = false, action: @escaping () -> Void
    ) {
        self.height = height
        self.fillsWidth = fillsWidth
        self.title = title
        self.systemImage = systemImage
        self.tone = tone
        self.isEnabled = isEnabled
        self.action = action
    }

    /// Fills the tile with `tint` instead of a tone: the recommended action of a card, in the card's colour. While
    /// `busyTitle` is set the label becomes a spinner and that text, and the action is held back.
    public func tinted(_ tint: Color, busyTitle: String? = nil) -> Self {
        var copy = self
        copy.tint = tint
        copy.busyTitle = busyTitle
        return copy
    }

    /// Gives the button an on state: the label and a wash take `tint` (the secondary accent by default).
    public func toggled(_ isOn: Bool, tint: Color? = nil) -> Self {
        var copy = self
        copy.isOn = isOn
        copy.onTint = tint
        return copy
    }

    /// A tooltip.
    public func tooltip(_ text: String) -> Self {
        var copy = self
        copy.helpText = text
        return copy
    }

    /// Replaces the symbol with any view, drawn in a 16 pt square.
    public func icon<Icon: View>(@ViewBuilder _ icon: () -> Icon) -> Self {
        var copy = self
        copy.iconView = AnyView(icon())
        return copy
    }

    public var body: some View {
        Button(action: { if busyTitle == nil { action() } }) {
            HStack(spacing: skin.size.s6) {
                if busyTitle != nil {
                    ProgressView().controlSize(.small)
                } else if let iconView {
                    iconView.frame(width: skin.size.s16, height: skin.size.s16)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(skin.font(AinkradFontToken(sizeKey: "t14", weight: "medium"), typography: typo))
                        .frame(width: skin.size.s16, height: skin.size.s16)
                }
                Text(busyTitle ?? title)
                    .font(skin.font(AinkradFontToken(sizeKey: "t12", weight: "medium"), typography: typo))
            }
            .foregroundStyle(foreground)
            .padding(.leading, hasIcon && busyTitle == nil ? skin.size.s9 : skin.size.s12)
            .padding(.trailing, skin.size.s12)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(height: height ?? skin.size.s34)
            .background {
                shape.fill(fill)
                if let tint { shape.fill(tint.opacity(hovering ? skin.opacity.o30 : skin.opacity.o22)) }
            }
            .overlay(shape.strokeBorder(stroke, lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(DockPressStyle(reduceMotion: reduceMotion))
        .help(helpText ?? "")
        .offset(y: hovering && isEnabled && !reduceMotion ? -skin.size.s2 : 0)
        .opacity(isEnabled ? 1 : skin.opacity.o45)
        .disabled(!isEnabled)
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .animation(skin.animation(skin.motion.hover), value: isOn)
        .onHover { hovering = $0 }
    }

    private var hasIcon: Bool { systemImage != nil || iconView != nil }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: skin.size.s10, style: .continuous) }

    private var toggleTint: Color { onTint ?? skin.color(skin.palette.accentSecondary) }

    private var foreground: Color {
        if tint != nil { return skin.color(.palette("foreground", 1)) }
        if isOn == true { return toggleTint }
        return switch tone {
        case .plain: skin.color(skin.text.primary)
        case .primary: skin.color(.palette("foreground", 1))
        case .warning: skin.color(skin.palette.warning)
        case .success: skin.color(skin.palette.success)
        case .danger: skin.color(skin.palette.danger)
        }
    }

    private var fill: Color {
        if tint != nil { return skin.color(.palette("foreground", skin.opacity.o05)) }
        if isOn == true { return toggleTint.opacity(skin.opacity.o14) }
        return switch tone {
        case .primary: skin.color(skin.palette.accentPrimary).opacity(hovering ? skin.opacity.o35 : skin.opacity.o25)
        case .danger: skin.color(skin.palette.danger).opacity(hovering ? skin.opacity.o16 : skin.opacity.o08)
        default: skin.color(.palette("foreground", hovering ? skin.opacity.o13 : skin.opacity.o07))
        }
    }

    private var stroke: Color {
        if let tint { return tint.opacity(skin.opacity.o45) }
        if isOn == true { return toggleTint.opacity(skin.opacity.o35) }
        return switch tone {
        case .primary: skin.color(skin.palette.accentPrimary).opacity(skin.opacity.o40)
        case .danger: skin.color(skin.palette.danger).opacity(skin.opacity.o22)
        default: skin.color(.palette("foreground", skin.opacity.o09))
        }
    }
}

/// A thin vertical rule between groups of dock buttons.
public struct AinkradDockSeparator: View {
    @Environment(\.ainkradSkin) private var skin
    public init() {}
    public var body: some View {
        Rectangle().fill(skin.color(.palette("foreground", skin.opacity.o10)))
            .frame(width: skin.size.s1, height: skin.size.s20)
            .padding(.horizontal, skin.size.s2)
    }
}

private struct DockPressStyle: ButtonStyle {
    let reduceMotion: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
    }
}
