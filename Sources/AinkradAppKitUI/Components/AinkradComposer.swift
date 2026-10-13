import AinkradAppKitContract
import AppKit
import SwiftUI

/// A chat composer: one seamless elevated surface holding optional chip rows,
/// the growing text area, and a bottom strip of controls ending in Send.
///
/// Typing a leading `/` or a trailing `@token` opens an overlay of
/// `suggestions(trigger)` anchored to the composer; ↑/↓ move the highlight,
/// Return or a click picks a row (the draft is rewritten via
/// `AinkradComposerTrigger.applying(_:to:)`, then `onPick` runs), Esc closes it.
///
/// The caller owns the draft and decides when sending is allowed; the slots
/// carry everything app-specific — attachment/mention chips, the leading
/// controls (agent, mode, model), and trailing utilities before Send.
public struct AinkradComposer<Chips: View, Leading: View, Trailing: View>: View {
    /// The one height every control in the bottom strip is pinned to, Send
    /// included. Slot content should use it too (e.g. `AinkradIconButton(size:)`).
    public static var controlHeight: CGFloat { 30 }

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Binding private var text: String
    private let placeholder: String
    private let isEditable: Bool
    private let canSend: Bool
    private let autoFocus: Bool
    private let suggestions: (AinkradComposerTrigger) -> [AinkradComposerSuggestion]
    private let onPick: (AinkradComposerTrigger, AinkradComposerSuggestion) -> Void
    private let onDrop: (([NSItemProvider]) -> Bool)?
    private let onSend: () -> Void
    private let chips: Chips
    private let leading: Leading
    private let trailing: Trailing

    // Opt-ins set by the modifier methods below (not init params: a defaulted
    // parameter is not ABI-compatible).
    var usesPaletteSuggestionRows = false
    var sendTitle: String?
    var sendGlyph: String?
    var stopTitle: String?
    var onStop: (() -> Void)?
    var dimsTextField = false
    var keepsSendLit = false

    @State private var trigger: AinkradComposerTrigger?
    @State private var isOverlayVisible = false
    @State private var selectedIndex = 0

    /// - Parameters:
    ///   - isEditable: `false` locks the text (e.g. while a turn runs); the
    ///     strip's controls stay live.
    ///   - canSend: enables Send and Return-to-send. The caller decides
    ///     (text present, attachments only, not busy, …).
    ///   - suggestions: rows for the open `/` or `@` overlay, in display order.
    ///     Return none to show the overlay's empty state.
    ///   - onPick: runs after the draft was rewritten for a picked row — e.g.
    ///     record the mentioned file.
    ///   - onDrop: drag-and-drop onto the text area (images, file URLs).
    public init(
        text: Binding<String>,
        placeholder: String,
        isEditable: Bool,
        canSend: Bool,
        autoFocus: Bool,
        suggestions: @escaping (AinkradComposerTrigger) -> [AinkradComposerSuggestion],
        onPick: @escaping (AinkradComposerTrigger, AinkradComposerSuggestion) -> Void,
        onDrop: (([NSItemProvider]) -> Bool)?,
        onSend: @escaping () -> Void,
        @ViewBuilder chips: () -> Chips,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self._text = text
        self.placeholder = placeholder
        self.isEditable = isEditable
        self.canSend = canSend
        self.autoFocus = autoFocus
        self.suggestions = suggestions
        self.onPick = onPick
        self.onDrop = onDrop
        self.onSend = onSend
        self.chips = chips()
        self.leading = leading()
        self.trailing = trailing()
    }

    /// Draws the `/` and `@` overlay's rows as Grimoire's slash panel does:
    /// one flat line each — accent glyph, title, the subtitle pushed to the
    /// row's end in faint mono — only the highlighted row filled. Sections and
    /// the key-hint footer are unchanged (give suggestions a `section`).
    public func paletteSuggestionRows() -> Self {
        var copy = self
        copy.usesPaletteSuggestionRows = true
        return copy
    }

    /// Send as a labelled primary button (`"Ask ⌘↵"`) instead of the round ↑
    /// icon, as Forge's ask-an-agent popover draws it. The label follows the
    /// skin's label case; the shortcut itself stays the caller's.
    public func sendTitle(_ title: String) -> Self {
        var copy = self
        copy.sendTitle = title
        return copy
    }

    /// Send as the round icon button holding a text glyph — `"↵"`, as
    /// Grimoire's busy composer queues the next message (mockup 01) — instead
    /// of the ↑ symbol. `sendTitle(_:)` wins when both are set.
    public func sendGlyph(_ glyph: String) -> Self {
        var copy = self
        copy.sendGlyph = glyph
        return copy
    }

