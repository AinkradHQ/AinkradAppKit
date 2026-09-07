import Testing
import Foundation
@testable import AinkradSignal

@Suite("Signal health")
struct SignalHealthTests {
    private func makeStore() throws -> (SignalStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("signal-health-\(UUID().uuidString).sqlite")
        return (try SignalStore(url: url), url)
    }
    private let epoch = Date(timeIntervalSince1970: 1_000_000)
    private func event(_ kind: String, at offset: TimeInterval = 0,
                       source: SignalSource = .app(appID: "raven")) -> SignalEvent {
        SignalEvent(timestamp: epoch.addingTimeInterval(offset), source: source,
                    kind: kind, severity: .info, title: kind)
    }

    @Test("an empty window reports nothing rather than zero percent read")
    func emptyWindow() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let health = store.health(since: epoch)
        // 0% read on a fresh install is not a finding, and rendering it as one
        // would indict a feature nobody has used yet.
        #expect(health == .empty)
        #expect(health.medianAcknowledgeSeconds == nil)
    }

    @Test("read rate counts what was read out of what arrived")
    func readRate() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        let a = event("a"), b = event("b"), c = event("c", at: 1)
        for e in [a, b, c] { _ = try store.insert(e) }
        store.markRead(ids: [a.id])

        let health = store.health(since: epoch.addingTimeInterval(-10))
        #expect(health.total == 3)
        #expect(abs(health.readRate - 1.0 / 3.0) < 0.001)
    }

    @Test("nothing read means no median, which is not the same as zero")
    func noMedianWhenNothingRead() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("a"))
        #expect(store.health(since: epoch.addingTimeInterval(-10))
            .medianAcknowledgeSeconds == nil)
    }

    @Test("the window excludes anything older than it")
    func windowExcludesOlder() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("old", at: -3600))
        _ = try store.insert(event("new", at: 0))
        #expect(store.health(since: epoch.addingTimeInterval(-60)).total == 1)
    }

    @Test("health can be scoped to one source, host included")
    func perSource() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("raven.thing"))
        _ = try store.insert(event("host.thing", at: 1, source: .host))

        let since = epoch.addingTimeInterval(-10)
        #expect(store.health(since: since, source: .app(appID: "raven")).total == 1)
        // Host stores a NULL app id, so this is the case a plain `=` would
        // silently report as zero.
        #expect(store.health(since: since, source: .host).total == 1)
    }

    @Test("the noisiest kind comes first, and ties break toward the least read")
    func noisiestOrdering() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        var loudRead: [UUID] = []
        for i in 0..<5 {
            let e = event("loud", at: Double(i))
            _ = try store.insert(e)
            if i < 4 { loudRead.append(e.id) }
        }
        for i in 0..<5 { _ = try store.insert(event("ignored", at: Double(10 + i))) }
        _ = try store.insert(event("quiet", at: 100))
        store.markRead(ids: loudRead)

        let noisiest = store.health(since: epoch.addingTimeInterval(-10)).noisiest
        // Equal volume, so the unread one leads: the top row is by definition
        // the next default worth changing.
        #expect(noisiest.map(\.kind) == ["ignored", "loud", "quiet"])
    }

    @Test("the median is the middle delay, not the mean")
    func medianNotMean() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        // Delays of 1s, 2s and 600s. A mean would report about 3.5 minutes and
        // describe nobody's experience; the median says 2 seconds.
        for (i, delay) in [1.0, 2.0, 600.0].enumerated() {
            let e = event("k\(i)", at: Double(i))
            _ = try store.insert(e)
            store.markRead(ids: [e.id])
            // markRead stamps `now`, so rewrite the stamp to a known delay.
            try store.setReadStampForTesting(id: e.id,
                                             at: e.timestamp.addingTimeInterval(delay))
        }
        let median = store.health(since: epoch.addingTimeInterval(-10))
            .medianAcknowledgeSeconds
        #expect(median != nil)
        #expect(abs((median ?? 0) - 2.0) < 0.5)
    }

    @Test("a noisiest row names its source, so it can actually be muted")
    func noisiestCarriesSource() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("sync.failed"))
        _ = try store.insert(event("sync.failed", at: 1))

        let top = try #require(store.health(since: epoch.addingTimeInterval(-10))
            .noisiest.first)

        // Overrides are keyed by (source, kind). Without the source a mute
        // control has to guess, and a wrong guess is a button that appears to
        // work and silently does nothing.
        #expect(top.source == .app(appID: "raven"))
    }

    @Test("the same kind from two sources is two rows, not one")
    func sameKindDifferentSources() throws {
        let (store, url) = try makeStore()
        defer { try? FileManager.default.removeItem(at: url) }
        _ = try store.insert(event("thing.failed"))
        _ = try store.insert(event("thing.failed", at: 1, source: .host))

        let rows = store.health(since: epoch.addingTimeInterval(-10)).noisiest
        #expect(rows.count == 2)
        #expect(Set(rows.compactMap(\.source)) == [.app(appID: "raven"), .host])
        // Distinct ids, or a ForEach collapses them into one row.
        #expect(Set(rows.map(\.id)).count == 2)
    }
}
