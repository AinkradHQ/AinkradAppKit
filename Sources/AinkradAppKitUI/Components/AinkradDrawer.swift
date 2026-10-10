import AinkradAppKitContract
import SwiftUI

/// Chamfer side drawer sliding in from `edge`, scoped to the host surface it's
/// attached to (same scoped-overlay approach as `.ainkradConfirmDialog` /
/// `.ainkradSheet`): dim behind, slide + materialize gated on
/// `ainkradReduceMotion`, dismiss on scrim tap or Esc.
private struct AinkradDrawerModifier<DrawerContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var edge: Edge
    var width: CGFloat
    @ViewBuilder var drawerContent: () -> DrawerContent

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let drawer = skin.components.drawer
        content.overlay {
            if isPresented {
                ZStack(alignment: alignment) {
                    skin.color(drawer.scrimColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { isPresented = false }

                    drawerContent()
                        .padding(skin.spacing.lg)
                        .frame(width: width)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .ainkradPanel(showsBrackets: !skin.usesNativeGlass)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .move(edge: edge).combined(with: .opacity)
                        )

                    Button("") { isPresented = false }
                        .keyboardShortcut(.escape, modifiers: [])
                        .opacity(0)
                        .frame(width: 0, height: 0)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(
                    reduceMotion ? nil : skin.animation(skin.motion.materializeAnimation), value: isPresented)
            }
        }
    }

    private var alignment: Alignment {
        switch edge {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        }
    }
}

extension View {
    /// Presents a chamfer side drawer sliding in from `edge`, scoped to THIS
    /// view's own bounds. Dim behind, slide/materialize gated on
    /// `ainkradReduceMotion`, dismiss on scrim tap or Esc.
    public func ainkradDrawer<DrawerContent: View>(
        isPresented: Binding<Bool>,
        edge: Edge = .leading,
        width: CGFloat = 280,
        @ViewBuilder content: @escaping () -> DrawerContent
    ) -> some View {
        modifier(AinkradDrawerModifier(isPresented: isPresented, edge: edge, width: width, drawerContent: content))
    }
}
