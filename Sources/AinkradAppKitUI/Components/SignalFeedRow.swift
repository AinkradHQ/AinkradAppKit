import SwiftUI
import AinkradAppKitContract
import AinkradSignal

public struct SignalDayGroup: Identifiable, Equatable {
    public let id: Date          // start of day
    public let events: [SignalEvent]
}

/// A run of events from one source, for the feed's by-app mode.
public struct SignalSourceGroup: Identifiable, Equatable {
    public let source: SignalSource
    public let name: String
    public let events: [SignalEvent]
    public let unread: Int
    public let worstUnread: SignalSeverity?

    public var id: String { "\(source)" }

    /// The newest title, shown on a collapsed group so it says something
    /// specific rather than only how many.
    public var preview: String? { events.first?.title }
}

/// Pure presentation helpers, kept out of the `View` so they are testable
/// without rendering. Anything that needs a clock takes it as a parameter —
/// no `Date()` inside a formatter.
public enum SignalPresentation {
    public static func relativeTime(_ date: Date, now: Date) -> String {
        let elapsed = max(0, now.timeIntervalSince(date))
        switch elapsed {
        case ..<60: return "now"
        case ..<3600: return "\(Int(elapsed / 60))m"
        case ..<86400: return "\(Int(elapsed / 3600))h"
        default: return "\(Int(elapsed / 86400))d"
        }
    }

    public static func dayGroups(_ events: [SignalEvent], calendar: Calendar) -> [SignalDayGroup] {
        let sorted = events.sorted { $0.timestamp > $1.timestamp }
        var order: [Date] = []
        var buckets: [Date: [SignalEvent]] = [:]
        for event in sorted {
            let day = calendar.startOfDay(for: event.timestamp)
            if buckets[day] == nil { order.append(day) }
            buckets[day, default: []].append(event)
        }
        return order.map { SignalDayGroup(id: $0, events: buckets[$0] ?? []) }
    }

    public static func iconSymbol(for severity: SignalSeverity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .failure: return "xmark.octagon"
        @unknown default: return "info.circle"
        }
    }

    /// Severity in the kit's own vocabulary, so Signal colours itself from the
    /// same `AinkradStatus` ramp every other component uses instead of a
    /// parallel palette of its own.
    ///
    /// `.info` maps to `.neutral` rather than a tinted success: an informational
    /// event is not a small success, and rendering it green said it was.
    public static func status(for severity: SignalSeverity) -> AinkradStatus {
        switch severity {
        case .info: return .neutral
        case .success: return .success
        case .warning: return .warning
        case .failure: return .danger
        @unknown default: return .neutral
        }
    }

    public static func color(for severity: SignalSeverity, in status: AinkradStatusColors) -> Color {
        switch severity {
        case .success: return status.success
        case .warning: return status.warning
        case .failure: return status.danger
        case .info: return status.success.opacity(0.55)
        @unknown default: return status.success.opacity(0.55)
        }
    }

    /// Groups events by source, newest group first.
    ///
    /// Ordered by each group's newest event rather than by count: the feed is
    /// a timeline, and a burst from one app should not permanently outrank an
    /// app that just said something.
    public static func sourceGroups(_ events: [SignalEvent],
                                    readIDs: Set<UUID>,
                                    name: (SignalSource) -> String) -> [SignalSourceGroup] {
        let sorted = events.sorted { $0.timestamp > $1.timestamp }
        var order: [SignalSource] = []
        var buckets: [SignalSource: [SignalEvent]] = [:]
        for event in sorted {
            if buckets[event.source] == nil { order.append(event.source) }
            buckets[event.source, default: []].append(event)
        }
        return order.map { source in
            let group = buckets[source] ?? []
            let unread = group.filter { !readIDs.contains($0.id) }
            return SignalSourceGroup(
                source: source,
                name: name(source),
                events: group,
                unread: unread.count,
                worstUnread: unread.map(\.severity)
                    .max { severityRank($0) < severityRank($1) })
        }
    }

    /// Explicit, not `CaseIterable`'s index — see `SignalSourceRailItem.rank`.
    static func severityRank(_ severity: SignalSeverity) -> Int {
        switch severity {
        case .info: return 0
        case .success: return 1
        case .warning: return 2
        case .failure: return 3
        @unknown default: return 0
        }
    }

    /// What a screen reader says for one row.
    ///
    /// Severity FIRST, deliberately. Sighted users get it from a coloured
    /// glyph before they read a word; a listener who hears the title first has
    /// to wait to the end of the sentence to learn whether it matters. Every
    /// row previously announced only its title — the severity was carried
    /// entirely by colour and an unlabelled symbol.
    public static func accessibilityLabel(for event: SignalEvent,
                                          repeatCount: Int,
                                          isUnread: Bool,
                                          isPinned: Bool = false,
                                          now: Date) -> String {
        var parts = [event.severity.rawValue.capitalized,
                     sourceLabel(event.source),
                     event.title]
        if let body = event.body, !body.isEmpty { parts.append(body) }
        parts.append(relativeTimeSpoken(event.timestamp, now: now))
        if repeatCount > 1 { parts.append("repeated \(repeatCount) times") }
        if isPinned { parts.append("pinned") }
        // Read state last: it is the least important thing about the row and
        // the thing a listener is most likely to already know.
        parts.append(isUnread ? "unread" : "read")
        return parts.joined(separator: ", ")
    }

    /// Spoken time. `relativeTime` returns "3h", which a screen reader reads
    /// as the letter h.
    public static func relativeTimeSpoken(_ date: Date, now: Date) -> String {
        let elapsed = max(0, now.timeIntervalSince(date))
        switch elapsed {
        case ..<60: return "just now"
        case ..<3600:
            let m = Int(elapsed / 60)
            return "\(m) minute\(m == 1 ? "" : "s") ago"
        case ..<86400:
            let h = Int(elapsed / 3600)
            return "\(h) hour\(h == 1 ? "" : "s") ago"
        default:
            let d = Int(elapsed / 86400)
            return "\(d) day\(d == 1 ? "" : "s") ago"
        }
    }

    public static func sourceLabel(_ source: SignalSource) -> String {
        switch source {
        case .host: return "Ainkrad"
        case .sage: return "Sage"
        case .app(let id): return id.split(separator: ".").last.map(String.init)?.capitalized ?? id
        @unknown default: return "Ainkrad"
        }
    }
}

