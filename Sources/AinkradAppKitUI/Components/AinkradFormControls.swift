import SwiftUI
import AppKit
import AinkradAppKitContract

/// Cardinal HUD switch — chamfered track (never a native `Toggle`), a
/// luminous thumb, and an accent glow that brightens while on.
public struct AinkradToggle: View {
    @Binding private var isOn: Bool
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>) { self._isOn = isOn }

    public var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                ChamferShape(cut: 6, corners: .all)
                    .fill(isOn ? theme.accentPrimary.opacity(0.9) : theme.surfaceElevated.opacity(0.6))
                ChamferShape(cut: 6, corners: .all)
                    .strokeBorder(isOn ? theme.accentSecondary.opacity(0.75) : theme.foreground.opacity(hovering ? 0.35 : 0.18), lineWidth: 1.25)
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

/// Masked entry with a reveal (eye) toggle — chamfer field + luminous focus
/// ring, no separator lines. Ported from the host's `NeonSecureField`; never
/// logs or otherwise surfaces the value beyond this field.
public struct AinkradSecureField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) {
        self._text = text; self.placeholder = placeholder
    }
    public var body: some View {
        HStack(spacing: AinkradSpacing.sm) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(AinkradFontResolver.font(.mono, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)

            Button { isRevealed.toggle() } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.foreground.opacity(0.55))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25))
        .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
        .animation(AinkradMotion.hover, value: isFocused)
    }
}

/// Plain-text entry mirroring `AinkradSecureField`'s chamfer chrome, minus the
/// reveal toggle and mono font.
public struct AinkradTextField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) {
        self._text = text; self.placeholder = placeholder
    }
    public var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25))
            .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
            .animation(AinkradMotion.hover, value: isFocused)
    }
}

/// Chamfer field with a leading magnifier glyph and a custom clear (✕)
/// affordance — never a native search field.
public struct AinkradSearchField: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSubmit: (() -> Void)?
    /// Lets a caller drive focus from outside (e.g. a ⌘F shortcut owned by a
    /// parent view). `nil` (the default) keeps the field's own internal
    /// `@FocusState` — every existing call site is unaffected.
    private let externalFocus: FocusState<Bool>.Binding?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var internalFocus: Bool

    public init(text: Binding<String>, placeholder: String, onSubmit: (() -> Void)? = nil, focus: FocusState<Bool>.Binding? = nil) {
        self._text = text; self.placeholder = placeholder; self.onSubmit = onSubmit; self.externalFocus = focus
    }

    private var isFocused: Bool { externalFocus?.wrappedValue ?? internalFocus }

    public var body: some View {
        HStack(spacing: AinkradSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.accentSecondary.opacity(isFocused ? 0.95 : 0.55))

            textField

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.foreground.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25))
        .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
        .animation(AinkradMotion.hover, value: isFocused)
    }

    @ViewBuilder
    private var textField: some View {
        let base = TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .onSubmit { onSubmit?() }

        if let externalFocus {
            base.focused(externalFocus)
        } else {
            base.focused($internalFocus)
        }
    }
}

/// Multiline chamfer field — same focus-ring/HUD chrome as the single-line
/// fields, backed by a native `TextEditor` for text-editing behavior (not a
/// styled selection control, so it isn't covered by the zero-native-controls
/// rule) with its default chrome stripped.
public struct AinkradTextArea: View {
    @Binding private var text: String
    private let placeholder: String
    private let autoFocus: Bool
    /// Editor's minimum height. Stored at the END with the historical default
    /// (80) so both existing inits keep their exact behavior.
    private let minHeight: CGFloat
    /// When non-nil, the editor AUTO-GROWS with its content from `minHeight` up
    /// to this cap, then scrolls (one-row-and-expandable composer behavior).
    /// When nil, the editor keeps the legacy greedy fill (`.frame(minHeight:)`),
    /// so every existing call site is byte-for-byte unchanged visually.
    private let maxHeight: CGFloat?
    /// When set, plain Return SUBMITS (calls this) instead of inserting a
    /// newline; Option+Return still inserts a newline. Auto-grow composers only.
    private let onSubmit: (() -> Void)?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool
    /// Measured content height (auto-grow mode only), reported by the AppKit
    /// text view's layout manager — deterministic, unlike SwiftUI's own
    /// measurement of `TextEditor`, which never reported a growing height here.
    @State private var contentHeight: CGFloat = 0
    /// Editing state of the AppKit-backed auto-grow view, driving the focus ring
    /// (the SwiftUI `@FocusState` doesn't track an `NSViewRepresentable`).
    @State private var nsFocused = false

