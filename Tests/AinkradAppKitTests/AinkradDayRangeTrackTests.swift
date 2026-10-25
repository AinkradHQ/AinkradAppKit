import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradDayRangeTrack")
@MainActor
struct AinkradDayRangeTrackTests {
    @Test("a plain range keeps its handles an hour apart")
    func gap() {
        #expect(AinkradDayRangeTrack.constrain(19.5, handle: 0, other: 20, wraps: false) == 19)
        #expect(AinkradDayRangeTrack.constrain(8.2, handle: 1, other: 8, wraps: false) == 9)
        #expect(AinkradDayRangeTrack.constrain(30, handle: 1, other: 8, wraps: false) == 24)
        #expect(AinkradDayRangeTrack.constrain(3, handle: 0, other: 2, wraps: true) == 3)
    }

    @Test("values snap to half hours and a wrapped range reads 24 as midnight")
    func snapping() {
        #expect(AinkradDayRangeTrack.snap(7.74, wraps: false) == 7.5)
        #expect(AinkradDayRangeTrack.snap(7.76, wraps: false) == 8)
        #expect(AinkradDayRangeTrack.snap(24, wraps: false) == 24)
        #expect(AinkradDayRangeTrack.snap(23.9, wraps: true) == 0)
    }

    @Test("a wrapped range draws as two segments and the clock reads hh:mm")
    func segmentsAndClock() {
        #expect(AinkradDayRangeTrack.segments(22, 7.5, wraps: true) == [22...24, 0...7.5])
        #expect(AinkradDayRangeTrack.segments(8, 20, wraps: false) == [8...20])
        #expect(AinkradDayRangeTrack.clock(9.5) == "09:30")
        #expect(AinkradDayRangeTrack.clock(24) == "00:00")
    }

    @Test("the track draws plain, wrapped and off")
    func draws() {
        let view = VStack(spacing: 28) {
            AinkradDayRangeTrack(start: .constant(8), end: .constant(20))
            AinkradDayRangeTrack(start: .constant(22), end: .constant(7.5), wraps: true, label: "muted")
            AinkradDayRangeTrack(start: .constant(9), end: .constant(17), isOn: false)
        }
        #expect(PromotedRender.draws(view, width: 400, height: 220))
    }
}