/// One event, in the house style: Exo 2 for prose, JetBrains Mono for the
/// readout, `ChamferShape` for every surface, and the `AinkradStatus` ramp for
/// severity. No separator lines — separation is spacing plus the elevated
/// surface on hover.
public struct SignalFeedRow: View {
    public let event: SignalEvent
    public var repeatCount: Int = 1
    public var isUnread: Bool = true
    public var now: Date = Date()
    public var onActivate: (SignalEvent) -> Void = { _ in }
    public var onAction: (SignalEvent, SignalAction) -> Void = { _, _ in }
    /// Right-click menu for this row, built by the host from the event. A
    /// closure rather than a list so the host can decide per event — the items
    /// name the source and kind, and one shared list could not.
    public var menuItems: (SignalEvent) -> [AinkradMenuItem] = { _ in [] }
    /// Kept through retention and through clearing the feed.
    public var isPinned: Bool = false
    /// Shows the body in full rather than clamped to two lines. A build error
    /// is the thing people most want out of the feed and the thing the clamp
    /// most reliably cuts in half.
    public var isExpanded: Bool = false
    /// Nil means the row cannot expand — used where there is no room for it,
    /// like the bell dropdown.
    public var onToggleExpanded: (() -> Void)?
    /// Focus driven from outside, so a LIST can move a selection with the
    /// arrow keys. The row's own `@FocusState` still lights the ring when the
    /// system moves focus by Tab; the two are OR-ed rather than fighting.
    public var isKeyboardFocused: Bool = false

    /// Explicit, because a public struct's implicit memberwise
    /// initialiser is INTERNAL — the components were public and
    /// unconstructible outside the module until this existed.
    public init(event: SignalEvent,
                repeatCount: Int = 1,
                isUnread: Bool = true,
                now: Date = Date(),
                onActivate: @escaping (SignalEvent) -> Void = { _ in },
                onAction: @escaping (SignalEvent, SignalAction) -> Void = { _, _ in }) {
        self.event = event
        self.repeatCount = repeatCount
        self.isUnread = isUnread
        self.now = now
        self.onActivate = onActivate
        self.onAction = onAction
    }

