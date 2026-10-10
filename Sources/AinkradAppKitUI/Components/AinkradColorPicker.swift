import AinkradAppKitContract
import AppKit
import SwiftUI

// MARK: - Pure color conversion helpers (unit-testable)

/// sRGB components (each 0...1) parsed from a 6-digit `RRGGBB` hex string.
/// Accepts an optional leading `#`; returns nil unless the string yields
/// exactly 6 hex digits. Pure — unit-testable without SwiftUI/AppKit.
func rgbComponents(fromHex hex: String) -> (red: Double, green: Double, blue: Double)? {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6, s.allSatisfy({ $0.isHexDigit }) else { return nil }
    var value: UInt64 = 0
    Scanner(string: s).scanHexInt64(&value)
    return (
        Double((value & 0xFF0000) >> 16) / 255,  // design-lint: allow hex-color bit-mask parsing
        Double((value & 0x00FF00) >> 8) / 255,  // design-lint: allow hex-color bit-mask parsing
        Double(value & 0x0000FF) / 255  // design-lint: allow hex-color bit-mask parsing
    )
}

/// Uppercase 6-digit `RRGGBB` hex (no `#`) for sRGB components (each clamped to
/// 0...1). Deliberately matches the host's `Color.hexString` format so the
/// Appearance accent-override binding round-trips exactly. Pure — unit-testable.
func hexString(red: Double, green: Double, blue: Double) -> String {
    func channel(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
    return String(format: "%02X%02X%02X", channel(red), channel(green), channel(blue))
}

/// sRGB components of `color`, or nil if it can't be resolved to sRGB.
func rgbComponents(of color: Color) -> (red: Double, green: Double, blue: Double)? {
    guard let c = NSColor(color).usingColorSpace(.sRGB) else { return nil }
    return (Double(c.redComponent), Double(c.greenComponent), Double(c.blueComponent))
}

/// HSB components (each 0...1) of `color`, or nil if it can't be resolved.
func hsbComponents(of color: Color) -> (hue: Double, saturation: Double, brightness: Double)? {
    guard let c = NSColor(color).usingColorSpace(.sRGB) else { return nil }
    return (Double(c.hueComponent), Double(c.saturationComponent), Double(c.brightnessComponent))
}

/// A `Color` from a 6-digit `RRGGBB` hex string, or nil if unparseable.
func color(fromHex hex: String) -> Color? {
    guard let rgb = rgbComponents(fromHex: hex) else { return nil }
    return Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
}

// MARK: - AinkradColorPicker

/// Custom Cardinal HUD color well — a chamfered swatch trigger that, on tap,
/// opens a custom-drawn editor in a top-level `AinkradFloatingPanel` (the same
/// `PanelMaterialize` + floating-panel pattern as `AinkradSelect`), NEVER a
/// native `ColorPicker`/`NSColorPanel`/`.popover`. The editor drives the single
/// `Binding<Color>` through three HSB `AinkradSlider`s and a hex
/// `AinkradTextField`; the hex round-trips in the host's `RRGGBB` format so it
/// slots straight into the Appearance accent-override binding.
public struct AinkradColorPicker: View {
    @Binding private var selection: Color

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var isOpen = false

    public init(selection: Binding<Color>) {
        self._selection = selection
    }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple's colour well and the system colour panel.
            ColorPicker("", selection: $selection, supportsOpacity: false)
                .labelsHidden()
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        trigger
            .ainkradFloatingPanel(isPresented: $isOpen, maxHeight: skin.components.colorPicker.panelMaxHeight) {
                ColorPickerMaterialize {
                    ColorEditorPanelView(selection: $selection)
                }
            }
    }

    private var trigger: some View {
        let picker = skin.components.colorPicker
        let triggerState: AinkradControlState = isOpen ? [.focused] : []
        let swatchShape = AinkradSkinShape(token: picker.swatchShape)
        return Button {
            isOpen.toggle()
        } label: {
            swatchShape
                .fill(selection)
                .frame(width: picker.swatchWidth, height: picker.swatchHeight)
                .overlay(
                    swatchShape
                        .strokeBorder(
                            skin.color(picker.swatchStroke.color, state: triggerState),
                            lineWidth: picker.swatchStroke.width.resolve(triggerState))
                )
                .shadow(
                    color: skin.color(picker.swatchGlow.color, state: triggerState),
                    radius: picker.swatchGlow.radius.resolve(triggerState)
                )
                .contentShape(swatchShape)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: isOpen)
    }
}

/// Fades + scales the color editor in on appear (skipped under Reduce Motion) —
/// the same "materialize" look as the pickers' `PanelMaterialize`, replicated
/// here since that type is file-private to `AinkradPickers`.
private struct ColorPickerMaterialize<Content: View>: View {
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var appeared = false
    private let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        let materialize = skin.roles.materialize
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : materialize.scale, anchor: .top)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(skin.animation(materialize.animation)) { appeared = true }
                }
            }
    }
}

