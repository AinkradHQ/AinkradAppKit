import SwiftUI

/// The tone of an `AinkradDockButton`.
public enum AinkradDockTone: Sendable {
    case plain, primary, warning, success, danger
}

/// The hero "dock" button of the Citadel screens: an icon and a label on a soft glass tile that lifts on hover and
/// presses in. `primary` is the accent-washed call to action; `warning`, `success` and `danger` tint the label (and,
/// for danger, the tile) for Pause, Resume, Stop and Terminate.
public struct AinkradDockButton: View {
    private let title: String
    private let systemImage: String?
    private let tone: AinkradDockTone
    private let isEnabled: Bool
    private let height: CGFloat?
    private let fillsWidth: Bool
    private let action: () -> Void

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

    public var body: some View {
        Button(action: action) {
            HStack(spacing: skin.size.s6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(skin.font(AinkradFontToken(sizeKey: "t14", weight: "medium"), typography: typo))
                        .frame(width: skin.size.s16, height: skin.size.s16)
                }
                Text(title).font(skin.font(AinkradFontToken(sizeKey: "t12", weight: "medium"), typography: typo))
            }
            .foregroundStyle(foreground)
            .padding(.leading, systemImage == nil ? skin.size.s12 : skin.size.s9)
            .padding(.trailing, skin.size.s12)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(height: height ?? skin.size.s34)
            .background(fill, in: shape)
            .overlay(shape.strokeBorder(stroke, lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(DockPressStyle(reduceMotion: reduceMotion))
        .offset(y: hovering && isEnabled && !reduceMotion ? -skin.size.s2 : 0)
        .opacity(isEnabled ? 1 : skin.opacity.o45)
        .disabled(!isEnabled)
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .onHover { hovering = $0 }
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: skin.size.s10, style: .continuous) }

    private var foreground: Color {
        switch tone {
        case .plain: skin.color(skin.text.primary)
        case .primary: skin.color(.palette("foreground", 1))
        case .warning: skin.color(skin.palette.warning)
        case .success: skin.color(skin.palette.success)
        case .danger: skin.color(skin.palette.danger)
        }
    }

    private var fill: Color {
        switch tone {
        case .primary: skin.color(skin.palette.accentPrimary).opacity(hovering ? skin.opacity.o35 : skin.opacity.o25)
        case .danger: skin.color(skin.palette.danger).opacity(hovering ? skin.opacity.o16 : skin.opacity.o08)
        default: skin.color(.palette("foreground", hovering ? skin.opacity.o13 : skin.opacity.o07))
        }
    }

    private var stroke: Color {
        switch tone {
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