    /// Two EXPLICIT overloads (no defaulted param) so both mangled symbols
    /// exist: `init(text:placeholder:)` re-mints the exact symbol pre-d38b2a8
    /// plugins (e.g. Leyline) linked against — repairing the `dlopen` break the
    /// earlier defaulted-param change caused — while `autoFocus:` callers
    /// resolve to the 3-arg init. Swift prefers the non-defaulted 2-arg overload
    /// on exact 2-arg calls, so there is no ambiguity. NEVER collapse these back
    /// into one defaulted-param init (that changes/drops the 2-arg symbol → ABI
    /// break). See ainkrad-hostthemetokens-abi memory.
    public init(text: Binding<String>, placeholder: String) {
        self._text = text; self.placeholder = placeholder; self.autoFocus = false
        self.minHeight = 80; self.maxHeight = nil; self.onSubmit = nil
    }

    /// `autoFocus` focuses the editor the first time it appears — for overlays
    /// (e.g. a summoned Quick-Ask) that should accept typing immediately.
    public init(text: Binding<String>, placeholder: String, autoFocus: Bool) {
        self._text = text; self.placeholder = placeholder; self.autoFocus = autoFocus
        self.minHeight = 80; self.maxHeight = nil; self.onSubmit = nil
    }

    /// Shorter/taller composer variant — `minHeight` replaces the hardcoded 80.
    /// Distinct symbol from the two inits above (different third label), and the
    /// non-defaulted `minHeight` keeps a bare 2-arg call resolving to
    /// `init(text:placeholder:)`, so no ambiguity. For GitMage's compact
    /// comment composers.
    public init(text: Binding<String>, placeholder: String, minHeight: CGFloat) {
        self._text = text; self.placeholder = placeholder; self.autoFocus = false
        self.minHeight = minHeight; self.maxHeight = nil; self.onSubmit = nil
    }

    /// Auto-growing composer — starts at `minHeight` (one row), grows with the
    /// typed content up to `maxHeight`, then scrolls. `autoFocus` focuses on
    /// appear; `onSubmit`, when provided, makes plain Return SUBMIT (and
    /// Option+Return insert a newline). NEW symbol (carries `maxHeight:`); the
    /// inits above are untouched. `autoFocus`/`onSubmit` default so a bare
    /// `…minHeight:maxHeight:` call keeps resolving here unambiguously.
    public init(text: Binding<String>, placeholder: String, minHeight: CGFloat, maxHeight: CGFloat,
                autoFocus: Bool = false, onSubmit: (() -> Void)? = nil) {
        self._text = text; self.placeholder = placeholder; self.autoFocus = autoFocus
        self.minHeight = minHeight; self.maxHeight = maxHeight; self.onSubmit = onSubmit
    }

    /// Whether the focus ring should read as active — the AppKit editing flag in
    /// auto-grow mode, the SwiftUI focus state otherwise.
    private var focusRingActive: Bool { maxHeight == nil ? isFocused : nsFocused }

    public var body: some View {
        editorSurface
            .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(ChamferShape(cut: 8).strokeBorder(theme.accentPrimary.opacity(focusRingActive ? 0.9 : 0.25), lineWidth: focusRingActive ? 1.5 : 1.25))
            .shadow(color: theme.accentSecondary.opacity(focusRingActive ? 0.4 : 0), radius: focusRingActive ? 6 : 0)
            .animation(AinkradMotion.hover, value: focusRingActive)
            .onAppear {
                // Legacy (TextEditor) autofocus; the AppKit path autofocuses
                // itself via `AutoGrowingTextView.autoFocus`.
                guard autoFocus, maxHeight == nil else { return }
                DispatchQueue.main.async { isFocused = true }
            }
    }

