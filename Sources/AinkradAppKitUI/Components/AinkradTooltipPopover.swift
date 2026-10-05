import AinkradAppKitContract
import SwiftUI

/// Fades + scales content in on appear, then holds steady — the shared
/// "materialize" look for content hosted in a top-level floating panel (a
/// SwiftUI `.transition` doesn't apply once content lives in its own
/// `NSPanel`, so this drives the same look via plain `@State` + `onAppear`).
/// Skips the animation under Reduce Motion.
private struct AinkradFloatingMaterialize<Content: View>: View {
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var appeared = false
    private let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        let mat = skin.roles.materialize
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : mat.scale, anchor: .top)
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(skin.animation(mat.animation)) { appeared = true }
                }
            }
    }
}

/// The shared chamfer "bubble" chrome for tooltips and popovers: surface
/// fill, luminous accent stroke, drop shadow. Sized to its content.
private struct AinkradBubbleChrome<Content: View>: View {
    let content: Content
    @Environment(\.ainkradSkin) private var skin
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        let bubble = skin.roles.bubble
        let shape = AinkradSkinShape(token: bubble.shape)
        content
            .background(shape.fill(skin.color(bubble.fill)))
            .overlay(shape.strokeBorder(skin.color(bubble.stroke.color), lineWidth: bubble.stroke.width.resolve([])))
            .shadow(color: skin.color(bubble.shadow.color), radius: bubble.shadow.radius, y: bubble.shadow.y)
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

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false
    @State private var visible = false

    func body(content: Content) -> some View {
        let tt = skin.components.tooltipPopover
        content
            .onHover { isHovering in
                hovering = isHovering
                guard isHovering else {
                    visible = false
                    return
                }
                let delay = reduceMotion ? 0 : tt.showDelay
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if hovering { visible = true }
                }
            }
            .ainkradFloatingPanel(isPresented: $visible, maxHeight: tt.tooltipMaxHeight) {
                AinkradFloatingMaterialize {
                    AinkradBubbleChrome {
                        Text(text)
                            .font(skin.font(tt.textFont, typography: typo))
                            .foregroundStyle(skin.color(tt.textColor))
                            .padding(.horizontal, skin.spacing.sm)
                            .padding(.vertical, skin.spacing.xs)
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
    @Environment(\.ainkradSkin) private var skin

    public init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> PopoverContent) {
        self._isPresented = isPresented
        self.popoverContent = content
    }

    public func body(content: Content) -> some View {
        let tt = skin.components.tooltipPopover
        content.ainkradFloatingPanel(isPresented: $isPresented, maxHeight: tt.popoverMaxHeight) {
            AinkradFloatingMaterialize {
                AinkradBubbleChrome {
                    popoverContent()
                        .padding(skin.spacing.md)
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
