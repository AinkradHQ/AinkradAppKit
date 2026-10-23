import AinkradAppKitContract
import SwiftUI

/// Where a scoped setting's value comes from (decision #52: server → company
/// → project, the most specific wins).
public enum AinkradValueScope: Hashable, Sendable {
    /// Inherited unchanged: "↳ company".
    case inherited(from: String)
    /// Set here: "● project · company 15 min ↺". `inheritedValue` is what the
    /// reset would go back to ("company 15 min").
    case overridden(at: String, inheritedValue: String?)
}

/// One scoped setting (Citadel 14 and 16 limits): the name with its bounds
/// under it, the value as an editable mono field, an optional suffix ("then
/// escalate to PO"), and on the right where the value comes from — inherited
/// in grey, overridden in cyan with ↺ to reset. Click the value (or press
/// Return on it) to edit; Return commits, Esc cancels. A value `validate`
/// refuses is not committed: the field keeps it, outlined red, and the bounds
/// turn red until it is fixed or cancelled. Overriding cross-fades the chip.
public struct AinkradScopedValue: View {
    private let label: String
    private let bounds: String?
    @Binding private var value: String
    private let suffix: String?
    private let scope: AinkradValueScope
    private let validate: (String) -> Bool
    private let onReset: (() -> Void)?
    @State private var isInvalid = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - bounds: the allowed range as the user reads it ("1–120 min").
    ///   - validate: whether an edited value may be committed (inside the bounds).
    ///   - onReset: the ↺ on an overridden value; `nil` hides it.
    public init(
        label: String, bounds: String? = nil, value: Binding<String>, suffix: String? = nil,
        scope: AinkradValueScope, validate: @escaping (String) -> Bool = { _ in true },
        onReset: (() -> Void)? = nil
    ) {
        self.label = label
        self.bounds = bounds
        self._value = value
        self.suffix = suffix
        self.scope = scope
        self.validate = validate
        self.onReset = onReset
    }

    public var body: some View {
        HStack(spacing: skin.size.s10) {
            VStack(alignment: .leading, spacing: skin.size.s1) {
                Text(label)
                    .font(skin.font(AinkradFontToken(sizeKey: "t12")))
                    .foregroundStyle(skin.color(skin.text.muted))
                if let bounds {
                    Text(bounds)
                        .font(skin.font(AinkradFontToken(sizeKey: "t10")))
                        .foregroundStyle(isInvalid ? statusColors.danger : skin.color(skin.text.faint))
                }
            }
            .frame(width: skin.size.s120, alignment: .leading)
            .accessibilityHidden(true)
            HStack(spacing: skin.size.s8) {
                KitInlineValueField(
                    text: $value, accessibilityLabel: label, isInvalid: $isInvalid,
                    validate: validate)
                if let suffix {
                    // Wraps rather than cuts in a narrow row.
                    Text(suffix)
                        .font(skin.font(AinkradFontToken(sizeKey: "t12")))
                        .foregroundStyle(skin.color(skin.text.muted))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            // The value and its suffix are sized first; the scope chip goes compact before they cut.
            .layoutPriority(2)
            Spacer(minLength: skin.size.s8)
            scopeChip
                .layoutPriority(1)
                .transition(.opacity)
                .id(scope)
        }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.present), value: scope)
        .accessibilityElement(children: .contain)
    }

    /// The chip sized to its content, never cut mid-text. When the row is too
    /// narrow for the full chain an overridden chip drops to "● project ↺"
    /// and an inherited one to "↳"; the full chain stays in the tooltip and
    /// in what VoiceOver reads.
    private var scopeChip: some View {
        ViewThatFits(in: .horizontal) {
            chip(compact: false)
            chip(compact: true)
        }
        .help(scopeText)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(scopeAccessibilityLabel)
    }

    private var isOverridden: Bool {
        if case .overridden = scope { return true }
        return false
    }

