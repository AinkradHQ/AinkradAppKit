import AinkradSignal
import Foundation
import Testing

@testable import AinkradAppKitUI

@MainActor
@Suite("SignalToastModel")
final class SignalToastStackModelTests {
    private func event(_ title: String, _ severity: SignalSeverity = .info) -> SignalEvent {
        SignalEvent(source: .host, kind: "test.event", severity: severity, title: title)
    }

    @Test("at most three toasts are visible; the rest become an overflow count")
    func caps() {
        let model = SignalToastModel()
        for i in 0..<6 { model.present(event("e\(i)")) }
        #expect(model.visible.count == 3)
        #expect(model.overflowCount == 3)
        #expect(
            model.visible.first?.title == "e2",
            "arrivals past the cap queue; they do not evict a toast being read")
    }

    @Test("dismissing promotes an overflowed toast into view")
    func dismissPromotes() {
        let model = SignalToastModel()
        for i in 0..<4 { model.present(event("e\(i)")) }
        #expect(model.overflowCount == 1)
        model.dismiss(id: model.visible[0].id)
        #expect(model.visible.count == 3)
        #expect(model.overflowCount == 0)
        #expect(model.visible.first?.title == "e3", "the promoted toast lands on top")
    }

    @Test("auto-dismiss delay scales with severity; failures stay longest but not forever")
    func autoDismissDelays() {
        #expect(SignalToastModel.autoDismissDelay(for: .info) == 4)
        #expect(SignalToastModel.autoDismissDelay(for: .success) == 4)
        #expect(SignalToastModel.autoDismissDelay(for: .warning) == 8)
        #expect(
            SignalToastModel.autoDismissDelay(for: .failure) == 30,
            "three failures that never left filled every slot; the feed keeps them")
    }

    @Test("an urgent info toast stays at least eight seconds")
    func urgentStaysLonger() {
        let message = SignalEvent(
            source: .app(appID: "whisper"), kind: "whisper.message", severity: .info,
            title: "Mam", proposedImportance: .urgent)
        #expect(SignalToastModel.autoDismissDelay(for: message) == 8)
        #expect(SignalToastModel.autoDismissDelay(for: event("plain")) == 4)
    }

    @Test("a repeat replaces its toast in place and counts itself")
    func repeatsInPlace() {
        let model = SignalToastModel()
        func chat(_ body: String, key: String = "acct:Mam") -> SignalEvent {
            SignalEvent(
                source: .app(appID: "whisper"), kind: "whisper.message", severity: .info,
                title: "Mam", body: body, dedupeKey: key)
        }
        model.present(event("other"))
        model.present(chat("one"))
        model.present(chat("two"))
        model.present(chat("three"))
        #expect(model.visible.count == 2, "one toast for the chat, not three")
        #expect(model.visible[0].body == "three", "the newest text is shown")
        #expect(model.repeatCount(for: model.visible[0].id) == 3)
        model.present(chat("elsewhere", key: "acct:Islam"))
        #expect(model.visible.count == 3, "a different chat is its own toast")
    }

    @Test("a failure arriving past the cap displaces the least-severe toast")
    func severityDisplacesWeakest() {
        let model = SignalToastModel()
        for i in 0..<3 { model.present(event("info\(i)", .info)) }
        model.present(event("BUILD FAILED", .failure))

        #expect(
            model.visible.first?.title == "BUILD FAILED",
            "the failure must not sit behind chatty info toasts")
        #expect(model.visible.count == 3)
        #expect(model.overflowCount == 1, "the displaced info toast goes back to the queue")
        #expect(
            !model.visible.contains { $0.severity == .info && $0.title == "info0" }
                || model.visible.filter { $0.severity == .info }.count == 2)
    }

    @Test("a failure on screen is never displaced, not even by another failure")
    func failuresAreNeverDisplaced() {
        let model = SignalToastModel()
        for i in 0..<3 { model.present(event("fail\(i)", .failure)) }
        model.present(event("newest failure", .failure))
        #expect(model.overflowCount == 1, "equal severity queues rather than displacing")
        #expect(model.visible.allSatisfy { $0.title != "newest failure" })
    }

    @Test("a less severe arrival still queues")
    func lessSevereQueues() {
        let model = SignalToastModel()
        for i in 0..<3 { model.present(event("warn\(i)", .warning)) }
        model.present(event("chatter", .info))
        #expect(model.overflowCount == 1)
        #expect(model.visible.allSatisfy { $0.severity == .warning })
    }

    @Test("presenting the same event twice does not stack duplicates")
    func idempotentPresent() {
        let model = SignalToastModel()
        let e = event("once")
        model.present(e)
        model.present(e)
        #expect(model.visible.count == 1)
    }

    @Test("hovering stops the clock, and a hovered toast outlives its window")
    func hoverPauses() {
        let model = SignalToastModel()
        let event = SignalEvent(source: .host, kind: "k", severity: .warning, title: "t")
        model.present(event)
        let start = Date()

        model.pause(id: event.id, now: start)

        // A warning's window is eight seconds; thirty seconds later, hovered,
        // it must still be there. Expiring mid-read is the single most
        // irritating thing a toast does.
        #expect(model.deadlines[event.id] == nil)
        #expect(model.visible.contains { $0.id == event.id })
        #expect(
            model.remainingFraction(
                id: event.id, severity: .warning,
                now: start.addingTimeInterval(30)) != nil)
    }

    @Test("resuming gives back the time that was left, not a fresh window")
    func resumeKeepsRemaining() {
        let model = SignalToastModel()
        let event = SignalEvent(source: .host, kind: "k", severity: .warning, title: "t")
        model.present(event)
        let start = Date()
        // Four seconds into an eight-second window.
        model.pause(id: event.id, now: start.addingTimeInterval(4))
        let held = model.remainingFraction(id: event.id, severity: .warning, now: start)
        model.resume(id: event.id, now: start.addingTimeInterval(20))

        #expect(held != nil)
        let after = model.remainingFraction(
            id: event.id, severity: .warning,
            now: start.addingTimeInterval(20))
        // Roughly half left, both before and after — resuming must not restart
        // the clock, or hovering would make a toast immortal.
        #expect(abs((after ?? 0) - (held ?? 0)) < 0.05)
    }

    @Test("a failure gets the longest clock, thirty seconds")
    func failureHasLongDeadline() {
        let model = SignalToastModel()
        let event = SignalEvent(source: .host, kind: "k", severity: .failure, title: "t")
        let before = Date()
        model.present(event)
        let deadline = try? #require(model.deadlines[event.id])
        #expect(deadline.map { $0.timeIntervalSince(before) > 29 } == true)
        #expect((model.remainingFraction(id: event.id, severity: .failure) ?? 0) > 0.9)
    }

    @Test("dismissing forgets the toast's clock")
    func dismissClearsState() {
        let model = SignalToastModel()
        let event = SignalEvent(source: .host, kind: "k", severity: .info, title: "t")
        model.present(event)
        model.pause(id: event.id)
        model.dismiss(id: event.id)
        #expect(model.deadlines[event.id] == nil)
        #expect(model.remainingFraction(id: event.id, severity: .info) == nil)
    }

    @Test("resuming a toast that is gone does nothing")
    func resumeAfterDismissIsInert() {
        let model = SignalToastModel()
        let event = SignalEvent(source: .host, kind: "k", severity: .info, title: "t")
        model.present(event)
        model.pause(id: event.id)
        model.dismiss(id: event.id)
        model.resume(id: event.id)
        // The sweep would otherwise resurrect a deadline for a toast nobody
        // can see, and keep sweeping forever.
        #expect(model.deadlines[event.id] == nil)
    }
}
