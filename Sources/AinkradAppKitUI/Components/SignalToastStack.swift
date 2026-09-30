import SwiftUI
import AinkradAppKitContract
import AinkradSignal

@MainActor
@Observable
/// Deliberately conforms to nothing: `ToastPresenting` is the HOST's delivery
/// seam, and the kit must not know it exists. The host adds the conformance
/// retroactively — `present(_:)` already matches — so a plugin gets the same
/// model without inheriting the host's dispatch protocol.
public final class SignalToastModel {
    public init() {}

    public static let maxVisible = 3

    public private(set) var visible: [SignalEvent] = []
    private var queued: [SignalEvent] = []
    public var overflowCount: Int { queued.count }

    /// How long a toast stays. A failure stays longest but no longer forever:
    /// three failures that never left filled every slot and hid everything
    /// after them. The feed keeps each one after its toast goes. Optional, so
    /// a future "until dismissed" severity stays expressible.
    public static func autoDismissDelay(for severity: SignalSeverity) -> TimeInterval? {
        switch severity {
        case .info, .success: return 4
        case .warning: return 8
        case .failure: return 30
        @unknown default: return 4
        }
    }

    /// The delay for this event: `.urgent` importance (a person waiting on
    /// you) gets at least 8s, since 4s is too short to read a message.
    static func autoDismissDelay(for event: SignalEvent) -> TimeInterval? {
        guard let base = autoDismissDelay(for: event.severity) else { return nil }
        return event.proposedImportance == .urgent ? max(base, 8) : base
    }

    /// How many times the toast with this id has been repeated in place (1 when
    /// it has not). See `present(_:)`.
    public func repeatCount(for id: UUID) -> Int { repeats[id] ?? 1 }
    private var repeats: [UUID: Int] = [:]

    /// Severity order, so a more urgent arrival can take a slot from a less
    /// urgent toast. Not `CaseIterable`'s order: that is a declaration detail
    /// and must not silently become behaviour.
    private static func rank(_ severity: SignalSeverity) -> Int {
        switch severity {
        case .info: return 0
        case .success: return 1
        case .warning: return 2
        case .failure: return 3
        @unknown default: return 0
        }
    }

    /// Past the cap, an arrival queues UNLESS it is strictly more severe than
    /// the least-severe toast on screen, in which case it takes that slot and
    /// the displaced toast goes back to the front of the queue.
    ///
    /// Plain FIFO queueing was the first cut and looked wrong the moment it was
    /// rendered: three chatty `.info` toasts filled the stack and a real
    /// failure sat behind "+2 more" — the feed's most important event hidden
    /// behind its least. Strictness matters in both directions: because the
    /// comparison is `>` and not `>=`, a `.failure` can never be displaced by
    /// another failure, so the toast that never auto-dismisses is never the one
    /// that silently disappears.
    ///
    /// A repeat (same source and `dedupeKey` as a toast still showing or
    /// queued) replaces that toast IN PLACE, keeps its slot, restarts its
    /// clock and counts itself: a burst from one chat is one toast reading
    /// "×3" with the newest text, not three toasts pushing everything else out.
    public func present(_ event: SignalEvent) {
        guard !visible.contains(where: { $0.id == event.id }),
              !queued.contains(where: { $0.id == event.id }) else { return }

        if let key = event.dedupeKey {
            let isRepeat: (SignalEvent) -> Bool = { $0.dedupeKey == key && $0.source == event.source }
            if let index = visible.firstIndex(where: isRepeat) {
                let old = visible[index]
                repeats[event.id] = repeatCount(for: old.id) + 1
                repeats[old.id] = nil
                deadlines[old.id] = nil
                heldRemaining[old.id] = nil
                visible[index] = event
                scheduleAutoDismiss(event)
                return
            }
            if let index = queued.firstIndex(where: isRepeat) {
                repeats[event.id] = repeatCount(for: queued[index].id) + 1
                repeats[queued[index].id] = nil
                queued[index] = event
                return
            }
        }

        if visible.count < Self.maxVisible {
            visible.insert(event, at: 0)
            scheduleAutoDismiss(event)
            return
        }

        let arriving = Self.rank(event.severity)
        if let weakest = visible.enumerated().min(by: {
            Self.rank($0.element.severity) < Self.rank($1.element.severity)
        }), Self.rank(weakest.element.severity) < arriving {
            let displaced = visible.remove(at: weakest.offset)
            queued.insert(displaced, at: 0)
            visible.insert(event, at: 0)
            scheduleAutoDismiss(event)
        } else {
            queued.insert(event, at: 0)
        }
    }

