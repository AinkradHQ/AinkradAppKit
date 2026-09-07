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

    /// `nil` means "requires an explicit dismissal". A failure that vanished on
    /// its own is exactly the case this feature exists to prevent.
    public static func autoDismissDelay(for severity: SignalSeverity) -> TimeInterval? {
        switch severity {
        case .info, .success: return 4
        case .warning: return 8
        case .failure: return nil
        @unknown default: return 4
        }
    }

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
    public func present(_ event: SignalEvent) {
        guard !visible.contains(where: { $0.id == event.id }),
              !queued.contains(where: { $0.id == event.id }) else { return }

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
        guard let total = Self.autoDismissDelay(for: severity) else { return nil }
        if let held = heldRemaining[id] { return min(1, max(0, held / total)) }
        guard let deadline = deadlines[id] else { return nil }
        return min(1, max(0, deadline.timeIntervalSince(now) / total))
    }

    private func scheduleAutoDismiss(_ event: SignalEvent) {
        guard let delay = Self.autoDismissDelay(for: event.severity) else { return }
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

/// Bottom-trailing stack of transient toasts.
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
    @State private var hovered: UUID?

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

    private func toast(_ event: SignalEvent) -> some View {
        let accent = SignalPresentation.color(for: event.severity, in: status)
        return HStack(alignment: .top, spacing: AinkradSpacing.sm + 1) {
            Image(systemName: SignalPresentation.iconSymbol(for: event.severity))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
                Text(event.title)
                    .font(AinkradFontResolver.font(size: 12, weight: .semibold, typography: typo))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                if let body = event.body, !body.isEmpty {
                    Text(body)
                        .font(AinkradFontResolver.font(size: 11, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.6))
                        .lineLimit(2)
                }
                // At most two. The toast is the surface that appears at the
                // moment the thing happened, and until now it was the one
                // surface that could do nothing about it.
                if !event.actions.isEmpty {
                    HStack(spacing: AinkradSpacing.xs + 2) {
                        ForEach(event.actions.prefix(2), id: \.id) { action in
                            toastAction(event, action)
                        }
                    }
                    .padding(.top, 1)
                }
            }
            Button {
                model.dismiss(id: event.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(theme.foreground.opacity(0.45))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm + 2)
        // A fixed width, not content-sized: a stack of toasts with ragged
        // right edges reads as a layout accident rather than one surface.
        .frame(width: 330, alignment: .leading)
        // Chamfered and accent-stroked like every other Ainkrad surface; a
        // continuous rounded rectangle read as a foreign toast library.
        .background(ChamferShape(cut: AinkradRadius.md).fill(theme.surfaceElevated))
        .overlay(ChamferShape(cut: AinkradRadius.md)
            .strokeBorder(accent.opacity(event.severity == .failure ? 0.55 : 0.3), lineWidth: 1))
        // A failure toast carries a hairline of its own severity colour rather
        // than a separator: it has to be distinguishable at a glance, since it
        // is the one toast that never auto-dismisses.
        .overlay(alignment: .leading) {
            if event.severity == .failure {
                Capsule().fill(accent).frame(width: 2.5).padding(.vertical, 8)
            }
        }
        // The clock stops while the pointer is over it: an eight-second
        // warning expiring mid-read is the most irritating thing a toast does.
        .onHover { isOver in
            hovered = isOver ? event.id : nil
            if isOver { model.pause(id: event.id) } else { model.resume(id: event.id) }
        }
        .overlay(alignment: .bottom) { dwellBar(event) }
        .contentShape(ChamferShape(cut: AinkradRadius.md))
        .onTapGesture { onActivate(event) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(SignalPresentation.accessibilityLabel(
            for: event, repeatCount: 1, isUnread: true, now: now))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onActivate(event) }
        .accessibilityActions {
            ForEach(event.actions.prefix(2), id: \.id) { action in
                Button(action.label) { onAction(event, action) }
            }
            Button("Dismiss") { model.dismiss(id: event.id) }
        }
    }
}
