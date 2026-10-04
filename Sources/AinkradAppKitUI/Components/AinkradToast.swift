import AinkradAppKitContract
import Foundation
import Observation
import SwiftUI

/// A single queued toast — identity, message, status color, and the instant
/// it should auto-dismiss.
public struct AinkradToastItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var message: String
    public var status: AinkradStatus
    public var expiresAt: Date

    public init(id: UUID = UUID(), message: String, status: AinkradStatus, expiresAt: Date) {
        self.id = id
        self.message = message
        self.status = status
        self.expiresAt = expiresAt
    }
}

/// Appends `item` to the end of `queue`. Pure — unit-testable without
/// touching the observable center or a timer.
public func toastQueueAdding(_ item: AinkradToastItem, to queue: [AinkradToastItem]) -> [AinkradToastItem] {
    queue + [item]
}

/// Drops every item whose `expiresAt` is at or before `now`. Pure —
/// `AinkradToastCenter`'s expiry sweep, unit-testable with an explicit clock.
public func toastQueueExpiring(_ queue: [AinkradToastItem], now: Date) -> [AinkradToastItem] {
    queue.filter { $0.expiresAt > now }
}

/// Observable toast queue, injected via `\.ainkradToastCenter`. Call `show`
/// from anywhere in the environment; `.ainkradToastHost()` renders the stack.
@MainActor
@Observable
public final class AinkradToastCenter {
    public private(set) var items: [AinkradToastItem] = []

    /// Nonisolated so `@Entry`'s default-value expression (evaluated outside
    /// the main actor at `EnvironmentValues` init time) can construct one;
    /// the body touches no actor-isolated state.
    public nonisolated init() {}

    /// Enqueues a toast that auto-dismisses after `duration` seconds.
    public func show(_ message: String, status: AinkradStatus = .neutral, duration: TimeInterval = 3) {
        let item = AinkradToastItem(message: message, status: status, expiresAt: Date().addingTimeInterval(duration))
        items = toastQueueAdding(item, to: items)
        DispatchQueue.main.asyncAfter(deadline: .now() + max(duration, 0)) { [weak self] in
            self?.dismiss(item.id)
        }
    }

    /// Removes a toast immediately (e.g. a manual dismiss tap).
    public func dismiss(_ id: AinkradToastItem.ID) {
        items = items.filter { $0.id != id }
    }
}

extension EnvironmentValues {
    @Entry public var ainkradToastCenter: AinkradToastCenter = AinkradToastCenter()
}

/// A single toast bubble — chamfer chip with a status-colored icon, tuned to
/// stack in `AinkradToastHostModifier`'s top-right column.
private struct AinkradToastView: View {
    let item: AinkradToastItem
    let onDismiss: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradTypography) private var typo

    private var color: Color { item.status.color(in: theme, statusColors: statusColors) }

    var body: some View {
        HStack(spacing: AinkradSpacing.sm) {
            Image(systemName: item.status.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            Text(item.message)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(theme.foreground.opacity(0.5))
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .frame(minWidth: 220, maxWidth: 340)
        .background(ChamferShape(cut: 8).fill(theme.surfaceElevated.opacity(0.92)))
        .overlay(ChamferShape(cut: 8).strokeBorder(color.opacity(0.6), lineWidth: 1.25))
        .shadow(color: color.opacity(0.4), radius: 6)
    }
}

private struct AinkradToastHostModifier: ViewModifier {
    /// Owned by this modifier instance (stable across re-renders via
    /// `@State`) and re-injected into `\.ainkradToastCenter` for `content`
    /// below, so every descendant that reads the environment — including
    /// whatever calls `.show(...)` — shares the SAME center this modifier
    /// renders from. Without the re-injection, `.show(...)` callers would
    /// read `\.ainkradToastCenter`'s environment default fresh (a distinct
    /// instance each time, since nothing above ever set a concrete one) and
    /// mutate a center this modifier never renders.
    @State private var center = AinkradToastCenter()
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.ainkradToastCenter, center)
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: AinkradSpacing.sm) {
                    ForEach(center.items) { item in
                        AinkradToastView(item: item) { center.dismiss(item.id) }
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .opacity
                                    )
                            )
                    }
                }
                .padding(AinkradSpacing.lg)
                .animation(reduceMotion ? nil : AinkradMotion.materialize, value: center.items.map(\.id))
                .allowsHitTesting(!center.items.isEmpty)
            }
    }
}

extension View {
    /// Renders the `\.ainkradToastCenter` queue as a materializing, top-right
    /// stack overlaid on this view. Mount once near the root of a window.
    public func ainkradToastHost() -> some View {
        modifier(AinkradToastHostModifier())
    }
}

extension AinkradStatus {
    fileprivate var iconName: String {
        switch self {
        case .neutral: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .danger: return "xmark.octagon"
        }
    }
}

/// Inline chamfer alert banner — status color + icon, no divider line, with
/// an optional dismiss affordance.
public struct AinkradBanner: View {
    private let message: String
    private let status: AinkradStatus
    private let onDismiss: (() -> Void)?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradTypography) private var typo

    public init(message: String, status: AinkradStatus = .neutral, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.status = status
        self.onDismiss = onDismiss
    }

    private var color: Color { status.color(in: theme, statusColors: statusColors) }

    public var body: some View {
        HStack(spacing: AinkradSpacing.sm) {
            Image(systemName: status.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            Text(message)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let onDismiss {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.foreground.opacity(0.5))
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onDismiss)
            }
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 8).fill(color.opacity(0.12)))
        .overlay(ChamferShape(cut: 8).strokeBorder(color.opacity(0.5), lineWidth: 1.25))
    }
}
