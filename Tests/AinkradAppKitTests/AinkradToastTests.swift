import Foundation
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("Toast queue reducer")
struct ToastQueueTests {
    private func item(_ message: String, expiresIn seconds: TimeInterval, from now: Date) -> AinkradToastItem {
        AinkradToastItem(id: UUID(), message: message, status: .neutral, expiresAt: now.addingTimeInterval(seconds))
    }

    @Test("adding appends to the end of the queue")
    func adds() {
        let now = Date()
        let a = item("a", expiresIn: 3, from: now)
        let b = item("b", expiresIn: 3, from: now)
        let queue = toastQueueAdding(b, to: toastQueueAdding(a, to: []))
        #expect(queue.map(\.message) == ["a", "b"])
    }

    @Test("expiring drops items whose expiresAt is at/before now")
    func expiresPastItems() {
        let now = Date()
        let expired = item("gone", expiresIn: -1, from: now)
        let alive = item("here", expiresIn: 5, from: now)
        let queue = toastQueueExpiring([expired, alive], now: now)
        #expect(queue.map(\.message) == ["here"])
    }

    @Test("expiring an all-fresh queue changes nothing")
    func keepsFreshQueue() {
        let now = Date()
        let a = item("a", expiresIn: 10, from: now)
        let b = item("b", expiresIn: 20, from: now)
        let queue = toastQueueExpiring([a, b], now: now)
        #expect(queue.map(\.message) == ["a", "b"])
    }

    @Test("expiring an empty queue stays empty")
    func expiresEmpty() {
        #expect(toastQueueExpiring([], now: Date()).isEmpty)
    }
}

@Suite("Toast center dismiss")
struct ToastCenterDismissTests {
    @Test("dismissing one toast removes only that toast, leaving the other")
    @MainActor
    func dismissRemovesOnlyTargetedToast() {
        let center = AinkradToastCenter()
        center.show("first", duration: 60)
        center.show("second", duration: 60)

        #expect(center.items.count == 2)
        let firstID = center.items[0].id

        center.dismiss(firstID)

        #expect(center.items.count == 1)
        #expect(center.items.first?.message == "second")
    }
}
