import AinkradAppKitContract
import SwiftUI

/// Fades + scales content in on appear, then holds steady — the shared
/// "materialize" look for content hosted in a top-level floating panel (a
/// SwiftUI `.transition` doesn't apply once content lives in its own
/// `NSPanel`, so this drives the same look via plain `@State` + `onAppear`).
/// Skips the animation under Reduce Motion.
private struct AinkradFloatingMaterialize<Content: View>: View {
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var appeared = false
    private let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.96, anchor: .top)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(AinkradMotion.materialize) { appeared = true }
                }
            }
    }
}

/// The shared chamfer "bubble" chrome for tooltips and popovers: surface
/// fill, luminous accent stroke, drop shadow. Sized to its content.
private struct AinkradBubbleChrome<Content: View>: View {
    let content: Content
    @Environment(\.ainkradTheme) private var theme
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.97)))
            .overlay(ChamferShape(cut: 6).strokeBorder(theme.accentSecondary.opacity(0.55), lineWidth: 1.25))
            .shadow(color: theme.accentSecondary.opacity(0.35), radius: 8, y: 3)
    }
}

/// Hover-delayed HUD tooltip bubble, presented through `AinkradFloatingPanel`
/// (top-level, not a plain in-view `.overlay`) so it is always fully
/// visible — `floatingPanelFrame` flips it above/below the anchor and clamps
/// it inside the screen's visible frame, instead of clipping at a window
/// edge the way an `.overlay` anchored near the trigger would. Appears after
/// a short hover delay and materializes in; skipped instantly (no
/// delay/animation) under Reduce Motion.
private struct AinkradTooltipModifier: ViewModifier {
    let text: String

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .onHover { isHovering in
                hovering = isHovering
                guard isHovering else {
                    visible = false
                    return
                }
                let delay = reduceMotion ? 0 : 0.45
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if hovering { visible = true }
                }
            }
            .ainkradFloatingPanel(isPresented: $visible, maxHeight: 160) {
                AinkradFloatingMaterialize {
                    AinkradBubbleChrome {
                        Text(text)
                            .font(AinkradFontResolver.font(.caption, typography: typo))
                            .foregroundStyle(theme.foreground.opacity(0.9))
                            .padding(.horizontal, AinkradSpacing.sm)
                            .padding(.vertical, AinkradSpacing.xs)
                    }
                }
                .fixedSize()
                .allowsHitTesting(false)
            }
    }
}

extension View {
    /// Attaches a hover-delayed Cardinal HUD tooltip bubble above this view.
    public func ainkradTooltip(_ text: String) -> some View {
        modifier(AinkradTooltipModifier(text: text))
    }
}

/// Custom anchored popover — presents `content` in a top-level, custom-drawn
/// floating panel via `AinkradFloatingPanel` (never the system `.popover`),
/// wrapped in the shared chamfer bubble chrome and materialize-in look.
/// Reuses the floating panel's positioning/dismiss (Esc, outside click,
/// parent window losing key/moving).
public struct AinkradPopover<PopoverContent: View>: ViewModifier {
    @Binding private var isPresented: Bool
    private let popoverContent: () -> PopoverContent

    public init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> PopoverContent) {
        self._isPresented = isPresented
        self.popoverContent = content
    }

    public func body(content: Content) -> some View {
        content.ainkradFloatingPanel(isPresented: $isPresented, maxHeight: 420) {
            AinkradFloatingMaterialize {
                AinkradBubbleChrome {
                    popoverContent()
                        .padding(AinkradSpacing.md)
                }
            }
        }
    }
}

extension View {
    /// Presents `content` as a custom, anchored Cardinal HUD popover (via
    /// `AinkradFloatingPanel` — never the system `.popover`).
    public func ainkradPopover<PopoverContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> PopoverContent
    ) -> some View {
        modifier(AinkradPopover(isPresented: isPresented, content: content))
    }
}
