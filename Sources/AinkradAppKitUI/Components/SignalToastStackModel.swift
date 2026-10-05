import AinkradAppKitContract
import AinkradSignal
import SwiftUI

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
            !queued.contains(where: { $0.id == event.id })
        else { return }

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
            visible.contains(where: { $0.id == id })
        else { return }
        deadlines[id] = now.addingTimeInterval(remaining)
        scheduleSweep()
    }

    /// How much of its life a toast has left, 0...1. Drives the hairline, and
    /// is a pure function so the bar can be tested without waiting.
    public func remainingFraction(
        id: UUID, severity: SignalSeverity,
        now: Date = Date()
    ) -> Double? {
        let event = visible.first { $0.id == id }
        guard let total = event.map(Self.autoDismissDelay(for:)) ?? Self.autoDismissDelay(for: severity) else {
            return nil
        }
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
