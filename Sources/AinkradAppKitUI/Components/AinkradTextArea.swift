import AinkradAppKitContract
import AppKit
import SwiftUI

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
        self._text = text
        self.placeholder = placeholder
        self.autoFocus = false
        self.minHeight = 80
        self.maxHeight = nil
        self.onSubmit = nil
    }

    /// `autoFocus` focuses the editor the first time it appears — for overlays
    /// (e.g. a summoned Quick-Ask) that should accept typing immediately.
    public init(text: Binding<String>, placeholder: String, autoFocus: Bool) {
        self._text = text
        self.placeholder = placeholder
        self.autoFocus = autoFocus
        self.minHeight = 80
        self.maxHeight = nil
        self.onSubmit = nil
    }

    /// Shorter/taller composer variant — `minHeight` replaces the hardcoded 80.
    /// Distinct symbol from the two inits above (different third label), and the
    /// non-defaulted `minHeight` keeps a bare 2-arg call resolving to
    /// `init(text:placeholder:)`, so no ambiguity. For GitMage's compact
    /// comment composers.
    public init(text: Binding<String>, placeholder: String, minHeight: CGFloat) {
        self._text = text
        self.placeholder = placeholder
        self.autoFocus = false
        self.minHeight = minHeight
        self.maxHeight = nil
        self.onSubmit = nil
    }

    /// Auto-growing composer — starts at `minHeight` (one row), grows with the
    /// typed content up to `maxHeight`, then scrolls. `autoFocus` focuses on
    /// appear; `onSubmit`, when provided, makes plain Return SUBMIT (and
    /// Option+Return insert a newline). NEW symbol (carries `maxHeight:`); the
    /// inits above are untouched. `autoFocus`/`onSubmit` default so a bare
    /// `…minHeight:maxHeight:` call keeps resolving here unambiguously.
    public init(
        text: Binding<String>, placeholder: String, minHeight: CGFloat, maxHeight: CGFloat,
        autoFocus: Bool = false, onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.autoFocus = autoFocus
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.onSubmit = onSubmit
    }

    /// Whether the focus ring should read as active — the AppKit editing flag in
    /// auto-grow mode, the SwiftUI focus state otherwise.
    private var focusRingActive: Bool { maxHeight == nil ? isFocused : nsFocused }

    public var body: some View {
        editorSurface
            .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(
                ChamferShape(cut: 8).strokeBorder(
                    theme.accentPrimary.opacity(focusRingActive ? 0.9 : 0.25), lineWidth: focusRingActive ? 1.5 : 1.25)
            )
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
