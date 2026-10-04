import AinkradAppKitContract
import AinkradAppKitUI
import SwiftUI

/// How a row arranges label and control. Chosen from the detail pane's
/// width, not the window's — a narrow pane inside a wide window still stacks.
public enum SettingsRowLayout: Sendable, Equatable {
    case stacked
    case sideBySide

    public init(detailWidth: CGFloat) {
        self = detailWidth > SettingsMetrics.wideBreakpoint ? .sideBySide : .stacked
    }
}

/// How a field is presented. A `.custom` field is not a control that fits a
/// 220pt trailing column — it is an entire pane (a manager UI, an editor)
/// that draws its own headings and its own cards. Rendering one through the
/// row path clamps it into the control rail and wraps it in a second layer of
/// card chrome, so it gets its own presentation instead: full width, no
/// label/control split, no row chrome.
public enum SettingsFieldPresentation: Sendable, Equatable {
    /// Label on the left, control on the shared trailing rail, row chrome.
    case row
    /// The field owns the full content width and draws its own chrome.
    case pane
}

/// One row = one setting. Label, help on the second line (never a tooltip —
/// hover-hidden explanations make settings unlearnable), optional badges, and
/// the control in a fixed-width trailing column so every control in a pane
/// lines up on one vertical rail.
public struct SettingsRow: View {
    @Environment(\.ainkradTheme) private var tokens
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    private let field: SettingsField
    private let layout: SettingsRowLayout
    @State private var isHovered = false

    public init(field: SettingsField, layout: SettingsRowLayout) {
        self.field = field
        self.layout = layout
    }

    /// `.custom` is a pane; the seven real control kinds are rows. Pure, so
    /// the split is testable without rendering anything.
    public static func presentation(for field: SettingsField) -> SettingsFieldPresentation {
        switch field.kind {
        case .custom: return .pane
        case .toggle, .select, .slider, .text, .secure, .shortcut, .action: return .row
        }
    }

    /// A segmented control holds a handful of short choices; past that it runs
    /// off the trailing rail (a folder list, a font list), so it becomes a menu.
    static func usesMenu(optionCount: Int) -> Bool { optionCount > 4 }

    public static func badges(for field: SettingsField) -> [String] {
        var result: [String] = []
        if field.isAdvanced { result.append("Advanced") }
        if field.requiresRestart { result.append("Restart required") }
        return result
    }

    public static func showsRevert(for field: SettingsField) -> Bool {
        field.reset != nil && field.isModified()
    }

    /// Quantizes `value` to the nearest multiple of `step` relative to
    /// `range.lowerBound`, then clamps to `range`. `AinkradSlider` has no
    /// native step; this is the glue that gives `.slider(step:)` teeth
    /// without touching the shared `AinkradAppKitUI` component. A
    /// non-positive `step` (0 or negative) disables quantization — the value
    /// passes through unchanged aside from the clamp, avoiding a
    /// divide-by-zero. Pure — unit-testable without a rendered view.
    public static func quantize(_ value: Double, step: Double, range: ClosedRange<Double>) -> Double {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        guard step > 0 else { return clamped }
        let steps = ((clamped - range.lowerBound) / step).rounded()
        let quantized = range.lowerBound + steps * step
        return min(max(quantized, range.lowerBound), range.upperBound)
    }

    @ViewBuilder
    public var body: some View {
        switch Self.presentation(for: field) {
        case .pane: paneBody
        case .row: rowBody
        }
    }

