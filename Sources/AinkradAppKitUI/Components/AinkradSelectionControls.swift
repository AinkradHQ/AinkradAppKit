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

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>, label: String? = nil) {
        self._isOn = isOn
        self.label = label
    }

    public var body: some View {
        Button {
            isOn = checkboxToggled(isOn)
        } label: {
            HStack(spacing: AinkradSpacing.sm) {
                ZStack {
                    ChamferShape(cut: 3)
                        .fill(isOn ? theme.accentSecondary.opacity(0.22) : theme.surfaceElevated.opacity(0.5))
                    ChamferShape(cut: 3)
                        .strokeBorder(theme.accentSecondary.opacity(isOn || hovering ? 0.85 : 0.4), lineWidth: 1.25)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.accentSecondary)
                    }
                }
                .frame(width: 18, height: 18)
                .shadow(color: theme.accentSecondary.opacity(isOn ? 0.5 : 0), radius: 4)

                if let label {
                    Text(label)
                        .font(AinkradFontResolver.font(.body, typography: typo))
                        .foregroundStyle(theme.foreground)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? 1.04 : 1.0)
        .animation(AinkradMotion.hover, value: isOn)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}

/// Custom radio group — a vertical stack of chamfer-hex markers (never a
/// native `Picker`). Tapping an option replaces `selection`.
public struct AinkradRadioGroup<T: Hashable>: View {
    private let options: [T]
    @Binding private var selection: T
    private let label: (T) -> String

    @Environment(\.ainkradTheme) private var theme
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
        return Button {
            selection = option
        } label: {
            HStack(spacing: AinkradSpacing.sm) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            theme.accentSecondary.opacity(isSelected || isHovered ? 0.9 : 0.4), lineWidth: 1.25)
                    if isSelected {
                        // Diamond marker — the Cardinal HUD radio "on" glyph,
                        // drawn (not a native radio dot).
                        Diamond()
                            .fill(theme.accentSecondary)
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 16, height: 16)
                .shadow(color: theme.accentSecondary.opacity(isSelected ? 0.5 : 0), radius: 4)

                Text(label(option))
                    .font(AinkradFontResolver.font(.body, typography: typo))
                    .foregroundStyle(theme.foreground)
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
