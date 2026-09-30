import Testing
import Foundation
@testable import AinkradSignal

@Suite("SignalStore dedupe")
struct SignalStoreDedupeTests {
    private func makeStore() throws -> (SignalStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("signal-\(UUID().uuidString).sqlite")
        return (try SignalStore(url: url), url)
    }

    private func event(at seconds: TimeInterval,
                       key: String? = "b:main",
                       source: SignalSource = .host,
                       title: String = "t") -> SignalEvent {
        SignalEvent(timestamp: Date(timeIntervalSince1970: seconds), source: source,
                    kind: "build.failed", severity: .failure, title: title, dedupeKey: key)
    }

    @Test("a repeat inside the window coalesces and bumps the count")
    func coalescesInsideWindow() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let first = event(at: 1000)
        #expect(try store.insert(first) == .inserted)
        #expect(try store.insert(event(at: 1030)) == .coalesced(id: first.id))
        let page = store.page(filter: .all, before: nil, limit: 10)
        #expect(page.count == 1)
        #expect(store.dedupeCount(id: first.id) == 2)
        #expect(page[0].timestamp == Date(timeIntervalSince1970: 1030), "timestamp advances to the latest")
    }

    @Test("a coalesced repeat shows the newest title and body, and search finds it")
    func coalesceKeepsLatestText() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let first = SignalEvent(timestamp: Date(timeIntervalSince1970: 1000), source: .app(appID: "whisper"),
                                kind: "whisper.message", severity: .info, title: "Mam", body: "first hello",
                                dedupeKey: "chat:mam")
        _ = try store.insert(first)
        let repeatEvent = SignalEvent(timestamp: Date(timeIntervalSince1970: 1020), source: .app(appID: "whisper"),
                                      kind: "whisper.message", severity: .info, title: "Mam", body: "second zebra",
                                      dedupeKey: "chat:mam")
        #expect(try store.insert(repeatEvent) == .coalesced(id: first.id))
        let page = store.page(filter: .all, before: nil, limit: 10)
        #expect(page.count == 1)
        #expect(page[0].id == first.id)
        #expect(page[0].body == "second zebra")
        #expect(store.search("zebra", filter: .all, limit: 10).map(\.id) == [first.id])
        #expect(store.search("first", filter: .all, limit: 10).isEmpty, "the replaced text no longer matches")
    }

    @Test("the same key outside the window inserts a new row")
    func insertsOutsideWindow() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event(at: 1000))
        #expect(try store.insert(event(at: 1000 + SignalStore.dedupeWindow + 1)) == .inserted)
        #expect(store.page(filter: .all, before: nil, limit: 10).count == 2)
    }

    @Test("the same key from a different source never coalesces")
    func scopedToSource() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event(at: 1000, source: .app(appID: "raven")))
        #expect(try store.insert(event(at: 1010, source: .app(appID: "quest"))) == .inserted)
        #expect(store.page(filter: .all, before: nil, limit: 10).count == 2)
    }

    @Test("a nil dedupe key never coalesces")
    func nilKeyAlwaysInserts() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event(at: 1000, key: nil))
        #expect(try store.insert(event(at: 1001, key: nil)) == .inserted)
        #expect(store.page(filter: .all, before: nil, limit: 10).count == 2)
    }
}