    /// The full chain: "↳ company", "project · company 15 min".
    private var scopeText: String {
        switch scope {
        case .inherited(let from): "↳ \(from)"
        case .overridden(let at, let inheritedValue): inheritedValue.map { "\(at) · \($0)" } ?? at
        }
    }

    private var scopeAccessibilityLabel: String {
        switch scope {
        case .inherited(let from): "Inherited from \(from)"
        case .overridden: "Overridden here, \(scopeText)"
        }
    }

    private func chip(compact: Bool) -> some View {
        let color = isOverridden ? theme.accentSecondary : skin.color(skin.text.faint)
        let text: String
        switch scope {
        case .inherited: text = compact ? "↳" : scopeText
        case .overridden(let at, _): text = compact ? at : scopeText
        }
        return HStack(spacing: skin.size.s5) {
            if isOverridden {
                Circle().fill(color).frame(width: skin.size.s6, height: skin.size.s6)
            }
            Text(text).lineLimit(1)
            if isOverridden, let onReset {
                KitResetButton(action: onReset, help: resetHelp)
            }
        }
        .font(skin.font(AinkradFontToken(sizeKey: "t10", mono: "family")))
        .foregroundStyle(color)
        .padding(.horizontal, skin.size.s6)
        .padding(.vertical, skin.size.s1)
        .background(
            isOverridden ? color.opacity(skin.opacity.o12) : skin.color(skin.palette.white).opacity(skin.opacity.o05),
            in: skin.usesNativeGlass
                ? AnyShape(Capsule(style: .continuous)) : AnyShape(RoundedRectangle(cornerRadius: skin.size.s4))
        )
        .fixedSize()
    }

    private var resetHelp: String {
        if case .overridden(_, let inheritedValue?) = scope { return "Reset to \(inheritedValue)" }
        return "Reset to the inherited value"
    }
}

/// The ↺ on an overridden scope chip: muted, the foreground on hover.
struct KitResetButton: View {
    let action: () -> Void
    let help: String
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @State private var hovering = false

    var body: some View {
        Button(action: action) {  // design-lint: allow raw-control glyph-only reset inside a chip
            Text("↺").foregroundStyle(hovering ? theme.foreground : skin.color(skin.text.muted))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .help(help)
        .accessibilityLabel(help)
    }
}

/// A value shown as a mono chip that turns into a text field on click — the
/// mockups' `.val`. Hover outlines it in cyan. Return commits when `validate`
/// allows (otherwise it stays open, outlined red), Esc restores the old value.
struct KitInlineValueField: View {
    @Binding var text: String
    let accessibilityLabel: String
    @Binding var isInvalid: Bool
    var validate: (String) -> Bool = { _ in true }
    var minWidth: CGFloat?
    var display: Text?
    var reserve: String?
    var displayColor: Color?
    var fill: Color?
    var horizontalPadding: CGFloat?
    @State private var isEditing = false
    @State private var draft = ""
    @State private var hovering = false
    @FocusState private var focused: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: skin.usesNativeGlass ? skin.size.s6 : skin.size.s4, style: .continuous)
        Group {
            if isEditing {
                ZStack {
                    if let reserve { Text(reserve).hidden() }
                    TextField("", text: $draft)  // design-lint: allow raw-control inline value editor
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(reserve == nil ? .leading : .center)
                        .focused($focused)
                        .fixedSize()
                }
                .frame(minWidth: minWidth ?? skin.size.s24)
                .onSubmit(commit)
                .onKeyPress(.escape) {
                    cancel()
                    return .handled
                }
                .onChange(of: focused) { _, isFocused in
                    if !isFocused, isEditing { commit() }
                }
            } else {
                Button(action: begin) {  // design-lint: allow raw-control the value is its own edit button
                    // `reserve` (the pill's "Edit") holds the width, so a hover never moves the neighbours.
                    ZStack {
                        if let reserve { Text(reserve).hidden() }
                        (display ?? Text(text)).foregroundStyle(displayColor ?? theme.foreground)
                    }
                    .frame(minWidth: minWidth, alignment: .center)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { hovering = $0 }
            }
        }
        .font(skin.font(AinkradFontToken(sizeKey: "t11", mono: "family")))
        .padding(.horizontal, horizontalPadding ?? skin.size.s8)
        .padding(.vertical, skin.size.s2)
        .background(
            shape.fill(
                fill
                    ?? skin.color(skin.palette.black).opacity(
                        skin.usesNativeGlass ? skin.opacity.o22 : skin.opacity.o30))
        )
        .overlay(shape.strokeBorder(rimColor, lineWidth: 1))
        .fixedSize()
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(text)
        .accessibilityHint(isEditing ? "" : "Edit")
    }

