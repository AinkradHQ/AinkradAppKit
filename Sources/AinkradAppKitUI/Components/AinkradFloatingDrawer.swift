import SwiftUI

extension View {
    /// Floats a panel over this view's trailing side while `isPresented`: a scrim behind (a tap closes), the panel
    /// inset from the top, trailing edge and bottom, sliding in from the right (a fade under Reduce Motion). Pass an
    /// `AinkradDrawerPanel` as `panel`. `top` (default 56) clears a filter bar; `inset` (default 20) is the trailing
    /// and bottom margin.
    public func ainkradFloatingDrawer<Panel: View>(
        isPresented: Binding<Bool>, top: CGFloat? = nil, inset: CGFloat? = nil,
        @ViewBuilder panel: @escaping () -> Panel
    ) -> some View {
        modifier(FloatingDrawerHost(isPresented: isPresented, top: top, inset: inset, panel: panel))
    }
}

private struct FloatingDrawerHost<Panel: View>: ViewModifier {
    @Binding var isPresented: Bool
    let top: CGFloat?
    let inset: CGFloat?
    let panel: () -> Panel
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    if isPresented {
                        skin.color(.palette("black", skin.opacity.o35))
                            .contentShape(Rectangle())
                            .onTapGesture { isPresented = false }
                            .transition(.opacity)
                        panel()
                            .frame(width: min(skin.size.s380 * 2, geo.size.width * 0.62))
                            .padding(.top, top ?? skin.size.s56)
                            .padding(.trailing, inset ?? skin.size.s20)
                            .padding(.bottom, inset ?? skin.size.s20)
                            .transition(
                                reduceMotion ? .opacity : .opacity.combined(with: .offset(x: skin.size.s60)))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topTrailing)
                .animation(
                    reduceMotion
                        ? nil : skin.animation(AinkradAnimationToken(curve: "spring", response: 0.35, damping: 0.82)),
                    value: isPresented)
            }
        }
    }
}

/// The panel an `ainkradFloatingDrawer` hosts: a header row (`header`, then `trailing`, then ✕ — Esc closes), a
/// scrolling body and a footer. `.reader` is the browse drawer (a requirement, a run, an artifact); `.form` is the
/// edit drawer (a tighter header, sections 12 apart, the footer on a faint strip of buttons). `contentID` swaps the
/// body with a short slide instead of re-entering the panel.
public struct AinkradDrawerPanel<Header: View, Trailing: View, Content: View, Footer: View>: View {
    public enum Style: Sendable { case reader, form }

    private let style: Style
    private let isTranslucent: Bool
    private let spacing: CGFloat?
    private let contentID: AnyHashable?
    private let onClose: () -> Void
    private let header: Header
    private let trailing: Trailing
    private let content: Content
    private let footer: Footer

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(
        style: Style = .reader, isTranslucent: Bool = false, spacing: CGFloat? = nil, contentID: AnyHashable? = nil,
        onClose: @escaping () -> Void, @ViewBuilder header: () -> Header, @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer
    ) {
        self.style = style
        self.isTranslucent = isTranslucent
        self.spacing = spacing
        self.contentID = contentID
        self.onClose = onClose
        self.header = header()
        self.trailing = trailing()
        self.content = content()
        self.footer = footer()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s20, style: .continuous)
        VStack(spacing: 0) {
            HStack(spacing: skin.size.s8) {
                header.frame(maxWidth: .infinity, alignment: .leading)
                trailing
                AinkradDrawerButton(action: onClose)
            }
            .padding(.horizontal, skin.size.s16)
            .padding(.vertical, style == .form ? skin.size.s10 : skin.size.s14)
            ScrollView {
                VStack(alignment: .leading, spacing: spacing ?? (style == .form ? skin.size.s12 : 0)) { content }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, skin.size.s16)
                    .padding(.bottom, skin.size.s16)
                    .id(contentID)
                    .transition(reduceMotion ? .opacity : .offset(x: skin.size.s18).combined(with: .opacity))
            }
            .scrollIndicators(.never)
            .animation(reduceMotion ? nil : skin.animation(skin.motion.present), value: contentID)
            if Footer.self != EmptyView.self {
                if style == .form {
                    HStack(spacing: skin.size.s8) { footer }
                        .padding(.horizontal, skin.size.s16)
                        .padding(.vertical, skin.size.s12)
                        .frame(maxWidth: .infinity)
                        .background(skin.color(.palette("foreground", skin.opacity.o03)))
                } else {
                    footer
                }
            }
        }
        .background(skin.color(.palette("background", isTranslucent ? skin.opacity.o90 : skin.opacity.o97)), in: shape)
        .background {
            if isTranslucent { shape.fill(.ultraThinMaterial) }
        }
        .clipShape(shape)
        .overlay(
            shape.strokeBorder(
                skin.color(.palette("foreground", style == .form ? skin.opacity.o08 : skin.opacity.o10)),
                lineWidth: 1)
        )
        .shadow(color: skin.color(.palette("black", skin.opacity.o50)), radius: skin.size.s30, x: -skin.size.s20)
    }
}

