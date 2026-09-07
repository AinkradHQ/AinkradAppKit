import SwiftUI
import AinkradAppKitContract
import AinkradSignal

/// Day-grouped list of events. Deliberately dumb: it owns no state and reads
/// no store, because both the bell popover and the in-window island embed it.
public struct SignalFeedList: View {
    public let events: [SignalEvent]
    public var repeatCounts: [UUID: Int] = [:]
    public var readIDs: Set<UUID> = []
    public var now: Date = Date()
    public var calendar: Calendar = .current
    public var onActivate: (SignalEvent) -> Void = { _ in }
    public var onAction: (SignalEvent, SignalAction) -> Void = { _, _ in }
    /// Per-row right-click menu, passed straight through to `SignalFeedRow`.
    public var menuItems: (SignalEvent) -> [AinkradMenuItem] = { _ in [] }
    public var pinnedIDs: Set<UUID> = []
    public var expandedIDs: Binding<Set<UUID>> = .constant([])

    /// Explicit, because a public struct's implicit memberwise
    /// initialiser is INTERNAL — the components were public and
    /// unconstructible outside the module until this existed.
    public init(events: [SignalEvent],
                repeatCounts: [UUID: Int] = [:],
                readIDs: Set<UUID> = [],
                now: Date = Date(),
                calendar: Calendar = .current,
                onActivate: @escaping (SignalEvent) -> Void = { _ in },
                onAction: @escaping (SignalEvent, SignalAction) -> Void = { _, _ in }) {
        self.events = events
        self.repeatCounts = repeatCounts
        self.readIDs = readIDs
        self.now = now
        self.calendar = calendar
        self.onActivate = onActivate
        self.onAction = onAction
    }

    /// Separate, not a defaulted parameter — see `SignalFeedRow`'s note on
    /// library evolution and mangled initialiser symbols.
    public init(events: [SignalEvent],
                repeatCounts: [UUID: Int],
                readIDs: Set<UUID>,
                now: Date,
                calendar: Calendar,
                onActivate: @escaping (SignalEvent) -> Void,
                onAction: @escaping (SignalEvent, SignalAction) -> Void,
                menuItems: @escaping (SignalEvent) -> [AinkradMenuItem]) {
        self.events = events
        self.repeatCounts = repeatCounts
        self.readIDs = readIDs
        self.now = now
        self.calendar = calendar
        self.onActivate = onActivate
        self.onAction = onAction
        self.menuItems = menuItems
    }

    /// Separate again, same reason.
    public init(events: [SignalEvent],
                repeatCounts: [UUID: Int],
                readIDs: Set<UUID>,
                now: Date,
                calendar: Calendar,
                onActivate: @escaping (SignalEvent) -> Void,
                onAction: @escaping (SignalEvent, SignalAction) -> Void,
                menuItems: @escaping (SignalEvent) -> [AinkradMenuItem],
                pinnedIDs: Set<UUID>,
                expandedIDs: Binding<Set<UUID>>) {
        self.events = events
        self.repeatCounts = repeatCounts
        self.readIDs = readIDs
        self.now = now
        self.calendar = calendar
        self.onActivate = onActivate
        self.onAction = onAction
        self.menuItems = menuItems
        self.pinnedIDs = pinnedIDs
        self.expandedIDs = expandedIDs
    }

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    /// The row the arrow keys are on. Owned by the LIST, not the row: only
    /// something that knows the order can move a selection through it.
    @State private var keyboardFocus: UUID?
    @FocusState private var listHasFocus: Bool

    private var groups: [SignalDayGroup] {
        SignalPresentation.dayGroups(events, calendar: calendar)
    }