    @ViewBuilder private var editorSurface: some View {
        if let maxHeight {
            // Auto-grow via an AppKit-backed NSTextView that reports its true
            // content height (SwiftUI's own TextEditor measurement never grew
            // here). One row when empty, grows line by line, then scrolls once
            // the content passes the cap.
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    // Placeholder insets match the NSTextView's text origin
                    // (textContainerInset + line-fragment padding) so it sits
                    // exactly where typed text will. `allowsHitTesting(false)`
                    // lets clicks fall through to the editor.
                    Text(placeholder)
                        .font(AinkradFontResolver.font(.body, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.4))
                        .padding(.horizontal, AinkradSpacing.md + 5)
                        .padding(.vertical, AinkradSpacing.sm)
                        .allowsHitTesting(false)
                }
                AutoGrowingTextView(
                    text: $text,
                    font: nsBodyFont,
                    textColor: NSColor(theme.foreground),
                    tintColor: NSColor(theme.accentSecondary),
                    inset: CGSize(width: AinkradSpacing.md, height: AinkradSpacing.sm),
                    autoFocus: autoFocus,
                    onSubmit: onSubmit,
                    onHeightChange: { h in
                        let clamped = min(max(h, minHeight), maxHeight)
                        if abs(clamped - contentHeight) > 0.5 { contentHeight = clamped }
                    },
                    onFocusChange: { nsFocused = $0 }
                )
            }
            // Frame the STACK (not just the editor) so the placeholder — a
            // taller sibling — can't stretch the empty height past one row.
            .frame(height: min(max(contentHeight, minHeight), maxHeight))
        } else {
            ZStack(alignment: .topLeading) {
                if text.isEmpty { placeholderText }
                editor
            }
            .frame(minHeight: minHeight)
        }
    }

    private var nsBodyFont: NSFont {
        let size = AinkradFontResolver.pointSize(.body, typography: typo)
        if let family = typo.fontFamilyName, let f = NSFont(name: family, size: size) { return f }
        return NSFont.systemFont(ofSize: size)
    }

    private var placeholderText: some View {
        Text(placeholder)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground.opacity(0.4))
            .padding(.horizontal, AinkradSpacing.md + 4)
            .padding(.vertical, AinkradSpacing.sm + 4)
            .allowsHitTesting(false)
    }

    private var editor: some View {
        TextEditor(text: $text)
            .focused($isFocused)
            .scrollContentBackground(.hidden)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            // Plain Return submits; Option+Return falls through to the editor to
            // insert a newline. Only active when a caller supplied `onSubmit` —
            // otherwise Return keeps its default newline behavior everywhere.
            .onKeyPress(keys: [.return], phases: .down) { press in
                guard let onSubmit, !press.modifiers.contains(.option) else { return .ignored }
                onSubmit()
                return .handled
            }
    }
}

/// AppKit-backed auto-growing editor for `AinkradTextArea`'s composer mode.
/// An `NSTextView` (in a scroll view) whose layout manager reports the true
/// content height back to SwiftUI, so the field grows to fit and only scrolls
/// once it's capped. Plain Return submits (`onSubmit`); Option+Return inserts a
/// newline (it arrives as `insertNewlineIgnoringFieldEditor:` and falls
/// through). SwiftUI's own `TextEditor` measurement never reported growth here,
/// hence the AppKit route.
private struct AutoGrowingTextView: NSViewRepresentable {
    @Binding var text: String
    let font: NSFont
    let textColor: NSColor
    let tintColor: NSColor
    let inset: CGSize
    let autoFocus: Bool
    let onSubmit: (() -> Void)?
    let onHeightChange: (CGFloat) -> Void
    let onFocusChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = false
        scroll.autohidesScrollers = true
        guard let tv = scroll.documentView as? NSTextView else { return scroll }
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.isAutomaticTextCompletionEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        if #available(macOS 14.0, *) { tv.inlinePredictionType = .no }
        tv.drawsBackground = false
        tv.font = font
        tv.textColor = textColor
        tv.insertionPointColor = tintColor
        tv.textContainerInset = inset
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.textContainer?.widthTracksTextView = true
        tv.string = text
        if autoFocus {
            DispatchQueue.main.async { tv.window?.makeFirstResponder(tv) }
        }
        DispatchQueue.main.async { context.coordinator.recomputeHeight(tv) }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let tv = scroll.documentView as? NSTextView else { return }
        if tv.string != text { tv.string = text }
        if tv.font != font { tv.font = font }
        tv.textColor = textColor
        tv.insertionPointColor = tintColor
        DispatchQueue.main.async { context.coordinator.recomputeHeight(tv) }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AutoGrowingTextView
        init(_ parent: AutoGrowingTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
            recomputeHeight(tv)
        }

        func textDidBeginEditing(_ notification: Notification) { parent.onFocusChange(true) }
        func textDidEndEditing(_ notification: Notification) { parent.onFocusChange(false) }

        func textView(_ tv: NSTextView, doCommandBy sel: Selector) -> Bool {
            // Plain Return → submit (consume). Option+Return arrives as
            // `insertNewlineIgnoringFieldEditor:` and is left to the text view.
            if sel == #selector(NSResponder.insertNewline(_:)), let onSubmit = parent.onSubmit {
                onSubmit()
                return true
            }
            return false
        }

        func recomputeHeight(_ tv: NSTextView) {
            guard let lm = tv.layoutManager, let tc = tv.textContainer else { return }
            lm.ensureLayout(for: tc)
            // An empty text view's used rect is slightly taller than a single
            // line of real text; pin the empty case to exactly one line height
            // so empty and one-row-filled match.
            let used: CGFloat
            if tv.string.isEmpty, let font = tv.font {
                used = lm.defaultLineHeight(for: font)
            } else {
                used = lm.usedRect(for: tc).height
            }
            parent.onHeightChange(used + tv.textContainerInset.height * 2)
        }
    }
}

/// Custom single-thumb HUD slider — chamfer-adjacent track + a glowing thumb
/// (never a native `Slider`).
public struct AinkradSlider: View {
    @Binding private var value: Double
    private let bounds: ClosedRange<Double>
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var dragging = false

