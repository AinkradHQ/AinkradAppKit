import AinkradAppKitContract
import AppKit
import SwiftUI

/// Cardinal HUD switch — chamfered track (never a native `Toggle`), a
/// luminous thumb, and an accent glow that brightens while on.
public struct AinkradToggle: View {
    @Binding private var isOn: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>) { self._isOn = isOn }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple's switch, tinted with the accent.
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(skin.color(skin.palette.accentPrimary))
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let toggle = skin.components.toggle
        let shape = AinkradSkinShape(token: toggle.shape)
        return Button {
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                shape
                    .fill(skin.color(toggle.fill, state: state))
                shape
                    .strokeBorder(
                        skin.color(toggle.stroke.color, state: state),
                        lineWidth: toggle.stroke.width.resolve(state))
                Circle().fill(skin.color(toggle.knobColor)).padding(toggle.knobInset)
                    .shadow(
                        color: skin.color(
                            isOn ? toggle.knobSelectedShadowColor : toggle.knobShadow.color),
                        radius: toggle.knobShadow.radius)
            }
            .frame(width: toggle.width, height: toggle.height)
            .shadow(
                color: skin.color(toggle.glow.color, state: state), radius: toggle.glow.radius.resolve(state)
            )
            .contentShape(shape)
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

    private var state: AinkradControlState {
        var state: AinkradControlState = []
        if isOn { state.insert(.selected) }
        if hovering { state.insert(.hover) }
        return state
    }
}
