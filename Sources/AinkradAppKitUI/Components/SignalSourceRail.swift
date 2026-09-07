import SwiftUI
import AinkradAppKitContract
import AinkradSignal

/// One entry in the feed's source rail.
public struct SignalSourceRailItem: Identifiable, Equatable {
    /// `nil` is the "All" row.
    public let source: SignalSource?
    public let name: String
    public let unread: Int
    /// The worst severity among this source's UNREAD events, for the dot.
    public let worstUnread: SignalSeverity?

    public var id: String {
        guard let source else { return "all" }
        return "\(source)"
    }

    public init(source: SignalSource?, name: String, unread: Int,
                worstUnread: SignalSeverity?) {
        self.source = source
        self.name = name
        self.unread = unread
        self.worstUnread = worstUnread
    }

    /// Builds the rail from what the feed holds.
    ///
    /// Pure, so the ordering and the severity roll-up are testable without
    /// rendering — they are the part with the decisions in them.
    public static func build(events: [SignalEvent],
                             readIDs: Set<UUID>,
                             name: (SignalSource) -> String) -> [SignalSourceRailItem] {
        var order: [SignalSource] = []
        var unread: [SignalSource: Int] = [:]
        var worst: [SignalSource: SignalSeverity] = [:]
        for event in events {
            if !order.contains(event.source) { order.append(event.source) }
            guard !readIDs.contains(event.id) else { continue }
            unread[event.source, default: 0] += 1
            // The worst UNREAD severity, not the worst overall: a failure the
            // user has already dealt with must stop colouring the dot red, or
            // the rail keeps reporting a problem that is finished.
            // Explicit nil check rather than a `?? .info` baseline: with a
            // default of `.info`, a source whose only unread event IS info
            // never records one, and its dot disappears instead of reading
            // neutral.
            if let current = worst[event.source] {
                if rank(event.severity) > rank(current) { worst[event.source] = event.severity }
            } else {
                worst[event.source] = event.severity
            }
        }
        let sources = order.sorted {
            // Loudest first, so what needs attention is at the top; then by
            // name, so a quiet list does not reshuffle every time an event
            // lands somewhere else.
            (unread[$0] ?? 0, name($1)) > (unread[$1] ?? 0, name($0))
        }
        let all = SignalSourceRailItem(
            source: nil, name: "All",
            unread: unread.values.reduce(0, +),
            worstUnread: worst.values.max(by: { rank($0) < rank($1) }))
        return [all] + sources.map {
            SignalSourceRailItem(source: $0, name: name($0),
                                 unread: unread[$0] ?? 0, worstUnread: worst[$0])
        }
    }

    /// Explicit, not `CaseIterable`'s index: that is a declaration detail and
    /// must not silently become the severity order.
    static func rank(_ severity: SignalSeverity) -> Int {
        switch severity {
        case .info: return 0
        case .success: return 1
        case .warning: return 2
        case .failure: return 3
        @unknown default: return 0
        }
    }
}

/// The feed's left-hand rail: which app is talking, how much, and how badly.
///
/// Replaces the source filter chips, which do not scale past about four apps
/// and have nowhere to put a count.
public struct SignalSourceRail: View {
    public let items: [SignalSourceRailItem]
    @Binding public var selection: SignalSource?
    public var onConfigure: (SignalSource) -> Void = { _ in }

    public init(items: [SignalSourceRailItem],
                selection: Binding<SignalSource?>,
                onConfigure: @escaping (SignalSource) -> Void = { _ in }) {
        self.items = items
        self._selection = selection
        self.onConfigure = onConfigure
    }

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var status
    @Environment(\.ainkradTypography) private var typo

    public var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(items) { item in
                SignalSourceRailRow(item: item,
                                    isSelected: selection == item.source,
                                    onSelect: { selection = item.source },
                                    onConfigure: onConfigure)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, AinkradSpacing.xs + 2)
        .padding(.horizontal, AinkradSpacing.xs + 2)
        .frame(width: 168)
    }

    /// The count and the severity are a coloured dot and a small number —
    /// both invisible to a listener, and both the reason the rail exists.
    static func label(for item: SignalSourceRailItem) -> String {
        var parts = [item.name]
        if item.unread > 0 {
            parts.append("\(item.unread) unread")
            if let worst = item.worstUnread {
                parts.append("worst \(worst.rawValue)")
            }
        } else {
            parts.append("nothing unread")
        }
        return parts.joined(separator: ", ")
    }

}

/// One rail row, split out so it can own its own hover state — a rail of ten
/// sources cannot share one `isHovered` without every row lighting up at once.
private struct SignalSourceRailRow: View {
    let item: SignalSourceRailItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onConfigure: (SignalSource) -> Void

    @State private var isHovered = false
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var status
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// Selected wins over hovered: a hover tint on the selected row would make
    /// selection ambiguous exactly while the pointer is on it.
    private var fillOpacity: Double {
        if isSelected { return 0.9 }
        return isHovered ? 0.45 : 0
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AinkradSpacing.xs + 2) {
                Circle()
                    .fill(item.worstUnread.map {
                        SignalPresentation.status(for: $0).color(in: theme, statusColors: status)
                    } ?? .clear)
                    .frame(width: 5, height: 5)
                Text(item.name)
                    .font(AinkradFontResolver.font(size: 11.5,
                                                   weight: isSelected ? .semibold : .regular,
                                                   typography: typo))
                    .foregroundStyle(theme.foreground
                        .opacity(isSelected ? 1 : (isHovered ? 0.9 : 0.72)))
                    .lineLimit(1)
                Spacer(minLength: AinkradSpacing.xs)
                if item.unread > 0 {
                    // Mono and digit-locked: the counts form a column, and a
                    // proportional face makes that column wobble.
                    Text(item.unread > 99 ? "99+" : "\(item.unread)")
                        .font(AinkradFontResolver.font(size: 9.5, weight: .medium,
                                                       mono: true, typography: typo))
                        .monospacedDigit()
                        .foregroundStyle(theme.foreground.opacity(0.5))
                }
            }
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs + 1)
            .background(
                ChamferShape(cut: AinkradRadius.sm)
                    .fill(theme.surfaceElevated.opacity(fillOpacity)))
            .overlay(alignment: .leading) {
                // An accent edge, not a separator — the design language forbids
                // rules, and selection still has to read instantly.
                //
                // Always present, scaled to nothing when unselected, so the
                // marker GROWS into place as selection moves down the rail
                // rather than blinking out of one row and into another.
                Capsule().fill(theme.accentSecondary)
                    .frame(width: 2)
                    .padding(.vertical, 4)
                    .scaleEffect(y: isSelected ? 1 : 0, anchor: .center)
                    .opacity(isSelected ? 1 : 0)
            }
            .contentShape(ChamferShape(cut: AinkradRadius.sm))
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: isHovered)
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: isSelected)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(SignalSourceRail.label(for: item))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .ainkradContextMenu(item.source.map { source in
            [AinkradMenuItem(title: "Notification settings\u{2026}", systemName: "slider.horizontal.3",
                             action: { onConfigure(source) })]
        } ?? [])
    }
}