    private var rimColor: Color {
        if isInvalid { return statusColors.danger }
        if isEditing || hovering { return theme.accentSecondary.opacity(skin.opacity.o45) }
        // A pill (`fill` given) has no rim at rest; the `.val` chip a 6 % hairline.
        return fill == nil ? skin.color(skin.palette.white).opacity(skin.opacity.o06) : .clear
    }

    private func begin() {
        draft = text
        isEditing = true
        DispatchQueue.main.async { focused = true }
    }

    private func commit() {
        guard validate(draft) else {
            isInvalid = true
            return
        }
        text = draft
        isInvalid = false
        isEditing = false
    }

    private func cancel() {
        isInvalid = false
        isEditing = false
    }
}

/// A story-point estimate as a small mono pill (Quest server backlog 01):
/// the number, or an amber "?" while unestimated — `estimator` says who is
/// estimating on hover. With a binding it is editable: hover shows "Edit",
/// click to type a number (Return commits, Esc cancels, empty clears it).
public struct AinkradPointsPill: View {
    private let points: Binding<Int?>
    private let isEditable: Bool
    private let estimator: String?
    @State private var isInvalid = false
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors

    /// An editable estimate.
    public init(points: Binding<Int?>, estimator: String? = nil) {
        self.points = points
        self.isEditable = true
        self.estimator = estimator
    }

    /// A read-only estimate.
    public init(points: Int?, estimator: String? = nil) {
        self.points = .constant(points)
        self.isEditable = false
        self.estimator = estimator
    }

    private var unestimated: Bool { points.wrappedValue == nil }
    private var label: String { points.wrappedValue.map(String.init) ?? "?" }
    private var tooltip: String {
        if unestimated { return estimator.map { "\($0) is estimating" } ?? "Not estimated" }
        return isEditable ? "Edit the estimate" : "\(label) points"
    }
    private var fill: Color {
        unestimated
            ? statusColors.warning.opacity(skin.opacity.o12) : skin.color(skin.palette.white).opacity(skin.opacity.o07)
    }

    public var body: some View {
        Group {
            if isEditable {
                KitInlineValueField(
                    text: Binding(
                        get: { points.wrappedValue.map(String.init) ?? "" },
                        set: { points.wrappedValue = Int($0) }),
                    accessibilityLabel: "Points", isInvalid: $isInvalid,
                    validate: { $0.isEmpty || (Int($0).map { $0 >= 0 } ?? false) },
                    minWidth: skin.size.s14,
                    display: Text(hovering ? "Edit" : label), reserve: "Edit",
                    displayColor: unestimated && !hovering ? statusColors.warning : theme.foreground,
                    fill: fill, horizontalPadding: skin.size.s4
                )
                .onHover { hovering = $0 }
            } else {
                Text(label)
                    .font(skin.font(AinkradFontToken(sizeKey: "t11", mono: "family")))
                    .foregroundStyle(unestimated ? statusColors.warning : theme.foreground)
                    .frame(minWidth: skin.size.s14)
                    .padding(.horizontal, skin.size.s8)
                    .padding(.vertical, skin.size.s2)
                    .background(RoundedRectangle(cornerRadius: skin.size.s4, style: .continuous).fill(fill))
                    .accessibilityElement()
                    .accessibilityLabel("Points")
            }
        }
        .fixedSize()
        .help(tooltip)
        .accessibilityValue(unestimated ? "Not estimated" : label)
    }
}
