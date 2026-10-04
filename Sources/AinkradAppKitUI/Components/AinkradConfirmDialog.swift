import AinkradAppKitContract
import SwiftUI

/// Confirm/cancel dialog card — a chamfer panel with a title, message, and
/// Cancel/confirm `AinkradButton` actions (destructive requests render the
/// confirm action in `.danger`). This is the visual content only; presentation
/// (dim scrim + centering, scoped to the calling component) is handled by
/// `View.ainkradConfirmDialog(...)`, the public entry point.
struct AinkradConfirmDialogCard: View {
    let title: String
    let message: String
    let confirmTitle: String
    let isDestructive: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.md) {
            Text(title.uppercased())
                .font(AinkradFontResolver.font(.headline, weight: .semibold, typography: typo))
                .tracking(0.6)
                .foregroundStyle(theme.foreground)
            Text(message)
                .font(AinkradFontResolver.font(.body, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.75))
            HStack(spacing: AinkradSpacing.sm) {
                Spacer(minLength: 0)
                AinkradButton(title: "Cancel", style: .ghost, action: onCancel)
                AinkradButton(title: confirmTitle, style: isDestructive ? .danger : .primary) {
                    onConfirm()
                    onCancel()
                }
            }
        }
        .padding(AinkradSpacing.lg)
        .frame(maxWidth: 360)
        .ainkradPanel(showsBrackets: true)
    }
}

private struct AinkradConfirmDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let confirmTitle: String
    let isDestructive: Bool
    let onConfirm: () -> Void

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        // Dim + subtle blur filling THIS container's own full
                        // bounds — no full-window cover. The explicit frame
                        // ensures the scrim fills+centers within the host
                        // view even when that host is small/compact. The
                        // blur is intentionally light (panel-level material)
                        // so it reads as depth, not a heavy frosted cover.
                        VisualEffectBlur(level: .panel, blendingMode: .withinWindow)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(0.6)
                        Color.black.opacity(0.45)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture { isPresented = false }

                        AinkradConfirmDialogCard(
                            title: title,
                            message: message,
                            confirmTitle: confirmTitle,
                            isDestructive: isDestructive,
                            onCancel: { isPresented = false },
                            onConfirm: onConfirm
                        )
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .scale(scale: 0.94, anchor: .center).combined(with: .opacity)
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(reduceMotion ? nil : AinkradMotion.materialize, value: isPresented)
                }
            }
    }
}

extension View {
    /// Presents a confirm/cancel dialog scoped to THIS view's own bounds — a
    /// dim scrim (`Color.black.opacity(0.45)`) plus a subtle panel-level
    /// blur filling the modified view's container, with the chamfer dialog
    /// card centered within it. Unlike a window-level modal, this never
    /// covers content outside the component/container it's attached to.
    ///
    /// Attach at your app/surface root — the dialog centers within, and
    /// dims, the view it modifies. Attaching it to a small inner container
    /// will scope the dim+center to that small box instead of the full app.
    ///
    /// Tapping the scrim or Cancel dismisses; Confirm runs `onConfirm` then
    /// dismisses. `isDestructive` renders the confirm action in `.danger`.
    public func ainkradConfirmDialog(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Confirm",
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            AinkradConfirmDialogModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                isDestructive: isDestructive,
                onConfirm: onConfirm
            ))
    }
}
