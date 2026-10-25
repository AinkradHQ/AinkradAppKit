import Observation
import SwiftUI

/// One button on an `AinkradRichToast` (Undo, Open, Allow once…).
public struct AinkradRichToastAction: Identifiable {
    public let id = UUID()
    public let title: String
    public let run: @MainActor () -> Void

    public init(_ title: String, run: @escaping @MainActor () -> Void) {
        self.title = title
        self.run = run
    }
}

/// A toast with a tinted glyph (or any icon view, e.g. an agent figure), a title and a body, optional actions, and a
/// lifetime ring that drains around the icon and pauses while hovered. A toast with `onOpen` is tappable as a whole.
public struct AinkradRichToast: Identifiable {
    public let id = UUID()
    public var title: String
    public var body: String?
    public var status: AinkradStatus
    /// Replaces the tinted glyph; sized by the caller (28 pt fits).
    public var icon: AnyView?
    public var actions: [AinkradRichToastAction]
    public var onOpen: (@MainActor () -> Void)?
    public var lifetime: TimeInterval

    public init(
        title: String, body: String? = nil, status: AinkradStatus = .neutral, icon: AnyView? = nil,
        actions: [AinkradRichToastAction] = [], lifetime: TimeInterval = 5.2, onOpen: (@MainActor () -> Void)? = nil
    ) {
        self.title = title
        self.body = body
        self.status = status
        self.icon = icon
        self.actions = actions
        self.lifetime = lifetime
        self.onOpen = onOpen
    }
}

/// The toasts a window is showing, newest first, at most `limit`.
@MainActor @Observable
public final class AinkradRichToastCenter {
    public private(set) var items: [AinkradRichToast] = []
    public var limit = 4

    public init() {}

    public func show(_ toast: AinkradRichToast) {
        items.insert(toast, at: 0)
        if items.count > limit { items.removeLast(items.count - limit) }
    }

    public func dismiss(_ id: UUID) { items.removeAll { $0.id == id } }
}

/// The stack itself; place it top-trailing inside the window (`.overlay(alignment: .topTrailing)`).
public struct AinkradRichToastStack: View {
    private let center: AinkradRichToastCenter
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(center: AinkradRichToastCenter) { self.center = center }

    public var body: some View {
        VStack(alignment: .trailing, spacing: skin.size.s8) {
            ForEach(center.items) { toast in
                RichToastCard(toast: toast) { center.dismiss(toast.id) }
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .offset(y: -skin.size.s18).combined(with: .scale(scale: 0.92))
                                    .combined(with: .opacity),
                                removal: .offset(x: skin.size.s40).combined(with: .scale(scale: 0.96))
                                    .combined(with: .opacity)))
            }
        }
        .frame(width: skin.size.s340, alignment: .trailing)
        .padding(.top, skin.size.s14)
        .padding(.trailing, skin.size.s16)
        .animation(
            reduceMotion ? nil : skin.animation(AinkradAnimationToken(curve: "spring", response: 0.5, damping: 0.72)),
            value: center.items.map(\.id))
    }
}

private struct RichToastCard: View {
    let toast: AinkradRichToast
    let dismiss: () -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var elapsed: TimeInterval = 0

    private var tint: Color {
        switch toast.status {
        case .neutral: skin.color(skin.palette.accentPrimary)
        case .success: skin.color(skin.palette.success)
        case .warning: skin.color(skin.palette.warning)
        case .danger: skin.color(skin.palette.danger)
        }
    }

    private var glyph: String {
        switch toast.status {
        case .neutral: "info"
        case .success: "checkmark"
        case .warning: "exclamationmark"
        case .danger: "xmark"
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s14, style: .continuous)
        HStack(alignment: .center, spacing: skin.size.s10) {
            iconSlot
            VStack(alignment: .leading, spacing: skin.size.s2) {
                Text(toast.title)
                    .font(skin.font(AinkradFontToken(sizeKey: "t12_5", weight: "semibold"), typography: typo))
                    .foregroundStyle(skin.color(skin.text.primary))
                if let body = toast.body {
                    Text(body).font(skin.font(AinkradFontToken(sizeKey: "t12"), typography: typo))
                        .foregroundStyle(skin.color(skin.text.muted)).lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(toast.actions) { action in
                Button {
                    action.run()
                    dismiss()
                } label: {
                    Text(action.title)
                        .font(skin.font(AinkradFontToken(sizeKey: "t11", weight: "semibold"), typography: typo))
                        .foregroundStyle(tint)
                        .padding(.horizontal, skin.size.s10)
                        .frame(height: skin.size.s26)
                        .background(tint.opacity(skin.opacity.o14), in: RoundedRectangle(cornerRadius: skin.size.s8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, skin.size.s9)
        .padding(.leading, skin.size.s9)
        .padding(.trailing, skin.size.s32)
        .background {
            ZStack(alignment: .topLeading) {
                shape.fill(skin.color(.palette("background", skin.opacity.o92)))
                RadialGradient(
                    colors: [tint.opacity(skin.opacity.o22), .clear], center: .topLeading, startRadius: 0,
                    endRadius: skin.size.s140
                )
                .clipShape(shape)
            }
        }
        .overlay(shape.strokeBorder(skin.color(.palette("foreground", skin.opacity.o08)), lineWidth: 1))
        .overlay(alignment: .topTrailing) {
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(skin.font(AinkradFontToken(sizeKey: "t10", weight: "semibold"), typography: typo))
                    .foregroundStyle(skin.color(skin.text.muted))
                    .frame(width: skin.size.s22, height: skin.size.s22)
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .padding(skin.size.s6)
        }
        .shadow(color: skin.color(.palette("black", skin.opacity.o40)), radius: skin.size.s20, y: skin.size.s16)
        .contentShape(shape)
        .onTapGesture {
            guard let open = toast.onOpen else { return }
            open()
            dismiss()
        }
        .offset(y: hovering && toast.onOpen != nil && !reduceMotion ? -1 : 0)
        .onHover { hovering = $0 }
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .task {
            // The lifetime clock only runs while the pointer is away.
            let step: TimeInterval = 0.05
            while elapsed < toast.lifetime {
                try? await Task.sleep(for: .milliseconds(Int(step * 1000)))
                if Task.isCancelled { return }
                if !hovering { elapsed += step }
            }
            dismiss()
        }
    }

    private var iconSlot: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: max(0, 1 - elapsed / toast.lifetime))
                .stroke(tint.opacity(skin.opacity.o60), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let icon = toast.icon {
                icon
            } else {
                Image(systemName: glyph)
                    .font(skin.font(AinkradFontToken(sizeKey: "t12", weight: "bold"), typography: typo))
                    .foregroundStyle(tint)
                    .frame(width: skin.size.s26, height: skin.size.s26)
                    .background(tint.opacity(skin.opacity.o16), in: RoundedRectangle(cornerRadius: skin.size.s8))
            }
        }
        .frame(width: skin.size.s34, height: skin.size.s34)
    }
}