    public var body: some View {
        if events.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AinkradSpacing.xs / 2,
                           pinnedViews: [.sectionHeaders]) {
                    ForEach(groups) { group in
                        Section {
                            ForEach(group.events) { event in
                                SignalFeedRow(
                                    event: event,
                                    repeatCount: repeatCounts[event.id] ?? 1,
                                    isUnread: !readIDs.contains(event.id),
                                    now: now,
                                    onActivate: onActivate,
                                    onAction: onAction,
                                    menuItems: menuItems,
                                    isPinned: pinnedIDs.contains(event.id),
                                    isExpanded: expandedIDs.wrappedValue.contains(event.id),
                                    onToggleExpanded: {
                                        if expandedIDs.wrappedValue.contains(event.id) {
                                            expandedIDs.wrappedValue.remove(event.id)
                                        } else {
                                            expandedIDs.wrappedValue.insert(event.id)
                                        }
                                    },
                                    isKeyboardFocused: keyboardFocus == event.id)
                            }
                        } header: {
                            dayHeader(group.id)
                        }
                    }
                }
                .padding(.vertical, AinkradSpacing.xs + 2)
                .padding(.horizontal, AinkradSpacing.xs + 2)
            }
            // Focus on the LIST rather than per row: `.onKeyPress` only fires
            // for something in the focus chain, and a list that hands focus to
            // each row would make Tab walk every event in the feed.
            .focusable()
            .focused($listHasFocus)
            .onKeyPress(.downArrow) { move(by: 1); return .handled }
            .onKeyPress(.upArrow) { move(by: -1); return .handled }
            .onKeyPress(.return) { activateFocused(); return .handled }
            .onKeyPress(.space) { activateFocused(); return .handled }
        }
    }

    /// Moves the selection, clamped rather than wrapping.
    ///
    /// Wrapping at the ends would silently jump the user from the newest event
    /// to the oldest, which in a feed reads as the list having scrolled
    /// somewhere unexpected rather than as a selection moving.
    private func move(by delta: Int) {
        keyboardFocus = Self.nextFocus(in: groups.flatMap(\.events).map(\.id),
                                       from: keyboardFocus, by: delta)
    }

    private func activateFocused() {
        guard let id = keyboardFocus,
              let event = groups.flatMap(\.events).first(where: { $0.id == id })
        else { return }
        onActivate(event)
    }

    /// The order the arrow keys walk — day groups flattened, exactly as drawn.
    /// Exposed so the traversal is testable without a window or a key event.
    public static func keyboardOrder(_ events: [SignalEvent],
                                     calendar: Calendar = .current) -> [UUID] {
        SignalPresentation.dayGroups(events, calendar: calendar)
            .flatMap(\.events).map(\.id)
    }

    /// Where a move lands. Pure, and clamped at both ends.
    public static func nextFocus(in order: [UUID], from current: UUID?,
                                 by delta: Int) -> UUID? {
        guard !order.isEmpty else { return nil }
        guard let current, let index = order.firstIndex(of: current) else {
            return order.first
        }
        return order[min(max(0, index + delta), order.count - 1)]
    }

    /// A header, not a separator: the design language forbids rules, so the day
    /// break is carried by weight and a soft scrim behind the pinned label.
    private func dayHeader(_ day: Date) -> some View {
        // Mono, uppercase, tracked: a date is a readout, and this is the same
        // treatment the top bar gives the clock.
        Text(Self.dayLabel(day, now: now, calendar: calendar))
            .font(AinkradFontResolver.font(size: 9.5, weight: .semibold, mono: true, typography: typo))
            .foregroundStyle(theme.foreground.opacity(0.42))
            .textCase(.uppercase)
            .tracking(0.7)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.top, AinkradSpacing.sm + 2)
            .padding(.bottom, AinkradSpacing.xs)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surface.opacity(0.92))
    }

    public static func dayLabel(_ day: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)),
           calendar.isDate(day, inSameDayAs: yesterday) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: day)
    }

    private var emptyState: some View {
        VStack(spacing: AinkradSpacing.xs + 2) {
            Image(systemName: "bell.slash")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(theme.foreground.opacity(0.3))
            Text("Nothing yet")
                .font(AinkradFontResolver.font(size: 12, weight: .medium, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.55))
            AinkradCaption("Runs, builds and app events will show up here.")
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AinkradSpacing.xl + AinkradSpacing.sm)
    }
}
