import Testing
import Foundation
@testable import AinkradAppKitUI
@testable import AinkradSignal

@Suite("Signal source rail")
struct SignalSourceRailTests {
    private func event(_ source: SignalSource, _ severity: SignalSeverity = .info,
                       id: UUID = UUID()) -> SignalEvent {
        SignalEvent(id: id, source: source, kind: "k", severity: severity, title: "t")
    }
    private func name(_ source: SignalSource) -> String {
        switch source {
        case .app(let id): return id.capitalized
        case .host: return "Ainkrad"
        case .sage: return "Sage"
        @unknown default: return "Ainkrad"
        }
    }
    private let raven = SignalSource.app(appID: "raven")
    private let rune = SignalSource.app(appID: "rune")

    @Test("an empty feed still offers All, with nothing in it")
    func emptyFeed() {
        let items = SignalSourceRailItem.build(events: [], readIDs: [], name: name)
        #expect(items.map(\.name) == ["All"])
        #expect(items[0].unread == 0)
        #expect(items[0].worstUnread == nil)
    }

    @Test("All carries the total and the worst severity across sources")
    func allAggregates() {
        let items = SignalSourceRailItem.build(
            events: [event(raven, .failure), event(rune, .info)], readIDs: [], name: name)
        #expect(items[0].name == "All")
        #expect(items[0].unread == 2)
        #expect(items[0].worstUnread == .failure)
    }

    @Test("sources are ordered loudest first")
    func loudestFirst() {
        let events = [event(rune), event(raven), event(raven), event(raven)]
        let items = SignalSourceRailItem.build(events: events, readIDs: [], name: name)
        // What needs attention belongs at the top; the whole point of the rail
        // is answering "who is unhappy" before anything is clicked.
        #expect(items.dropFirst().map(\.name) == ["Raven", "Rune"])
    }

    @Test("sources with equal counts are ordered by name, so the list is stable")
    func tiesSortByName() {
        let items = SignalSourceRailItem.build(
            events: [event(rune), event(raven)], readIDs: [], name: name)
        #expect(items.dropFirst().map(\.name) == ["Raven", "Rune"])
    }

    @Test("a source with only read events is still listed, at zero")
    func readSourceStillListed() {
        let read = UUID()
        let items = SignalSourceRailItem.build(
            events: [event(raven, .failure, id: read)], readIDs: [read], name: name)
        // It has spoken, so it stays reachable — the user may want its history
        // or its settings even when nothing is outstanding.
        #expect(items.dropFirst().map(\.name) == ["Raven"])
        #expect(items[1].unread == 0)
    }

    @Test("a failure that has been read stops colouring the dot")
    func worstSeverityIgnoresReadEvents() {
        let read = UUID()
        let items = SignalSourceRailItem.build(
            events: [event(raven, .failure, id: read), event(raven, .info)],
            readIDs: [read], name: name)
        // Otherwise the rail keeps reporting a problem the user has finished
        // with, and the dot becomes something they learn to ignore.
        #expect(items[1].worstUnread == .info)
    }

    @Test("every row has a distinct id, including All")
    func idsAreDistinct() {
        let items = SignalSourceRailItem.build(
            events: [event(raven), event(rune), event(.host)], readIDs: [], name: name)
        #expect(Set(items.map(\.id)).count == items.count)
    }
}

@Suite("Signal source grouping")
struct SignalSourceGroupingTests {
    private let raven = SignalSource.app(appID: "raven")
    private let rune = SignalSource.app(appID: "rune")
    private func event(_ source: SignalSource, at seconds: TimeInterval,
                       _ severity: SignalSeverity = .info,
                       id: UUID = UUID(), title: String = "t") -> SignalEvent {
        SignalEvent(id: id, timestamp: Date(timeIntervalSince1970: seconds),
                    source: source, kind: "k", severity: severity, title: title)
    }
    private func name(_ source: SignalSource) -> String {
        if case .app(let id) = source { return id.capitalized }
        return "Ainkrad"
    }

    @Test("groups are ordered by their newest event, not by size")
    func newestGroupFirst() {
        let events = [event(raven, at: 10), event(raven, at: 20), event(rune, at: 30)]
        let groups = SignalPresentation.sourceGroups(events, readIDs: [], name: name)
        // The feed is a timeline. A burst from one app must not permanently
        // outrank an app that has just said something.
        #expect(groups.map(\.name) == ["Rune", "Raven"])
    }

    @Test("a group's events are newest first")
    func eventsWithinGroupAreNewestFirst() {
        let groups = SignalPresentation.sourceGroups(
            [event(raven, at: 10, title: "old"), event(raven, at: 90, title: "new")],
            readIDs: [], name: name)
        #expect(groups[0].events.map(\.title) == ["new", "old"])
        #expect(groups[0].preview == "new", "a collapsed group says something specific")
    }

    @Test("a group counts only its unread events and their worst severity")
    func groupUnreadRollup() {
        let read = UUID()
        let groups = SignalPresentation.sourceGroups(
            [event(raven, at: 10, .failure, id: read), event(raven, at: 20, .warning)],
            readIDs: [read], name: name)
        #expect(groups[0].unread == 1)
        #expect(groups[0].worstUnread == .warning, "the read failure is finished with")
    }

    @Test("a fully read group reports no severity at all")
    func fullyReadGroup() {
        let read = UUID()
        let groups = SignalPresentation.sourceGroups(
            [event(raven, at: 10, .failure, id: read)], readIDs: [read], name: name)
        #expect(groups[0].unread == 0)
        #expect(groups[0].worstUnread == nil)
    }

    @Test("a single-event source is still a group")
    func singleEventGroup() {
        let groups = SignalPresentation.sourceGroups([event(raven, at: 1)],
                                                     readIDs: [], name: name)
        #expect(groups.count == 1)
        #expect(groups[0].events.count == 1)
    }

    @Test("an empty feed has no groups")
    func emptyFeed() {
        #expect(SignalPresentation.sourceGroups([], readIDs: [], name: name).isEmpty)
    }
}
