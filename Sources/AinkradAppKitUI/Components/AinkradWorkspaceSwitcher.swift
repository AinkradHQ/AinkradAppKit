import AinkradAppKitContract
import SwiftUI

/// Whose workspace it is: the person's own, or a client's.
public enum AinkradWorkspaceKind: Equatable, Sendable {
    case own, client
}

/// One workspace (a Citadel company) on the switcher.
public struct AinkradWorkspace: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var kind: AinkradWorkspaceKind
    /// The tile's colour; `nil` takes the primary accent.
    public var tint: Color?
    /// A faint line under the name in the menu ("18 agents · 3 projects").
    public var detail: String?
    /// How many things wait on the person there; 0 shows none.
    public var needsYou: Int

    public init(
        id: String, name: String, kind: AinkradWorkspaceKind = .own, tint: Color? = nil, detail: String? = nil,
        needsYou: Int = 0
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.tint = tint
        self.detail = detail
        self.needsYou = needsYou
    }
}

/// The workspace switcher at the top of a sidebar (Citadel, every screen;
/// open on org 03): the current workspace's tile, name and own/client badge
/// over `subtitle`, and a chevron. Click opens `AinkradWorkspaceMenu` below it;
/// ⌘1–⌘9 jump straight to a workspace whether or not it is open. Hover
/// brightens it; open, it takes the accent rim.
public struct AinkradWorkspaceSwitcher: View {
    private let workspaces: [AinkradWorkspace]
    @Binding private var selection: String
    private let subtitle: String?
    private let header: String?
    private let footnote: String?
    private let onNew: (() -> Void)?
    @State private var isOpen = false
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - subtitle: under the name ("Citadel · 2 other companies").
    ///   - header, footnote, onNew: passed to the menu.
    public init(
        workspaces: [AinkradWorkspace], selection: Binding<String>, subtitle: String? = nil, header: String? = nil,
        footnote: String? = nil, onNew: (() -> Void)? = nil
    ) {
        self.workspaces = workspaces
        self._selection = selection
        self.subtitle = subtitle
        self.header = header
        self.footnote = footnote
        self.onNew = onNew
    }

    private var current: AinkradWorkspace? { workspaces.first { $0.id == selection } ?? workspaces.first }