extension AinkradDrawerPanel where Trailing == EmptyView, Footer == EmptyView {
    public init(
        style: Style = .reader, isTranslucent: Bool = false, spacing: CGFloat? = nil, contentID: AnyHashable? = nil,
        onClose: @escaping () -> Void, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content
    ) {
        self.init(
            style: style, isTranslucent: isTranslucent, spacing: spacing, contentID: contentID, onClose: onClose,
            header: header, trailing: { EmptyView() }, content: content, footer: { EmptyView() })
    }
}

extension AinkradDrawerPanel where Footer == EmptyView {
    public init(
        style: Style = .reader, isTranslucent: Bool = false, spacing: CGFloat? = nil, contentID: AnyHashable? = nil,
        onClose: @escaping () -> Void, @ViewBuilder header: () -> Header, @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            style: style, isTranslucent: isTranslucent, spacing: spacing, contentID: contentID, onClose: onClose,
            header: header, trailing: trailing, content: content, footer: { EmptyView() })
    }
}

extension AinkradDrawerPanel where Trailing == EmptyView {
    public init(
        style: Style = .reader, isTranslucent: Bool = false, spacing: CGFloat? = nil, contentID: AnyHashable? = nil,
        onClose: @escaping () -> Void, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.init(
            style: style, isTranslucent: isTranslucent, spacing: spacing, contentID: contentID, onClose: onClose,
            header: header, trailing: { EmptyView() }, content: content, footer: footer)
    }
}

/// The drawer's square glyph button: the ✕ that closes it (Esc), or a pager chevron (`glyph`, `isEnabled`). Faint,
/// with a soft fill on hover; `filled` keeps a resting fill.
public struct AinkradDrawerButton: View {
    private let glyph: String
    private let size: CGFloat?
    private let isEnabled: Bool
    private let filled: Bool
    private let action: () -> Void
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin

    public init(
        glyph: String = "xmark", size: CGFloat? = nil, isEnabled: Bool = true, filled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.glyph = glyph
        self.size = size
        self.isEnabled = isEnabled
        self.filled = filled
        self.action = action
    }

    public var body: some View {
        let side = size ?? skin.size.s30
        let closes = glyph == "xmark"
        AinkradTapArea(help: closes ? "Close (Esc)" : nil, action: action) {
            Image(systemName: glyph)
                .kitFont(closes ? "t11" : "t12", weight: "semibold")
                .foregroundStyle(skin.color(hovering ? skin.text.primary : skin.text.muted))
                .frame(width: side, height: side)
                .background(
                    skin.color(
                        .palette("foreground", hovering ? skin.opacity.o12 : filled ? skin.opacity.o06 : 0)),
                    in: RoundedRectangle(cornerRadius: skin.size.s8, style: .continuous)
                )
                .contentShape(Rectangle())
        }
        .opacity(isEnabled ? 1 : skin.opacity.o30)
        .disabled(!isEnabled)
        .onHover { hovering = $0 && isEnabled }
        .animation(skin.animation(skin.motion.hover), value: hovering)
        .modifier(EscapeShortcut(isOn: closes))
    }
}

private struct EscapeShortcut: ViewModifier {
    let isOn: Bool
    func body(content: Content) -> some View {
        if isOn { content.keyboardShortcut(.cancelAction) } else { content }
    }
}

/// `Runs › #422`: faint crumbs, the last one emphasised. `monospaced` sets the whole trail in the mono face (the
/// edit drawers); otherwise only the last part is mono.
public struct AinkradDrawerCrumb: View {
    private let parts: [String]
    private let monospaced: Bool
    @Environment(\.ainkradSkin) private var skin

    public init(_ parts: [String], monospaced: Bool = false) {
        self.parts = parts
        self.monospaced = monospaced
    }

    public var body: some View {
        HStack(spacing: monospaced ? skin.size.s8 : skin.size.s6) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 { Text("›").foregroundStyle(skin.color(skin.text.faint)) }
                if index == parts.count - 1 {
                    Text(part).kitFont("t12", weight: monospaced ? "bold" : "semibold", mono: true)
                        .foregroundStyle(skin.color(skin.text.primary))
                } else {
                    Text(part).kitFont("t12", mono: monospaced).foregroundStyle(skin.color(skin.text.faint))
                }
            }
        }
        .lineLimit(1)
        .kitFont("t12")
    }
}