    /// Send drawn at full strength even while `canSend` is `false` — with an
    /// empty draft a click does nothing, but the button does not read as
    /// disabled. For the busy composer's queue button (`sendGlyph("↵")`),
    /// which the mockup draws lit (Grimoire mockup 01).
    public func sendStaysLit() -> Self {
        var copy = self
        copy.keepsSendLit = true
        return copy
    }

    /// A Stop button just before Send while `action` is non-nil — the
    /// mockups' red outline `"■ Stop"` (`AinkradButton(style: .danger)
    /// .outlined()`), e.g. while the agent works. It stays live when sending
    /// is not allowed; pass `nil` to hide it.
    public func stopButton(_ title: String, action: (() -> Void)?) -> Self {
        var copy = self
        copy.stopTitle = title
        copy.onStop = action
        return copy
    }

    /// While `dimmed`, only the text area fades to 60 % — the chips, the
    /// strip and Send stay at full strength — as Grimoire's usage-limit
    /// composer holds its queued message (mockup 12 D, `.composer.off
    /// .field`). Pair with `isEditable: false` to also lock the text.
    public func textFieldDimmed(_ dimmed: Bool) -> Self {
        var copy = self
        copy.dimsTextField = dimmed
        return copy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: skin.spacing.sm) {
            chips

            AinkradTextArea(
                text: $text, placeholder: placeholder,
                minHeight: 34, maxHeight: 80, autoFocus: autoFocus,
                onSubmit: { if canSend { onSend() } }
            )
            .disabled(!isEditable)
            .opacity(dimsTextField ? skin.opacity.o60 : 1)
            .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in onDrop?(providers) ?? false }

            HStack(spacing: skin.spacing.sm) {
                leading
                Spacer(minLength: 8)
                trailing
                if let stopTitle, let onStop {
                    AinkradButton(title: stopTitle, style: .danger, action: onStop).outlined().fixedSize()
                }
                // Lit but not sendable: left enabled so Glass does not grey
                // the glyph; the action checks `canSend` instead.
                sendButton
                    .disabled(!canSend && !keepsSendLit)
                    .opacity(canSend || keepsSendLit ? 1 : skin.opacity.o40)
            }
            .frame(height: Self.controlHeight)
        }
        .padding(.horizontal, skin.spacing.md).padding(.vertical, skin.size.s10)
        .background(skin.shape(cut: AinkradRadius.md).fill(theme.surfaceElevated.opacity(skin.opacity.o45)))
        .background(
            AinkradComposerOverlayKeyMonitor(isActive: { isOverlayVisible }, onKey: handle)
        )
        .ainkradFloatingPanel(isPresented: $isOverlayVisible, maxHeight: 260) {
            if let trigger {
                AinkradComposerOverlayList(
                    trigger: trigger, suggestions: suggestions(trigger),
                    selectedIndex: selectedIndex, usesPaletteRows: usesPaletteSuggestionRows,
                    onSelect: { pick($0, for: trigger) })
            }
        }
        .onChange(of: text) { _, newValue in updateTrigger(newValue) }
    }

    @ViewBuilder private var sendButton: some View {
        if let sendTitle {
            AinkradButton(title: sendTitle, style: .primary) { if canSend { onSend() } }
        } else {
            AinkradIconButton(systemName: "arrow.up", size: Self.controlHeight, tooltip: "Send") {
                if canSend { onSend() }
            }
            .textGlyph(sendGlyph)
        }
    }

    /// Re-derives the overlay from the draft. The highlight resets only when
    /// the overlay opens or switches kind, not while the query narrows.
    private func updateTrigger(_ newValue: String) {
        guard let detected = AinkradComposerTrigger.detect(in: newValue) else {
            isOverlayVisible = false
            trigger = nil
            return
        }
        if !isOverlayVisible || !Self.sameKind(trigger, detected) { selectedIndex = 0 }
        trigger = detected
        isOverlayVisible = true
    }

    private func handle(_ key: AinkradComposerOverlayKey) {
        guard let trigger else { return }
        let rows = suggestions(trigger)
        switch key {
        case .up: selectedIndex = AinkradComposerOverlayKey.moved(selectedIndex, by: -1, count: rows.count)
        case .down: selectedIndex = AinkradComposerOverlayKey.moved(selectedIndex, by: 1, count: rows.count)
        case .confirm:
            guard rows.indices.contains(selectedIndex) else { return }
            pick(rows[selectedIndex], for: trigger)
        }
    }

    private func pick(_ suggestion: AinkradComposerSuggestion, for trigger: AinkradComposerTrigger) {
        text = trigger.applying(suggestion, to: text)
        isOverlayVisible = false
        onPick(trigger, suggestion)
    }

    static func sameKind(_ lhs: AinkradComposerTrigger?, _ rhs: AinkradComposerTrigger) -> Bool {
        switch (lhs, rhs) {
        case (.command, .command), (.mention, .mention): return true
        default: return false
        }
    }
}