    public func dismiss(id: UUID) {
        visible.removeAll { $0.id == id }
        deadlines[id] = nil
        heldRemaining[id] = nil
        repeats[id] = nil
        // Promote the NEWEST queued event, and to the top - the same ordering
        // the visible stack already uses, so a promotion does not shuffle the
        // stack into a different order than arrivals produce.
        if !queued.isEmpty {
            let next = queued.removeFirst()
            visible.insert(next, at: 0)
            scheduleAutoDismiss(next)
        }
    }

    // MARK: - dwell

    /// When each visible toast is due to go. Absent means it never
    /// auto-dismisses — a failure, which must be dismissed deliberately.
    public private(set) var deadlines: [UUID: Date] = [:]
    /// Time left on a paused toast, held while the pointer is over it.
    private var heldRemaining: [UUID: TimeInterval] = [:]

    /// Stops the clock while the pointer is over a toast.
    ///
    /// An eight-second warning can expire while it is being read, which is the
    /// one moment the user is definitely paying attention to it. Pausing on
    /// hover is the cheapest fix for the most annoying failure a toast has.
    public func pause(id: UUID, now: Date = Date()) {
        guard let deadline = deadlines[id] else { return }
        heldRemaining[id] = max(0, deadline.timeIntervalSince(now))
        deadlines[id] = nil
    }

    public func resume(id: UUID, now: Date = Date()) {
        guard let remaining = heldRemaining.removeValue(forKey: id),
              visible.contains(where: { $0.id == id }) else { return }
        deadlines[id] = now.addingTimeInterval(remaining)
        scheduleSweep()
    }

    /// How much of its life a toast has left, 0...1. Drives the hairline, and
    /// is a pure function so the bar can be tested without waiting.
    public func remainingFraction(id: UUID, severity: SignalSeverity,
                                  now: Date = Date()) -> Double? {
        let event = visible.first { $0.id == id }
        guard let total = event.map(Self.autoDismissDelay(for:)) ?? Self.autoDismissDelay(for: severity) else { return nil }
        if let held = heldRemaining[id] { return min(1, max(0, held / total)) }
        guard let deadline = deadlines[id] else { return nil }
        return min(1, max(0, deadline.timeIntervalSince(now) / total))
    }

    private func scheduleAutoDismiss(_ event: SignalEvent) {
        guard let delay = Self.autoDismissDelay(for: event) else { return }
        deadlines[event.id] = Date().addingTimeInterval(delay)
        scheduleSweep()
    }

    /// One sweep for all toasts rather than a task per toast: pausing has to
    /// be able to move a deadline, and a sleeping task holding its own delay
    /// cannot be told about that without cancelling it.
    private func scheduleSweep() {
        guard !isSweeping else { return }
        isSweeping = true
        Task { [weak self] in
            while let self, !self.deadlines.isEmpty || !self.heldRemaining.isEmpty {
                try? await Task.sleep(for: .milliseconds(100))
                let now = Date()
                for (id, deadline) in self.deadlines where deadline <= now {
                    self.dismiss(id: id)
                }
            }
            self?.isSweeping = false
        }
    }

    private var isSweeping = false
}

/// A stack of transient toasts; the host places it top-trailing, under the bell.
///
/// Each toast is its own layer with its own transition, so the stack settles as
/// separated live layers rather than one image sliding — the host's motion rule.
public struct SignalToastStack: View {
    public let model: SignalToastModel
    public var now: Date = Date()
    public var onActivate: (SignalEvent) -> Void = { _ in }
    /// Runs an action the user chose from the toast itself.
    public var onAction: (SignalEvent, SignalAction) -> Void = { _, _ in }