    /// A pane occupies the full content width and is not wrapped: no control
    /// column (which would squeeze a whole manager UI into 220pt), no chamfer
    /// fill, and no hover border (which would light up around the entire pane
    /// whenever the pointer entered it). The pane draws its own headings and
    /// cards.
    ///
    /// It does get the same inset a row gets inside its card, for two
    /// reasons: pane content would otherwise sit flush against the
    /// deep-link highlight stroke that can be drawn around it, and pane text
    /// would start 14pt to the left of row text on a mixed page. Matching
    /// `rowBody`'s padding keeps every page on one left rail.
    private var paneBody: some View {
        control
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AinkradSpacing.md)
    }

    /// The row path is `AinkradFormRow` — the kit's form row — plus the
    /// settings-specific card chrome. Badges and the revert affordance are
    /// handed to FormRow's own slots rather than re-implemented here, and the
    /// fixed control width is what puts every control on one vertical rail.
    private var rowBody: some View {
        AinkradFormRow(
            title: field.label,
            help: field.help,
            badges: Self.badges(for: field).map { $0.uppercased() },
            controlWidth: layout == .sideBySide ? SettingsMetrics.controlColumnWidth : nil,
            // Handed to FormRow whenever the affordance is *meaningful*
            // (modified + resettable), not only while hovered. Passing it
            // conditionally on `isHovered` would add/remove the button from
            // the layout on hover, changing the row's height. Reserving the
            // space and fading the button's opacity on hover instead keeps
            // geometry constant — only the paint changes.
            accessory: Self.showsRevert(for: field) ? { AnyView(revertButton) } : nil
        ) {
            control
        }
        .padding(AinkradSpacing.md)
        .background(ChamferShape(cut: AinkradRadius.md).fill(tokens.surfaceElevated.opacity(0.5)))
        .overlay(
            ChamferShape(cut: AinkradRadius.md)
                .strokeBorder(tokens.accentPrimary.opacity(isHovered ? 0.3 : 0.15), lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: AinkradMotion.durationFast), value: isHovered)
    }

    /// Restores this field's default. Lives here rather than in FormRow
    /// because "modified vs default" is a settings concept the kit has no
    /// opinion about. Always occupies its layout space when the affordance
    /// is meaningful (see `rowBody`); only its opacity — not its presence —
    /// responds to hover, so hovering never changes the row's height.
    @ViewBuilder
    private var revertButton: some View {
        if let reset = field.reset {
            Button(action: reset) {
                // Sizes an SF Symbol glyph, not text — the kit font API does
                // not apply to icon glyphs.
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 10))
                    .foregroundStyle(tokens.accentSecondary.opacity(0.9))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
            .allowsHitTesting(isHovered)
            .help(field.defaultDescription.map { "Reset to \($0)" } ?? "Reset to default")
        }
    }

    @ViewBuilder
    private var control: some View {
        switch field.kind {
        case .toggle(let binding):
            AinkradToggle(isOn: binding)
        case .select(let options, let selection):
            // Both pickers need `T: Hashable`; `SettingsOption` is only
            // `Identifiable`. The field's binding already holds the selected
            // option's `id` (a `String`), so they operate directly on ids.
            let label = { (id: String) in options.first { $0.id == id }?.title ?? id }
            if Self.usesMenu(optionCount: options.count) {
                AinkradSelect(items: options.map(\.id), selection: selection, label: label)
            } else {
                AinkradSegmentedPicker(items: options.map(\.id), selection: selection, label: label)
                    .fixedSize()
            }
        case .slider(let range, let step, let value):
            // `AinkradSlider` has no native step, so it's wrapped in a
            // shim binding that quantizes writes via `Self.quantize`
            // before they reach the underlying `value` binding.
            AinkradSlider(
                value: Binding(
                    get: { value.wrappedValue },
                    set: { value.wrappedValue = Self.quantize($0, step: step, range: range) }
                ),
                in: range
            )
        case .text(let binding):
            AinkradTextField(text: binding, placeholder: "")
        case .secure(let binding):
            AinkradSecureField(text: binding, placeholder: "")
        case .shortcut(let binding):
            Text(binding.wrappedValue)
                .font(AinkradFontResolver.font(.mono, typography: typo))
                .foregroundStyle(tokens.foreground.opacity(0.8))
        case .action(let title, let handler):
            AinkradButton(title: title, action: handler)
        case .custom(let view):
            view
        }
    }
}