    public init(value: Binding<Double>, in bounds: ClosedRange<Double>) {
        self._value = value; self.bounds = bounds
    }

    private var span: Double { max(bounds.upperBound - bounds.lowerBound, .leastNonzeroMagnitude) }
    private func fraction(_ value: Double) -> CGFloat { CGFloat((value - bounds.lowerBound) / span) }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let x = fraction(value) * width

            ZStack(alignment: .leading) {
                Capsule().fill(theme.surfaceElevated.opacity(0.6)).frame(height: 4)
                Capsule().fill(theme.accentSecondary.opacity(0.85)).frame(width: max(x, 0), height: 4)
                Circle()
                    .fill(theme.accentSecondary)
                    .frame(width: 14, height: 14)
                    .shadow(color: theme.accentSecondary.opacity(dragging ? 0.9 : 0.55), radius: dragging ? 8 : 4)
                    .scaleEffect(dragging && !reduceMotion ? 1.15 : 1.0)
                    .offset(x: x - 7)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        dragging = true
                        let clampedFraction = min(max(drag.location.x / max(width, 1), 0), 1)
                        value = bounds.lowerBound + Double(clampedFraction) * span
                    }
                    .onEnded { _ in dragging = false }
            )
        }
        .frame(height: 20)
        .animation(AinkradMotion.hover, value: dragging)
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.xs)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.3)))
        .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentPrimary.opacity(0.2), lineWidth: 1))
        // The control was a bare `DragGesture` with no accessibility of any
        // kind: no value, no action, and a drag is a pointer gesture. It was
        // therefore not merely unlabelled but INOPERABLE without a mouse —
        // the notification volume could not be changed at all.
        .accessibilityElement()
        .accessibilityValue(Self.spokenValue(value, in: bounds))
        .accessibilityAdjustableAction { direction in
            // Twentieths, so a full sweep is twenty presses rather than a
            // hundred, and each press moves audibly.
            let stepSize = span / 20
            switch direction {
            case .increment: value = min(value + stepSize, bounds.upperBound)
            case .decrement: value = max(value - stepSize, bounds.lowerBound)
            @unknown default: break
            }
        }
    }

    /// Spoken as a percentage of the range. Pure, so the wording is testable
    /// without rendering — a slider that announces "0.62" tells the listener
    /// nothing about how far along it is.
    static func spokenValue(_ value: Double, in bounds: ClosedRange<Double>) -> String {
        let span = max(bounds.upperBound - bounds.lowerBound, .leastNonzeroMagnitude)
        let fraction = (value - bounds.lowerBound) / span
        return "\(Int((min(max(fraction, 0), 1) * 100).rounded()))%"
    }
}

public struct AinkradFormRow<Control: View>: View {
    public let title: String
    public let help: String?
    /// Short uppercase tags rendered beside the title — e.g. ADVANCED,
    /// RESTART REQUIRED. Empty by default so existing call sites are unchanged.
    public let badges: [String]
    /// Fixed width for the control, so every control in a form shares one
    /// vertical rail. `nil` keeps the previous behaviour: the control sizes
    /// itself and right-aligns after a Spacer.
    public let controlWidth: CGFloat?
    private let control: Control
    private let accessory: AnyView?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    public init(
        title: String,
        help: String? = nil,
        badges: [String] = [],
        controlWidth: CGFloat? = nil,
        accessory: (() -> AnyView)? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.title = title
        self.help = help
        self.badges = badges
        self.controlWidth = controlWidth
        self.accessory = accessory?()
        self.control = control()
    }

    public var body: some View {
        // `.center`, not `.firstTextBaseline`: with a two-line label (title +
        // help) baseline alignment pins the control to the title's line,
        // floating it at the top of the row instead of the middle of the
        // label block. `.center` centres the control against the whole
        // label block regardless of how many lines it has, and degrades to
        // the same visual result as baseline alignment for a single-line
        // label (title only) since there's only one line to center against.
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
                HStack(spacing: AinkradSpacing.xs) {
                    Rectangle()
                        .fill(theme.accentSecondary.opacity(0.55))
                        .frame(width: 2, height: 12)
                    Text(title)
                        .font(AinkradFontResolver.font(.body, typography: typo))
                        .foregroundStyle(theme.foreground)
                    ForEach(badges, id: \.self) { badge in
                        AinkradBadge(text: badge, tint: theme.accentSecondary)
                    }
                    if let accessory { accessory }
                }
                if let help {
                    Text(help)
                        .font(AinkradFontResolver.font(.caption, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.55))
                        .padding(.leading, AinkradSpacing.xs + 2)
                }
            }
            Spacer(minLength: AinkradSpacing.lg)
            if let controlWidth {
                control.frame(width: controlWidth, alignment: .trailing)
            } else {
                control
            }
        }
    }
}
