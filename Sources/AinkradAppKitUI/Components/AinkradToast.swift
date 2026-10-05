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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    private var color: Color {
        item.status.color(in: HostThemeTokens(skin: skin), statusColors: AinkradStatusColors(skin: skin))
    }

    var body: some View {
        let toast = skin.components.toast
        let shape = AinkradSkinShape(token: toast.shape)
        HStack(spacing: skin.spacing.sm) {
            Image(systemName: item.status.iconName)
                .font(skin.font(toast.iconFont, typography: typo))
                .foregroundStyle(color)
            Text(item.message)
                .font(skin.font(toast.bodyFont, typography: typo))
                .foregroundStyle(skin.color(toast.bodyColor))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: "xmark")
                .font(skin.font(toast.closeFont, typography: typo))
                .foregroundStyle(skin.color(toast.closeColor))
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)
        }
        .padding(.horizontal, skin.spacing.md)
        .padding(.vertical, skin.spacing.sm)
        .frame(minWidth: toast.minWidth, maxWidth: toast.maxWidth)
        .background(shape.fill(skin.color(toast.fill)))
        .overlay(
            shape.strokeBorder(
                skin.color(toast.stroke.color, tint: color), lineWidth: toast.stroke.width.resolve([]))
        )
        .shadow(color: skin.color(toast.glow.color, tint: color), radius: toast.glow.radius.resolve([]))
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
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.ainkradToastCenter, center)
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: skin.spacing.sm) {
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
                .padding(skin.spacing.lg)
                .animation(
                    reduceMotion ? nil : skin.animation(skin.motion.materializeAnimation),
                    value: center.items.map(\.id)
                )
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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    public init(message: String, status: AinkradStatus = .neutral, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.status = status
        self.onDismiss = onDismiss
    }

    private var color: Color {
        status.color(in: HostThemeTokens(skin: skin), statusColors: AinkradStatusColors(skin: skin))
    }

    public var body: some View {
        let banner = skin.components.banner
        let shape = AinkradSkinShape(token: banner.shape)
        HStack(spacing: skin.spacing.sm) {
            Image(systemName: status.iconName)
                .font(skin.font(banner.iconFont, typography: typo))
                .foregroundStyle(color)
            Text(message)
                .font(skin.font(banner.bodyFont, typography: typo))
                .foregroundStyle(skin.color(banner.bodyColor))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let onDismiss {
                Image(systemName: "xmark")
                    .font(skin.font(banner.closeFont, typography: typo))
                    .foregroundStyle(skin.color(banner.closeColor))
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onDismiss)
            }
        }
        .padding(.horizontal, skin.spacing.md)
        .padding(.vertical, skin.spacing.sm)
        .background(shape.fill(skin.color(banner.fill, tint: color)))
        .overlay(
            shape.strokeBorder(
                skin.color(banner.stroke.color, tint: color), lineWidth: banner.stroke.width.resolve([])))
    }
}