    /// Explicit, because a public struct's implicit memberwise
    /// initialiser is INTERNAL — the components were public and
    /// unconstructible outside the module until this existed.
    public init(model: SignalToastModel,
                now: Date = Date(),
                onActivate: @escaping (SignalEvent) -> Void = { _ in }) {
        self.model = model
        self.now = now
        self.onActivate = onActivate
    }

    /// Separate, not a defaulted parameter — library evolution, same reason as
    /// `SignalFeedRow`'s.
    public init(model: SignalToastModel,
                now: Date,
                onActivate: @escaping (SignalEvent) -> Void,
                onAction: @escaping (SignalEvent, SignalAction) -> Void) {
        self.model = model
        self.now = now
        self.onActivate = onActivate
        self.onAction = onAction
    }

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var status
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @Environment(\.ainkradSignalIdentity) private var identities
    @State private var hovered: UUID?
    /// Toasts showing their whole body. An expanded toast holds its clock:
    /// the user asked to read it, so it must not leave mid-sentence.
    @State private var expanded: Set<UUID> = []
    /// Toasts whose body does not fit on one line, measured, not guessed from
    /// a character count, so the chevron appears exactly when text is cut.
    @State private var overflowing: Set<UUID> = []

    public var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(model.visible) { event in
                toast(event)
                    .transition(reduceMotion
                        ? .opacity
                        : .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            // Shrinking away toward the corner the bell lives
                            // in: the dismissal is where the user learns that
                            // notifications go somewhere rather than vanish.
                            removal: .opacity.combined(with: .scale(scale: 0.7))
                                .combined(with: .offset(x: 40, y: -60))))
            }
            // Below the stack, not above it: the chip counts what is WAITING,
            // so it belongs after the toasts it is queued behind. Above them it
            // read as a badge hanging off whatever sits over the stack.
            if model.overflowCount > 0 {
                AinkradBadge(text: "+\(model.overflowCount) more",
                             tint: theme.accentSecondary)
                    .transition(.opacity)
            }
        }
        .padding(16)
        .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.82),
                   value: model.visible.map(\.id))
        .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.82),
                   value: model.overflowCount)
    }

    /// A thin remaining-time hairline. Only while hovered — a countdown on
    /// every toast would be a row of progress bars competing with the words.
    @ViewBuilder
    private func dwellBar(_ event: SignalEvent) -> some View {
        if hovered == event.id,
           let fraction = model.remainingFraction(id: event.id, severity: event.severity,
                                                  now: now) {
            GeometryReader { geo in
                Rectangle()
                    .fill(SignalPresentation.color(for: event.severity, in: status)
                        .opacity(0.7))
                    .frame(width: geo.size.width * fraction, height: 1.5)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 1.5)
            .allowsHitTesting(false)
        }
    }

    /// Built from the same primitives `SignalFeedRow`'s inline action uses, so
    /// the two read as one control in two places rather than two controls.
    private func toastAction(_ event: SignalEvent, _ action: SignalAction) -> some View {
        let tint = action.isDestructive ? status.danger : theme.accentPrimary
        return Button { onAction(event, action) } label: {
            Text(action.label)
                .font(AinkradFontResolver.font(size: 10.5, weight: .medium, typography: typo))
                .foregroundStyle(tint)
                .padding(.horizontal, AinkradSpacing.sm)
                .padding(.vertical, AinkradSpacing.xs / 2)
                .background(ChamferShape(cut: 4).fill(tint.opacity(0.14)))
                .overlay(ChamferShape(cut: 4).strokeBorder(tint.opacity(0.5), lineWidth: 1))
                .contentShape(ChamferShape(cut: 4))
        }
        .buttonStyle(.plain)
    }

    /// The severity colour, from the same mapping feed rows use, so an info
    /// event reads the same in a toast and in the dropdown.
    private func accent(_ event: SignalEvent) -> Color {
        SignalPresentation.status(for: event.severity).color(in: theme, statusColors: status)
    }

    /// The sending app's launcher icon, large, as the toast's anchor. Without
    /// a resolver (a plugin hosting the stack itself) it falls back to the
    /// severity glyph.
    @ViewBuilder
    private func leadingIcon(_ event: SignalEvent) -> some View {
        if let identity = identities.identity(for: event.source) {
            AinkradAppTile(symbol: identity.symbol, size: 34)
                .allowsHitTesting(false)
                .accessibilityLabel(identity.name)
        } else {
            Image(systemName: SignalPresentation.iconSymbol(for: event.severity))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(accent(event))
                .frame(width: 34, height: 34)
        }
    }

    private func bodyText(_ event: SignalEvent) -> Text {
        Text(event.body.flatMap { $0.isEmpty ? nil : $0 } ?? " ")
            .font(AinkradFontResolver.font(size: 11.5, typography: typo))
            .foregroundStyle(theme.foreground.opacity(0.66))
    }

    private func toggleExpanded(_ event: SignalEvent) {
        if expanded.contains(event.id) {
            collapse(event.id)
            if hovered != event.id { model.resume(id: event.id) }
        } else {
            expanded.insert(event.id)
            model.pause(id: event.id)
        }
    }

    private func collapse(_ id: UUID) {
        expanded.remove(id)
        overflowing.remove(id)
    }

    /// Two on the toast and the rest behind "⋯": the same set the feed row
    /// offers, so one event never offers different things in two places.
    @ViewBuilder
    private func actionRow(_ event: SignalEvent) -> some View {
        let more = Array(event.actions.dropFirst(2))
        HStack(spacing: AinkradSpacing.xs + 1) {
            ForEach(Array(event.actions.prefix(2)), id: \.id) { action in toastAction(event, action) }
            if !more.isEmpty {
                AinkradMenuButton(items: more.map { action in
                    AinkradMenuItem(title: action.label, isDestructive: action.isDestructive) {
                        onAction(event, action)
                    }
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.foreground.opacity(0.6))
                        .frame(width: 22, height: 18)
                        .background(ChamferShape(cut: 4).fill(theme.foreground.opacity(0.08)))
                }
            }
        }
    }

    private func toast(_ event: SignalEvent) -> some View {
        let accent = accent(event)
        let repeats = model.repeatCount(for: event.id)
        let isHovered = hovered == event.id
        return HStack(alignment: .top, spacing: AinkradSpacing.sm + 2) {
            leadingIcon(event)
            VStack(alignment: .leading, spacing: 3) {
                // Who: the thing it is about (the chat's service, when the
                // link names one) and the title. When, and the way out, trail.
                HStack(spacing: AinkradSpacing.xs + 1) {
                    if let symbol = event.deepLink?.symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.accentSecondary)
                    }
                    Text(event.title)
                        .font(AinkradFontResolver.font(size: 12.5, weight: .semibold, typography: typo))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                    if repeats > 1 {
                        Text("×\(repeats)")
                            .font(AinkradFontResolver.font(size: 10, weight: .semibold, typography: typo))
                            .monospacedDigit()
                            .foregroundStyle(theme.accentSecondary)
                    }
                    Spacer(minLength: AinkradSpacing.xs)
                    Text(SignalPresentation.relativeTime(event.timestamp, now: now))
                        .font(AinkradFontResolver.font(size: 10, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.4))
                    if overflowing.contains(event.id) || expanded.contains(event.id) {
                        Button { toggleExpanded(event) } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(theme.foreground.opacity(isHovered ? 0.7 : 0.4))
                                .rotationEffect(.degrees(expanded.contains(event.id) ? 180 : 0))
                                .frame(width: 14, height: 14)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(expanded.contains(event.id) ? "Show less" : "Show the whole message")
                    }
                    Button {
                        collapse(event.id)
                        model.dismiss(id: event.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(theme.foreground.opacity(isHovered ? 0.7 : 0.4))
                            .frame(width: 14, height: 14)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss")
                }
                // What, with the actions under the ✕ while the pointer is on
                // the toast. They float over the text's end rather than take
                // a row, so nothing reflows when they appear.
                bodyText(event)
                    .lineLimit(expanded.contains(event.id) ? 30 : 1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // Measure the body's natural height against one line's:
                    // the same text, laid out unclamped and invisible.
                    .background {
                        GeometryReader { oneLine in
                            bodyText(event)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(width: oneLine.size.width, alignment: .leading)
                                .hidden()
                                .background(GeometryReader { full in
                                    Color.clear.preference(
                                        key: ToastBodyOverflowKey.self,
                                        value: full.size.height > (expanded.contains(event.id) ? 0 : oneLine.size.height) + 1
                                            ? [event.id] : [])
                                })
                        }
                        .allowsHitTesting(false)
                    }
                    .overlay(alignment: .topTrailing) {
                        if isHovered && !event.actions.isEmpty {
                            actionRow(event)
                                .padding(.leading, AinkradSpacing.md)
                                .background(
                                    LinearGradient(colors: [theme.surfaceElevated.opacity(0), theme.surfaceElevated],
                                                   startPoint: .leading, endPoint: UnitPoint(x: 0.25, y: 0.5)))
                                .transition(.opacity.combined(with: .offset(x: 6)))
                        }
                    }
            }
        }
        .padding(.leading, AinkradSpacing.sm + 3)
        .padding(.trailing, AinkradSpacing.sm + 2)
        .padding(.vertical, AinkradSpacing.sm + 1)
        // A fixed width, not content-sized: a stack of toasts with ragged
        // right edges reads as a layout accident rather than one surface.
        .frame(width: 320, alignment: .leading)
        // Chamfered and accent-stroked like every other Ainkrad surface; a
        // continuous rounded rectangle read as a foreign toast library.
        .background(ChamferShape(cut: AinkradRadius.md).fill(theme.surfaceElevated))
        .overlay(ChamferShape(cut: AinkradRadius.md)
            .strokeBorder(accent.opacity(event.severity == .failure ? 0.55 : (isHovered ? 0.45 : 0.28)), lineWidth: 1))
        // Severity as an edge, not a second icon: the app icon says who, the
        // edge says how bad. Info has none, so a quiet message stays quiet.
        .overlay(alignment: .leading) {
            if event.severity != .info {
                Capsule().fill(accent).frame(width: 2.5).padding(.vertical, 8)
                    .shadow(color: accent.opacity(0.6), radius: 3)
            }
        }
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: isHovered)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.86),
                   value: expanded.contains(event.id))
        .onPreferenceChange(ToastBodyOverflowKey.self) { ids in
            if ids.contains(event.id) { overflowing.insert(event.id) }
            else if !expanded.contains(event.id) { overflowing.remove(event.id) }
        }
        // The clock stops while the pointer is over it: an eight-second
        // warning expiring mid-read is the most irritating thing a toast does.
        .onHover { isOver in
            hovered = isOver ? event.id : nil
            if isOver { model.pause(id: event.id) }
            else if !expanded.contains(event.id) { model.resume(id: event.id) }
        }
        .overlay(alignment: .bottom) { dwellBar(event) }
        .contentShape(ChamferShape(cut: AinkradRadius.md))
        .onTapGesture { onActivate(event) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(SignalPresentation.accessibilityLabel(
            for: event, repeatCount: model.repeatCount(for: event.id), isUnread: true, now: now))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onActivate(event) }
        .accessibilityActions {
            ForEach(event.actions, id: \.id) { action in
                Button(action.label) { onAction(event, action) }
            }
            Button("Dismiss") { model.dismiss(id: event.id) }
        }
    }
}

/// Ids of toasts whose body is taller than the line it is clamped to.
private struct ToastBodyOverflowKey: PreferenceKey {
    static let defaultValue: Set<UUID> = []
    static func reduce(value: inout Set<UUID>, nextValue: () -> Set<UUID>) { value.formUnion(nextValue()) }
}