    public var body: some View {
        let shape =
            skin.usesNativeGlass
            ? AnyShape(RoundedRectangle(cornerRadius: skin.size.s10, style: .continuous))
            : AnyShape(skin.shape(cut: skin.size.s7))
        Button {  // design-lint: allow raw-control the switcher's trigger
            isOpen.toggle()
        } label: {
            HStack(spacing: skin.size.s10) {
                if let current { KitWorkspaceTile(workspace: current) }
                VStack(alignment: .leading, spacing: skin.size.s1) {
                    HStack(spacing: skin.size.s6) {
                        Text(current?.name ?? "")
                            .font(skin.font(AinkradFontToken(sizeKey: "t13", weight: "semibold")))
                            .foregroundStyle(theme.foreground)
                            .lineLimit(1)
                        if let current { KitWorkspaceKindBadge(kind: current.kind) }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(skin.font(AinkradFontToken(sizeKey: "t10_5")))
                            .foregroundStyle(skin.color(skin.text.faint))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: skin.size.s4)
                Image(systemName: "chevron.down")
                    .imageScale(.small)
                    .foregroundStyle(skin.color(skin.text.faint))
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
            }
            .padding(.horizontal, skin.size.s10)
            .padding(.vertical, skin.size.s7)
            .background(
                shape.fill(
                    skin.usesNativeGlass
                        ? skin.color(skin.palette.white).opacity(skin.opacity.o06)
                        : theme.surface.opacity(skin.opacity.o96))
            )
            .overlay(shape.stroke(rim, lineWidth: 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .brightness(hovering && !isOpen ? skin.opacity.o06 : 0)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: isOpen)
        .background { shortcuts }
        .ainkradFloatingPanel(isPresented: $isOpen, maxHeight: skin.size.s440) {
            AinkradWorkspaceMenu(
                workspaces: workspaces,
                selection: Binding(
                    get: { selection },
                    set: {
                        selection = $0
                        isOpen = false
                    }), header: header, footnote: footnote,
                onNew: onNew.map { new in
                    {
                        isOpen = false
                        new()
                    }
                })
        }
        .accessibilityLabel("Workspace: \(current?.name ?? "")")
        .accessibilityValue(subtitle ?? "")
        .accessibilityHint("Shows every workspace")
    }

    private var rim: Color {
        if isOpen { return theme.accentPrimary }
        return skin.usesNativeGlass
            ? skin.color(skin.palette.white).opacity(skin.opacity.o12) : theme.accentSecondary.opacity(skin.opacity.o45)
    }

    /// ⌘1–⌘9, invisible, so the jump works with the menu closed.
    private var shortcuts: some View {
        ForEach(Array(workspaces.prefix(9).enumerated()), id: \.element.id) { index, workspace in
            Button("") { selection = workspace.id }  // design-lint: allow raw-control keyboard-only ⌘N jump
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                .opacity(0)
                .accessibilityHidden(true)
        }
    }
}

/// The open switcher (Citadel org 03): an optional caps `header` ("Companies
/// on citadel.ainkrad.io"), one row per workspace — tile, name and badge over
/// its detail, its needs-you count in amber, its ⌘N — the current one filled
/// with the accent, then "New company…" when `onNew` is set, and a faint
/// `footnote`. Rows lift their fill on hover; each is a keyboard stop.
public struct AinkradWorkspaceMenu: View {
    private let workspaces: [AinkradWorkspace]
    @Binding private var selection: String
    private let header: String?
    private let footnote: String?
    private let onNew: (() -> Void)?
    @State private var hovered: String?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme

    public init(
        workspaces: [AinkradWorkspace], selection: Binding<String>, header: String? = nil, footnote: String? = nil,
        onNew: (() -> Void)? = nil
    ) {
        self.workspaces = workspaces
        self._selection = selection
        self.header = header
        self.footnote = footnote
        self.onNew = onNew
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: skin.size.s2) {
            if let header {
                Text(skin.labelCased(header))
                    .font(skin.font(AinkradFontToken(sizeKey: "t10", weight: "semibold")))
                    .tracking(skin.usesNativeGlass ? 0 : skin.size.s1)
                    .foregroundStyle(skin.color(skin.text.faint))
                    .padding(.horizontal, skin.size.s10)
                    .padding(.top, skin.size.s6)
                    .padding(.bottom, skin.size.s4)
            }
            ForEach(Array(workspaces.enumerated()), id: \.element.id) { index, workspace in
                row(workspace, index: index)
            }
            if let onNew {
                KitMenuRow(isHighlighted: hovered == "+new", isSelected: false, action: onNew) {
                    HStack(spacing: skin.size.s10) {
                        Image(systemName: "plus")
                            .foregroundStyle(theme.accentSecondary)
                            .frame(width: skin.size.s26)
                        Text("New company…")
                            .font(skin.font(AinkradFontToken(sizeKey: "t13")))
                            .foregroundStyle(theme.foreground)
                        Spacer(minLength: skin.size.s8)
                        Text("admin")
                            .font(skin.font(AinkradFontToken(sizeKey: "t10", mono: "family")))
                            .foregroundStyle(skin.color(skin.text.faint))
                    }
                }
                .onHover { hovered = $0 ? "+new" : nil }
            }
            if let footnote {
                Text(footnote)
                    .font(skin.font(AinkradFontToken(sizeKey: "t10_5")))
                    .foregroundStyle(skin.color(skin.text.faint))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, skin.size.s10)
                    .padding(.vertical, skin.size.s6)
            }
        }
        .padding(skin.size.s4)
        .frame(width: skin.size.s300)
        .modifier(PopoverChrome())
        .accessibilityElement(children: .contain)
    }

    private func row(_ workspace: AinkradWorkspace, index: Int) -> some View {
        KitMenuRow(
            isHighlighted: hovered == workspace.id, isSelected: workspace.id == selection,
            action: { selection = workspace.id }
        ) {
            HStack(spacing: skin.size.s10) {
                KitWorkspaceTile(workspace: workspace)
                VStack(alignment: .leading, spacing: skin.size.s1) {
                    HStack(spacing: skin.size.s6) {
                        Text(workspace.name)
                            .font(skin.font(AinkradFontToken(sizeKey: "t13", weight: "medium")))
                            .foregroundStyle(theme.foreground)
                            .lineLimit(1)
                        KitWorkspaceKindBadge(kind: workspace.kind)
                    }
                    if let detail = workspace.detail {
                        Text(detail)
                            .font(skin.font(AinkradFontToken(sizeKey: "t10_5")))
                            .foregroundStyle(skin.color(skin.text.faint))
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: skin.size.s8)
                if workspace.needsYou > 0 {
                    KitCountDot(count: workspace.needsYou)
                }
                if index < 9 {
                    Text("⌘\(index + 1)")
                        .font(skin.font(AinkradFontToken(sizeKey: "t10", mono: "family")))
                        .foregroundStyle(skin.color(skin.text.faint))
                }
            }
        }
        .onHover { hovered = $0 ? workspace.id : (hovered == workspace.id ? nil : hovered) }
        .accessibilityLabel(
            [
                workspace.name, workspace.kind == .own ? "own" : "client", workspace.detail,
                workspace.needsYou > 0 ? "\(workspace.needsYou) need you" : nil,
            ].compactMap { $0 }.joined(separator: ", ")
        )
        .accessibilityAddTraits(workspace.id == selection ? .isSelected : [])
    }
}

/// A menu row: the accent fill when selected, a white lift on hover.
struct KitMenuRow<Content: View>: View {
    let isHighlighted: Bool
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: Content
    @FocusState private var focused: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {  // design-lint: allow raw-control menu row
            content
                .padding(.horizontal, skin.size.s8)
                .padding(.vertical, skin.size.s6)
                .background(
                    RoundedRectangle(cornerRadius: skin.size.s6, style: .continuous)
                        .fill(fill)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The keyboard focus lifts the row like a hover instead of drawing the system ring.
        .focusEffectDisabled()
        .focused($focused)
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: isHighlighted || focused)
    }

    private var fill: Color {
        if isSelected { return theme.accentPrimary.opacity(focused ? skin.opacity.o30 : skin.opacity.o22) }
        return isHighlighted || focused ? skin.color(skin.palette.white).opacity(skin.opacity.o06) : .clear
    }
}

/// The workspace's initial on its colour: Neon a 3 pt-cut chamfer, Glass a
/// 7 pt rounded square, with a 1 pt inner highlight.
struct KitWorkspaceTile: View {
    let workspace: AinkradWorkspace
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme

    var body: some View {
        let shape =
            skin.usesNativeGlass
            ? AnyShape(RoundedRectangle(cornerRadius: skin.size.s7, style: .continuous))
            : AnyShape(skin.shape(cut: skin.size.s5))
        Text(workspace.name.first.map { String($0).uppercased() } ?? "")
            .font(skin.font(AinkradFontToken(sizeKey: "t12", weight: "bold")))
            .foregroundStyle(skin.color(skin.palette.white))
            .frame(width: skin.size.s26, height: skin.size.s26)
            .background(shape.fill(workspace.tint ?? theme.accentPrimary))
            .overlay(shape.stroke(skin.color(skin.palette.white).opacity(skin.opacity.o18), lineWidth: 1))
            .accessibilityHidden(true)
    }
}

/// "OWN" in the primary accent, "CLIENT" in the tertiary — tiny caps capsules.
struct KitWorkspaceKindBadge: View {
    let kind: AinkradWorkspaceKind
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme

    var body: some View {
        let color = kind == .own ? theme.accentPrimary : theme.accentTertiary
        Text(kind == .own ? "OWN" : "CLIENT")
            .font(skin.font(AinkradFontToken(sizeKey: "t9", weight: "semibold")))
            .tracking(skin.size.s1 / 2)
            .foregroundStyle(color)
            .brightness(skin.opacity.o35)  // the mockups' light blue / mint tints
            .padding(.horizontal, skin.size.s5)
            .background(color.opacity(kind == .own ? skin.opacity.o30 : skin.opacity.o16), in: Capsule())
            .fixedSize()
            .accessibilityHidden(true)
    }
}

/// An amber count pill ("8") — things waiting on the person.
struct KitCountDot: View {
    let count: Int
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors

    var body: some View {
        Text("\(count)")
            .font(skin.font(AinkradFontToken(sizeKey: "t10", weight: "semibold", mono: "family")))
            .foregroundStyle(theme.background)
            .padding(.horizontal, skin.size.s6)
            .background(statusColors.warning, in: Capsule())
            .fixedSize()
    }
}
