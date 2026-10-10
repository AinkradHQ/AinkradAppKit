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

    public var body: some View {
        VStack(alignment: .leading, spacing: skin.spacing.sm) {
            chips

            AinkradTextArea(
                text: $text, placeholder: placeholder,
                minHeight: 34, maxHeight: 80, autoFocus: autoFocus,
                onSubmit: { if canSend { onSend() } }
            )
            .disabled(!isEditable)
            .onDrop(of: [.image, .fileURL], isTargeted: nil) { providers in onDrop?(providers) ?? false }

            HStack(spacing: skin.spacing.sm) {
                leading
                Spacer(minLength: 8)
                trailing
                AinkradIconButton(systemName: "arrow.up", size: Self.controlHeight, tooltip: "Send") { onSend() }
                    .disabled(!canSend)
                    .opacity(canSend ? 1 : skin.opacity.o40)
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
                    selectedIndex: selectedIndex, onSelect: { pick($0, for: trigger) })
            }
        }
        .onChange(of: text) { _, newValue in updateTrigger(newValue) }
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