    /// A SEPARATE initialiser rather than a seventh defaulted parameter on the
    /// one above. This module builds with `-enable-library-evolution`, so
    /// adding a default changes the existing init's mangled symbol and anything
    /// already linked against it dies at `Bundle.load()` — source compiles
    /// either way, and only linking tells the truth. That is the
    /// `AinkradFormRow` failure recorded in AinkradQuest's project.yml.
    public init(event: SignalEvent,
                repeatCount: Int,
                isUnread: Bool,
                now: Date,
                onActivate: @escaping (SignalEvent) -> Void,
                onAction: @escaping (SignalEvent, SignalAction) -> Void,
                menuItems: @escaping (SignalEvent) -> [AinkradMenuItem]) {
        self.event = event
        self.repeatCount = repeatCount
        self.isUnread = isUnread
        self.now = now
        self.onActivate = onActivate
        self.onAction = onAction
        self.menuItems = menuItems
    }

    /// Separate again, for the same library-evolution reason as the one above.
    public init(event: SignalEvent,
                repeatCount: Int,
                isUnread: Bool,
                now: Date,
                onActivate: @escaping (SignalEvent) -> Void,
                onAction: @escaping (SignalEvent, SignalAction) -> Void,
                menuItems: @escaping (SignalEvent) -> [AinkradMenuItem],
                isPinned: Bool,
                isExpanded: Bool,
                onToggleExpanded: (() -> Void)?) {
        self.event = event
        self.repeatCount = repeatCount
        self.isUnread = isUnread
        self.now = now
        self.onActivate = onActivate
        self.onAction = onAction
        self.menuItems = menuItems
        self.isPinned = isPinned
        self.isExpanded = isExpanded
        self.onToggleExpanded = onToggleExpanded
    }

