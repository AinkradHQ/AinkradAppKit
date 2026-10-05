import AinkradAppKitContract
import AppKit
import SwiftUI

/// Cardinal HUD switch — chamfered track (never a native `Toggle`), a
/// luminous thumb, and an accent glow that brightens while on.
public struct AinkradToggle: View {
    @Binding private var isOn: Bool
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>) { self._isOn = isOn }

    public var body: some View {
        Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                ChamferShape(cut: 6, corners: .all)
                    .fill(isOn ? theme.accentPrimary.opacity(0.9) : theme.surfaceElevated.opacity(0.6))
                ChamferShape(cut: 6, corners: .all)
                    .strokeBorder(
                        isOn ? theme.accentSecondary.opacity(0.75) : theme.foreground.opacity(hovering ? 0.35 : 0.18),
                        lineWidth: 1.25)
                Circle().fill(.white).padding(3)
                    .shadow(color: isOn ? theme.accentSecondary.opacity(0.75) : .black.opacity(0.4), radius: 3)
            }
            .frame(width: 40, height: 22)
            .shadow(color: theme.accentSecondary.opacity(isOn ? 0.45 : 0), radius: isOn ? 6 : 0)
            .contentShape(ChamferShape(cut: 6, corners: .all))
        }
        .buttonStyle(.plain)
        // It is a `Button`, never a native `Toggle`, so nothing announces that
        // it HAS a state — a listener heard "button" and could not tell on from
        // off. On/off is carried entirely by fill and glow.
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? "on" : "off")
        .animation(AinkradMotion.hover, value: isOn)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }
    }
}