/// The floating-panel editor body: a live preview strip, three HSB sliders, and
/// a hex field, all writing back through the single `Binding<Color>`. HSB is the
/// panel's working state (seeded once from `selection` on appear) so dragging a
/// slider never loses hue when saturation/brightness hit zero. Only user edits
/// (slider setters / hex submit) write `selection`; the on-appear seed does not.
private struct ColorEditorPanelView: View {
    @Binding var selection: Color

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    @State private var hue: Double = 0
    @State private var saturation: Double = 0
    @State private var brightness: Double = 1
    @State private var hexText: String = ""

    var body: some View {
        let popover = skin.roles.popover
        let picker = skin.components.colorPicker
        let shape = AinkradSkinShape(token: popover.shape)
        VStack(alignment: .leading, spacing: AinkradSpacing.md) {
            preview
            sliderRow("Hue", binding: hsbBinding(.hue))
            sliderRow("Saturation", binding: hsbBinding(.saturation))
            sliderRow("Brightness", binding: hsbBinding(.brightness))
            hexRow
        }
        .padding(AinkradSpacing.md)
        .frame(width: picker.panelWidth)
        .background(shape.fill(skin.color(popover.fill)))
        .overlay(
            shape.strokeBorder(skin.color(popover.stroke.color), lineWidth: popover.stroke.width.resolve([]))
        )
        .shadow(color: skin.color(popover.shadow.color), radius: popover.shadow.radius, y: popover.shadow.y)
        .onAppear(perform: seedFromSelection)
    }

    private var preview: some View {
        let shape = AinkradSkinShape(token: skin.components.colorPicker.previewShape)
        let picked = Color(  // design-lint: allow raw-color user-picked colour
            hue: hue, saturation: saturation, brightness: brightness)
        return shape.fill(picked)
            .frame(height: skin.components.colorPicker.previewHeight)
            .overlay(
                shape.strokeBorder(
                    skin.color(skin.components.colorPicker.previewStroke.color),
                    lineWidth: skin.components.colorPicker.previewStroke.width.resolve([])))
    }

    private func sliderRow(_ title: String, binding: Binding<Double>) -> some View {
        let picker = skin.components.colorPicker
        return VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
            HStack(spacing: AinkradSpacing.xs) {
                Rectangle()
                    .fill(skin.color(picker.channelTickColor))
                    .frame(width: picker.channelTickWidth, height: picker.channelTickHeight)
                Text(title)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(skin.color(picker.labelColor))
            }
            AinkradSlider(value: binding, in: 0...1)
        }
    }

    private var hexRow: some View {
        HStack(spacing: AinkradSpacing.sm) {
            Text("HEX")
                .font(AinkradFontResolver.font(.caption, typography: typo))
                .foregroundStyle(skin.color(skin.components.colorPicker.valueColor))
            AinkradTextField(text: $hexText, placeholder: "RRGGBB")
                .onSubmit(applyHex)
        }
    }

    /// A binding to one HSB channel: reads the working `@State`, and on write
    /// stores it AND pushes the composed color out through `selection`.
    private func hsbBinding(_ ch: HSBChannel) -> Binding<Double> {
        Binding(
            get: { channel(ch) },
            set: { newValue in
                setChannel(ch, newValue)
                writeBackFromHSB()
            }
        )
    }

    private enum HSBChannel { case hue, saturation, brightness }

    private func channel(_ c: HSBChannel) -> Double {
        switch c {
        case .hue: return hue
        case .saturation: return saturation
        case .brightness: return brightness
        }
    }

    private func setChannel(_ c: HSBChannel, _ v: Double) {
        switch c {
        case .hue: hue = v
        case .saturation: saturation = v
        case .brightness: brightness = v
        }
    }

    /// Seeds the working HSB + hex state from the incoming color. Sets `@State`
    /// directly (not via the slider bindings) so it never writes `selection`.
    private func seedFromSelection() {
        if let hsb = hsbComponents(of: selection) {
            hue = hsb.hue
            saturation = hsb.saturation
            brightness = hsb.brightness
        }
        if let rgb = rgbComponents(of: selection) {
            hexText = hexString(red: rgb.red, green: rgb.green, blue: rgb.blue)
        }
    }

    private func writeBackFromHSB() {
        let color = Color(  // design-lint: allow raw-color user-picked colour
            hue: hue, saturation: saturation, brightness: brightness)
        selection = color
        if let rgb = rgbComponents(of: color) {
            hexText = hexString(red: rgb.red, green: rgb.green, blue: rgb.blue)
        }
    }

    private func applyHex() {
        guard let rgb = rgbComponents(fromHex: hexText) else {
            // Restore the field to the last valid color on a bad entry.
            if let cur = rgbComponents(of: selection) {
                hexText = hexString(red: cur.red, green: cur.green, blue: cur.blue)
            }
            return
        }
        let color = Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
        if let hsb = hsbComponents(of: color) {
            hue = hsb.hue
            saturation = hsb.saturation
            brightness = hsb.brightness
        }
        selection = color
        hexText = hexString(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}