    /// Separate again — library evolution. See the note on the initialiser
    /// above.
    public init(event: SignalEvent,
                repeatCount: Int,
                isUnread: Bool,
                now: Date,
                onActivate: @escaping (SignalEvent) -> Void,
                onAction: @escaping (SignalEvent, SignalAction) -> Void,
                menuItems: @escaping (SignalEvent) -> [AinkradMenuItem],
                isPinned: Bool,
                isExpanded: Bool,
                onToggleExpanded: (() -> Void)?,
                isKeyboardFocused: Bool) {
        self.event = event
        self.repeatCount = repeatCount
        self.isUnread = isUnread
        self.now = now
        self.onActivate = onActivate
        self.onAction = onAction
        self.menuItems = menuItems
        self.isPinned = isPinned
        self.isExpanded = isExpanded
        self.onToggleExpanded = onToggleExpanded
        self.isKeyboardFocused = isKeyboardFocused
    }

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradStatusColors) private var statusColors
    @State private var isHovered = false
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool

    private var status: AinkradStatus { SignalPresentation.status(for: event.severity) }
    private var accent: Color { status.color(in: theme, statusColors: statusColors) }

    public var body: some View {
        HStack(alignment: .top, spacing: AinkradSpacing.sm) {
            // Its own layer: the glyph lifts on hover rather than the whole row
            // sliding as one image.
            Image(systemName: SignalPresentation.iconSymbol(for: event.severity))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accent)
                .frame(width: 16, height: 16)
                // Gated: the lift is decoration, and someone who has asked
                // for less motion has asked for exactly this to stop.
                .scaleEffect(isHovered && !reduceMotion ? 1.12 : 1)
                .offset(y: isHovered && !reduceMotion ? -1 : 0)

            VStack(alignment: .leading, spacing: AinkradSpacing.xs / 2) {
                HStack(spacing: AinkradSpacing.xs + 2) {
                    Text(event.title)
                        .font(AinkradFontResolver.font(size: 12.5, weight: isUnread ? .semibold : .regular, typography: typo))
                        .foregroundStyle(theme.foreground)
                        .lineLimit(1)
                    if repeatCount > 1 {
                        AinkradBadge(text: "×\(repeatCount)", status: status)
                    }
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8.5))
                            .foregroundStyle(theme.accentSecondary)
                    }
                    Spacer(minLength: AinkradSpacing.xs)
                    // A readout, so mono — the same language as the clock and
                    // battery in the top bar.
                    Text(SignalPresentation.relativeTime(event.timestamp, now: now))
                        .font(AinkradFontResolver.font(size: 10, weight: .medium, mono: true, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.45))
                }

                if let body = event.body, !body.isEmpty {
                    Text(body)
                        .font(AinkradFontResolver.font(size: 11.5, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.62))
                        // Expanded shows the whole thing. Two lines is right
                        // for scanning and wrong for the one case people
                        // actually need the feed for — reading a build error.
                        .lineLimit(isExpanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: AinkradSpacing.xs + 2) {
                    Text(SignalPresentation.sourceLabel(event.source))
                        .font(AinkradFontResolver.font(size: 9.5, weight: .medium, mono: true, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.45))
                        .tracking(0.4)
                    ForEach(event.actions, id: \.id) { action in
                        rowAction(action)
                    }
                }
            }

            if let onToggleExpanded, (event.body?.isEmpty == false) {
                Button(action: onToggleExpanded) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(theme.foreground.opacity(isHovered ? 0.6 : 0.3))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
                .padding(.top, 3)
            }

            // The column is always reserved, even when read: letting it
            // collapse pulled read rows' timestamps further right than unread
            // ones, so a column that should read as a straight edge zig-zagged.
            Circle()
                .fill(accent)
                .frame(width: 5, height: 5)
                .opacity(isUnread ? 1 : 0)
                .padding(.top, 6)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm + 1)
        .background(
            ChamferShape(cut: AinkradRadius.sm)
                .fill(theme.surfaceElevated.opacity(isHovered ? 0.9 : 0))
        )
        .overlay(
            ChamferShape(cut: AinkradRadius.sm)
                .strokeBorder(theme.accentSecondary.opacity(isHovered ? 0.35 : 0), lineWidth: 1)
        )
        // The focus ring is a ChamferShape, never the system ring: that is a
        // continuous rounded rectangle and reads as foreign against every
        // other surface in the app.
        .overlay(
            ChamferShape(cut: AinkradRadius.sm)
                .strokeBorder(theme.accentPrimary.opacity(
                    isFocused || isKeyboardFocused ? 0.9 : 0), lineWidth: 1.5)
        )
        // Focusable rather than wrapped in a `Button`.
        //
        // A Button would give keyboard activation for free, but the row
        // CONTAINS buttons — the inline actions — and on macOS an outer button
        // can swallow them. That is a click-through behaviour that cannot be
        // verified without a pointer, so this takes the route whose failure
        // mode is visible instead: focus and key handling explicitly, tap
        // gesture unchanged, nested actions demonstrably still their own
        // controls.
        .focusable()
        .focused($isFocused)
        .onKeyPress(.return) { onActivate(event); return .handled }
        .onKeyPress(.space) { onActivate(event); return .handled }
        .contentShape(ChamferShape(cut: AinkradRadius.sm))
        .onTapGesture { onActivate(event) }
        // One element, one sentence. Without this the row is a pile of
        // separate labels — glyph, title, body, source, "now" — read in
        // layout order, and the severity is never spoken at all.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(SignalPresentation.accessibilityLabel(
            for: event, repeatCount: repeatCount, isUnread: isUnread,
            isPinned: isPinned, now: now))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onActivate(event) }
        // The row's own actions, reachable without hunting for a button that
        // is only visible on hover.
        .accessibilityActions {
            ForEach(event.actions, id: \.id) { action in
                Button(action.label) { onAction(event, action) }
            }
            if let onToggleExpanded, event.body?.isEmpty == false {
                Button(isExpanded ? "Collapse" : "Show full message",
                       action: onToggleExpanded)
            }
        }
        .ainkradContextMenu(menuItems(event))
        .onHover { hovering in
            // The surface still changes on hover under reduce-motion — that is
            // feedback, not decoration — it simply does so without animating.
            withAnimation(reduceMotion ? nil : AinkradMotion.hover) { isHovered = hovering }
        }
    }

    /// Inline action. `AinkradButton` is the right control for a footer or a
    /// dialog, but its `AinkradSpacing.lg` padding is far too heavy for a row,
    /// so this is built from the same primitives it uses — `ChamferShape`, the
    /// spacing ramp, the brand face — rather than a raw capsule.
    private func rowAction(_ action: SignalAction) -> some View {
        let tint = action.isDestructive ? statusColors.danger : theme.accentPrimary
        return Button { onAction(event, action) } label: {
            Text(action.label)
                .font(AinkradFontResolver.font(size: 10.5, weight: .medium, typography: typo))
                .foregroundStyle(tint)
                .padding(.horizontal, AinkradSpacing.sm)
                .padding(.vertical, AinkradSpacing.xs / 2)
                .background(ChamferShape(cut: 4).fill(tint.opacity(0.14)))
                .overlay(ChamferShape(cut: 4).strokeBorder(tint.opacity(0.5), lineWidth: 1))
                .contentShape(ChamferShape(cut: 4))
        }
        .buttonStyle(.plain)
    }
}
