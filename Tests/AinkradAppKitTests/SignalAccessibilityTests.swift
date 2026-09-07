import Testing
import SwiftUI
import Foundation
@testable import AinkradAppKitUI
@testable import AinkradSignal

@Suite("Signal accessibility labels")
struct SignalAccessibilityTests {
    private let now = Date(timeIntervalSince1970: 100_000)
    private func event(_ severity: SignalSeverity = .failure,
                       source: SignalSource = .app(appID: "raven"),
                       body: String? = "3 errors",
                       ago: TimeInterval = 0) -> SignalEvent {
        SignalEvent(timestamp: now.addingTimeInterval(-ago), source: source,
                    kind: "build.failed", severity: severity,
                    title: "Build failed", body: body)
    }

    @Test("severity is spoken first, before the title")
    func severityLeads() {
        let label = SignalPresentation.accessibilityLabel(
            for: event(), repeatCount: 1, isUnread: true, now: now)
        // A sighted user gets severity from a coloured glyph before reading a
        // word. A listener who hears the title first must wait to the end of
        // the sentence to learn whether it matters.
        #expect(label.hasPrefix("Failure, Raven, Build failed"))
    }

    @Test("the label carries body, time, and read state")
    func fullLabel() {
        let label = SignalPresentation.accessibilityLabel(
            for: event(ago: 180), repeatCount: 1, isUnread: true, now: now)
        #expect(label == "Failure, Raven, Build failed, 3 errors, 3 minutes ago, unread")
    }

    @Test("repeats and pinning are announced when they apply")
    func repeatsAndPin() {
        let label = SignalPresentation.accessibilityLabel(
            for: event(), repeatCount: 4, isUnread: false, isPinned: true, now: now)
        #expect(label.contains("repeated 4 times"))
        #expect(label.contains("pinned"))
        #expect(label.hasSuffix("read"))
    }

    @Test("a single occurrence says nothing about repeats")
    func noRepeatNoise() {
        let label = SignalPresentation.accessibilityLabel(
            for: event(), repeatCount: 1, isUnread: true, now: now)
        #expect(!label.contains("repeated"))
        #expect(!label.contains("pinned"))
    }

    @Test("an event with no body does not leave an empty clause")
    func emptyBodyOmitted() {
        let label = SignalPresentation.accessibilityLabel(
            for: event(body: nil), repeatCount: 1, isUnread: true, now: now)
        #expect(!label.contains(", , "))
        #expect(label == "Failure, Raven, Build failed, just now, unread")
    }

    @Test("time is spoken in words, not the visual abbreviation")
    func spokenTime() {
        // `relativeTime` returns "3h", which a screen reader reads as the
        // letter h.
        #expect(SignalPresentation.relativeTime(now.addingTimeInterval(-7200), now: now) == "2h")
        #expect(SignalPresentation.relativeTimeSpoken(
            now.addingTimeInterval(-7200), now: now) == "2 hours ago")
        #expect(SignalPresentation.relativeTimeSpoken(
            now.addingTimeInterval(-3600), now: now) == "1 hour ago")
        #expect(SignalPresentation.relativeTimeSpoken(
            now.addingTimeInterval(-60), now: now) == "1 minute ago")
        #expect(SignalPresentation.relativeTimeSpoken(
            now.addingTimeInterval(-172800), now: now) == "2 days ago")
    }

    @Test("host and Sage are named as themselves")
    func hostSources() {
        #expect(SignalPresentation.accessibilityLabel(
            for: event(source: .host), repeatCount: 1, isUnread: true,
            now: now).contains("Ainkrad"))
        #expect(SignalPresentation.accessibilityLabel(
            for: event(source: .sage), repeatCount: 1, isUnread: true,
            now: now).contains("Sage"))
    }

    @Test("a rail row speaks its count and worst severity")
    func railLabel() {
        // Both are a coloured dot and a small number — invisible to a
        // listener, and both the reason the rail exists.
        #expect(SignalSourceRail.label(for: SignalSourceRailItem(
            source: .app(appID: "raven"), name: "Raven", unread: 3,
            worstUnread: .failure)) == "Raven, 3 unread, worst failure")
    }

    @Test("a quiet rail row says so rather than staying silent")
    func railLabelQuiet() {
        #expect(SignalSourceRail.label(for: SignalSourceRailItem(
            source: .app(appID: "lore"), name: "Lore", unread: 0,
            worstUnread: nil)) == "Lore, nothing unread")
    }

    @Test("All speaks the total the same way")
    func railLabelAll() {
        #expect(SignalSourceRail.label(for: SignalSourceRailItem(
            source: nil, name: "All", unread: 7,
            worstUnread: .warning)) == "All, 7 unread, worst warning")
    }
}

@Suite("Colour contrast ratio")
struct ColorContrastRatioTests {
    @Test("black on white is the maximum ratio, and a colour on itself is the minimum")
    func bounds() {
        #expect(abs(Color.black.contrastRatio(against: .white) - 21) < 0.1)
        #expect(abs(Color.white.contrastRatio(against: .white) - 1) < 0.01)
    }

    @Test("the ratio is symmetric, so argument order cannot change a verdict")
    func symmetric() {
        let a = Color(red: 0.2, green: 0.7, blue: 0.4)
        let b = Color(red: 0.1, green: 0.1, blue: 0.15)
        #expect(abs(a.contrastRatio(against: b) - b.contrastRatio(against: a)) < 0.001)
    }
}
