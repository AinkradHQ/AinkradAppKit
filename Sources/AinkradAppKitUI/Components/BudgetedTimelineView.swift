import SwiftUI
import AinkradAppKitContract

/// A `TimelineView(.animation)` that obeys `AinkradMotionBudget`.
///
/// Use this instead of a bare `TimelineView(.animation)` for any DECORATIVE
/// motion. It caps the frame rate to what the budget allows and, when the
/// window is not visible, stops scheduling frames entirely — rendering the
/// time-zero pose instead, which is the same frozen-branch idiom
/// `AmbientSkyView` already uses.
///
/// Do NOT use it for motion that carries information the user is waiting on
/// (a live progress readout, for instance) — a backgrounded 5 fps is fine for
/// a glow and wrong for a countdown.
public struct BudgetedTimelineView<Content: View>: View {
    @Environment(\.ainkradMotionBudget) private var budget
    private let content: (Date) -> Content

    public init(@ViewBuilder content: @escaping (Date) -> Content) {
        self.content = content
    }

    public var body: some View {
        if let interval = budget.minimumInterval {
            TimelineView(.animation(minimumInterval: interval)) { context in
                content(context.date)
            }
        } else {
            // Frozen: the time-zero pose, so re-enabling animates forward from
            // exactly where the frozen frame sat rather than jumping.
            content(Date(timeIntervalSinceReferenceDate: 0))
        }
    }
}
