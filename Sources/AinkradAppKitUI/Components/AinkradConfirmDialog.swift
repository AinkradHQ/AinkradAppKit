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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo

    @ViewBuilder var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            nativeBody
        } else {
            kitBody
        }
    }

    /// Glass on macOS 26+: a macOS alert — bold title, secondary message,
    /// Return confirms and Esc cancels, on the panel's glass.
    @available(macOS 26, *)
    private var nativeBody: some View {
        VStack(alignment: .leading, spacing: skin.spacing.md) {
            Text(title).font(.headline)
            Text(message).font(.callout).foregroundStyle(.secondary)
            HStack(spacing: skin.spacing.sm) {
                Spacer(minLength: 0)
                AinkradButton(title: "Cancel", style: .secondary, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                AinkradButton(title: confirmTitle, style: isDestructive ? .danger : .primary) {
                    onConfirm()
                    onCancel()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(skin.spacing.lg)
        .frame(maxWidth: skin.components.confirmDialog.maxWidth)
        .ainkradPanel()
    }

    private var kitBody: some View {
        let dialog = skin.components.confirmDialog
        return VStack(alignment: .leading, spacing: skin.spacing.md) {
            Text(skin.labelCased(title))
                .font(skin.font(dialog.titleFont, typography: typo))
                .tracking(dialog.titleFont.tracking ?? 0)
                .foregroundStyle(skin.color(skin.text.primary))
            Text(message)
                .font(skin.font(dialog.messageFont, typography: typo))
                .foregroundStyle(skin.color(dialog.messageColor))
            HStack(spacing: skin.spacing.sm) {
                Spacer(minLength: 0)
                AinkradButton(title: "Cancel", style: .ghost, action: onCancel)
                AinkradButton(title: confirmTitle, style: isDestructive ? .danger : .primary) {
                    onConfirm()
                    onCancel()
                }
            }
        }
        .padding(skin.spacing.lg)
        .frame(maxWidth: dialog.maxWidth)
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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let dialog = skin.components.confirmDialog
        let scrim = skin.roles.scrim
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
                        AinkradMaterialBackground(level: .panel, blending: .withinWindow)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(scrim.opacity)
                        skin.color(scrim.color)
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
                                : .scale(scale: dialog.transitionScale, anchor: .center).combined(with: .opacity)
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(
                        reduceMotion ? nil : skin.animation(skin.motion.materializeAnimation), value: isPresented)
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
