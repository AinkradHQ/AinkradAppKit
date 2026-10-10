import AinkradAppKitContract
import SwiftUI

/// Flips a boolean. Pure — the reducer `AinkradCheckbox` calls on tap,
/// unit-testable without SwiftUI.
public func checkboxToggled(_ isOn: Bool) -> Bool { !isOn }

/// Pairs each radio option with whether it is the current selection. Pure —
/// the shape `AinkradRadioGroup`'s rows are built from, unit-testable
/// without SwiftUI.
public func radioOptionRows<T: Hashable>(options: [T], selected: T) -> [(option: T, isSelected: Bool)] {
    options.map { ($0, $0 == selected) }
}

/// Custom chamfer checkbox — accent checkmark drawn on a `ChamferShape` box
/// (never a native `Toggle`/checkbox control). Optional trailing label.
public struct AinkradCheckbox: View {
    @Binding private var isOn: Bool
    private let label: String?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>, label: String? = nil) {
        self._isOn = isOn
        self.label = label
    }

    public var body: some View {
        let checkbox = skin.components.checkbox
        let shape = AinkradSkinShape(token: checkbox.shape)
        Button {
            isOn = checkboxToggled(isOn)
        } label: {
            HStack(spacing: AinkradSpacing.sm) {
                ZStack {
                    shape
                        .fill(skin.color(checkbox.fill, state: state))
                    shape
                        .strokeBorder(
                            skin.color(checkbox.stroke.color, state: state),
                            lineWidth: checkbox.stroke.width.resolve(state))
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(skin.font(checkbox.checkGlyphFont, typography: typo))
                            .foregroundStyle(skin.color(skin.palette.accentSecondary))
                    }
                }
                .frame(width: checkbox.size, height: checkbox.size)
                .shadow(
                    color: skin.color(checkbox.glow.color, state: state),
                    radius: checkbox.glow.radius.resolve(state))

                if let label {
                    Text(label)
                        .font(skin.font(checkbox.labelFont, typography: typo))
                        .foregroundStyle(skin.color(skin.text.primary))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? checkbox.hoverScale : 1.0)
        .animation(AinkradMotion.hover, value: isOn)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if isOn { state.insert(.selected) }
        if hovering { state.insert(.hover) }
        return state
    }
}

/// Custom radio group — a vertical stack of chamfer-hex markers (never a
/// native `Picker`). Tapping an option replaces `selection`.
public struct AinkradRadioGroup<T: Hashable>: View {
    private let options: [T]
    @Binding private var selection: T
    private let label: (T) -> String

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hoveredOption: T?

    public init(options: [T], selection: Binding<T>, label: @escaping (T) -> String) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.sm) {
            ForEach(options, id: \.self) { option in row(option) }
        }
    }

    private func row(_ option: T) -> some View {
        let isSelected = option == selection
        let isHovered = hoveredOption == option
        var rowState: AinkradControlState = []
        if isSelected { rowState.insert(.selected) }
        if isHovered { rowState.insert(.hover) }
        let radio = skin.components.radioGroup
        return Button {
            selection = option
        } label: {
            HStack(spacing: AinkradSpacing.sm) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            skin.color(radio.ringStroke.color, state: rowState),
                            lineWidth: radio.ringStroke.width.resolve(rowState))
                    if isSelected {
                        // `markerShape`: Neon's drawn diamond (the Cardinal HUD
                        // radio "on" glyph), or a dot for `Circle`.
                        Group {
                            if radio.markerShape == "Circle" {
                                Circle().fill(skin.color(radio.markerFill))
                            } else {
                                Diamond().fill(skin.color(radio.markerFill))
                            }
                        }
                        .frame(width: radio.markerSize, height: radio.markerSize)
                    }
                }
                .frame(width: radio.ringSize, height: radio.ringSize)
                .shadow(
                    color: skin.color(radio.glow.color, state: rowState),
                    radius: radio.glow.radius.resolve(rowState))

                Text(label(option))
                    .font(skin.font(radio.labelFont, typography: typo))
                    .foregroundStyle(skin.color(skin.text.primary))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(AinkradMotion.hover, value: isSelected)
        .animation(AinkradMotion.hover, value: isHovered)
        .onHover { hovering in hoveredOption = hovering ? option : (hoveredOption == option ? nil : hoveredOption) }
    }
}

/// A diamond glyph — the Cardinal HUD "selected" marker used by
/// `AinkradRadioGroup` (and reusable anywhere a drawn, non-system-glyph
/// diamond is needed).
private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
