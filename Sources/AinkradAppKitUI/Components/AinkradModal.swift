import AinkradAppKitContract
import SwiftUI

/// Centered chamfer modal, scoped to the host surface it's attached to —
/// mirrors `.ainkradConfirmDialog`'s scoped-overlay approach (dim + subtle
/// blur filling THIS view's own bounds, never a full-window cover), but
/// hosts arbitrary content instead of a fixed title/message/buttons layout.
/// Dismisses on scrim tap or Esc; materialize/scale transition gated on
/// `ainkradReduceMotion`.
/// Sizing facts about `.ainkradModal`, published because callers cannot see
/// them and have repeatedly guessed wrong.
///
/// `.ainkradModal` pads its content by `AinkradSpacing.lg` and THEN caps the
/// padded result at `maxWidth`, so the budget a caller actually gets is
/// `contentWidth`, not `maxWidth`. Content laid out at `maxWidth` overflows the
/// cap and the panel border is drawn over it. The behaviour is kept for source
/// and visual compatibility — every existing modal in every app is laid out
/// against it — so the numbers are exposed instead of changed.
///
/// Prefer `.ainkradModal(isPresented:contentWidth:content:)` in new code, where
/// the width you pass is the width your content gets.
public enum AinkradModalMetrics {
    /// Outer cap applied to content + the modifier's own padding.
    public static let maxWidth: CGFloat = 480
    /// What content is actually offered under `.ainkradModal` — `maxWidth`
    /// minus the modifier's padding on both edges.
    public static let contentWidth: CGFloat = maxWidth - 2 * AinkradSpacing.lg
}

private struct AinkradModalModifier<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    /// When non-nil, this is the width offered to CONTENT, and the modifier's
    /// padding is added outside it — the honest arrangement. When nil the
    /// historical layout applies: pad first, then cap the padded result at
    /// `AinkradModalMetrics.maxWidth`.
    var contentWidth: CGFloat?
    @ViewBuilder var modalContent: () -> ModalContent

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    VisualEffectBlur(level: .panel, blendingMode: .withinWindow)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .opacity(0.6)
                    Color.black.opacity(0.45)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { isPresented = false }

                    sizedContent
                        .ainkradPanel(showsBrackets: true)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .scale(scale: 0.94, anchor: .center).combined(with: .opacity)
                        )

                    dismissKey
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(reduceMotion ? nil : AinkradMotion.materialize, value: isPresented)
            }
        }
    }

    /// The one place the two layouts differ. Order is the whole distinction:
    /// cap-then-pad gives content the width that was asked for; pad-then-cap
    /// spends part of it on the modifier's own chrome.
    @ViewBuilder private var sizedContent: some View {
        if let contentWidth {
            modalContent()
                .frame(maxWidth: contentWidth)
                .padding(AinkradSpacing.lg)
        } else {
            modalContent()
                .padding(AinkradSpacing.lg)
                .frame(maxWidth: AinkradModalMetrics.maxWidth)
        }
    }

    /// Invisible Esc-key dismiss affordance — a real (custom-drawn, zero-size,
    /// zero-opacity) `Button` rather than any native menu/shortcut chrome, so
    /// pressing Esc while this scoped overlay is key dismisses it.
    private var dismissKey: some View {
        Button("") { isPresented = false }
            .keyboardShortcut(.escape, modifiers: [])
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}

/// Chamfer sheet sliding in from `edge`, scoped to the host surface —
/// dim behind, materialize + slide gated on `ainkradReduceMotion`, dismiss on
/// scrim tap or Esc.
private struct AinkradSheetModifier<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var edge: Edge
    @ViewBuilder var sheetContent: () -> SheetContent

    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack(alignment: alignment) {
                    Color.black.opacity(0.45)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { isPresented = false }

                    sheetContent()
                        .padding(AinkradSpacing.lg)
                        .frame(maxWidth: isHorizontalEdge ? .infinity : 360)
                        .ainkradPanel(showsBrackets: true)
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
                .animation(reduceMotion ? nil : AinkradMotion.materialize, value: isPresented)
            }
        }
    }

    /// `.top`/`.bottom` sheets span the host's width; `.leading`/`.trailing`
    /// are fixed-width side sheets.
    private var isHorizontalEdge: Bool { edge == .top || edge == .bottom }

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
    /// Presents a centered chamfer modal scoped to THIS view's own bounds,
    /// mirroring `.ainkradConfirmDialog`'s dim+blur scrim. Content is
    /// arbitrary — supply your own layout/buttons. Tapping the scrim or Esc
    /// dismisses (set `isPresented` false); the caller decides what else
    /// dismissing does.
    ///
    /// Note the sizing, which is not what it looks like: content is padded by
    /// `AinkradSpacing.lg` and the PADDED result is capped at
    /// `AinkradModalMetrics.maxWidth`, so content is offered
    /// `AinkradModalMetrics.contentWidth` (448), not 480. Size content against
    /// that constant, or use the `contentWidth:` overload below, where the
    /// width you pass is the width your content gets.
    public func ainkradModal<ModalContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        modifier(
            AinkradModalModifier(
                isPresented: isPresented, contentWidth: nil,
                modalContent: content))
    }

    /// Presents a centered chamfer modal whose CONTENT is capped at
    /// `contentWidth`, with the modal's own padding added outside it.
    ///
    /// The distinction from `ainkradModal(isPresented:content:)` is only the
    /// order of padding and capping, and it is the whole point: there, the cap
    /// includes the modifier's chrome and content silently gets 32pt less than
    /// the number in the call. Here the number means what it says.
    ///
    /// A separate entry point rather than a change to the original: every
    /// existing modal across the host and the plugin apps is laid out against
    /// the old arithmetic, and reordering it would move all of them 32pt wider
    /// at once. `contentWidth` is non-defaulted, so this is also a distinct
    /// mangled symbol and no shipped binary's call is affected.
    public func ainkradModal<ModalContent: View>(
        isPresented: Binding<Bool>,
        contentWidth: CGFloat,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        modifier(
            AinkradModalModifier(
                isPresented: isPresented, contentWidth: contentWidth,
                modalContent: content))
    }

    /// Presents a chamfer sheet sliding in from `edge`, scoped to THIS view's
    /// own bounds. Dim behind, slide/materialize gated on
    /// `ainkradReduceMotion`, dismiss on scrim tap or Esc.
    public func ainkradSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        edge: Edge = .bottom,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(AinkradSheetModifier(isPresented: isPresented, edge: edge, sheetContent: content))
    }
}
