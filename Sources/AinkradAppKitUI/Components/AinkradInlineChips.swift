import SwiftUI

/// A mono value pill; a click turns it into a field, Return commits (the caller checks and refuses), focus loss
/// cancels.
public struct AinkradValuePill: View {
    private let text: String
    private let help: String?
    private let tint: Color?
    private let commit: (String) -> Void
    @State private var editing = false
    @State private var draft = ""
    @FocusState private var focused: Bool
    @Environment(\.ainkradSkin) private var skin

    public init(text: String, help: String? = nil, tint: Color? = nil, commit: @escaping (String) -> Void) {
        self.text = text
        self.help = help
        self.tint = tint
        self.commit = commit
    }

    public var body: some View {
        if editing {
            AinkradTextField(text: $draft, placeholder: text, focus: $focused)
                .monospaced().compact()
                .onReturn { _ in
                    editing = false
                    commit(draft)
                }
                .frame(width: skin.size.s90)
                .onAppear {
                    draft = text
                    focused = true
                }
                .onChange(of: focused) { _, now in if !now { editing = false } }
        } else {
            AinkradTapArea(help: help, action: { editing = true }) {
                Text(text).kitFont("t11", mono: true)
                    .foregroundStyle(tint ?? skin.color(skin.text.muted))
                    .padding(.horizontal, skin.size.s6)
                    .padding(.vertical, skin.size.s1)
                    .background(
                        skin.color(.palette("foreground", skin.opacity.o06)),
                        in: RoundedRectangle(cornerRadius: skin.size.s5, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: skin.size.s5, style: .continuous)
                            .strokeBorder(skin.color(.palette("foreground", skin.opacity.o08)), lineWidth: 1))
            }
        }
    }
}

/// Where a value comes from: `↳ server` (faint) when inherited, `● project ↺` (secondary accent) when overridden,
/// with a reset when `reset` is given. A lighter sibling of the `AinkradScopedValue` row's chip, for use inline.
public struct AinkradScopeChip: View {
    private let text: String
    private let overridden: Bool
    private let reset: (() -> Void)?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme

    public init(text: String, overridden: Bool = false, reset: (() -> Void)? = nil) {
        self.text = text
        self.overridden = overridden
        self.reset = reset
    }

    public var body: some View {
        let tint = overridden ? theme.accentSecondary : skin.color(skin.text.faint)
        HStack(spacing: skin.size.s4) {
            Text(overridden ? "● \(text)" : "↳ \(text)")
            if let reset {
                AinkradTapArea(help: "Reset to inherited", action: reset) { Text("↺") }
            }
        }
        .kitFont("t10_5", mono: true)
        .foregroundStyle(tint)
        .padding(.horizontal, skin.size.s6)
        .padding(.vertical, skin.size.s1)
        .background(
            (overridden ? tint.opacity(skin.opacity.o12) : skin.color(.palette("foreground", skin.opacity.o05))),
            in: RoundedRectangle(cornerRadius: skin.size.s5, style: .continuous))
    }
}

/// A toggle chip: `✓ rate-limited` on (secondary accent), `○ refused task` off.
public struct AinkradToggleChip: View {
    private let title: String
    private let isOn: Bool
    private let isEnabled: Bool
    private let help: String?
    private let toggle: () -> Void
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme

    public init(
        title: String, isOn: Bool, isEnabled: Bool = true, help: String? = nil, toggle: @escaping () -> Void
    ) {
        self.title = title
        self.isOn = isOn
        self.isEnabled = isEnabled
        self.help = help
        self.toggle = toggle
    }

    public var body: some View {
        let accent = theme.accentSecondary
        let shape = RoundedRectangle(cornerRadius: skin.size.s9, style: .continuous)
        AinkradTapArea(help: help, action: { if isEnabled { toggle() } }) {
            Text("\(isOn ? "✓" : "○") \(title)").kitFont("t11")
                .foregroundStyle(isOn ? accent : skin.color(skin.text.faint))
                .padding(.horizontal, skin.size.s10)
                .frame(height: skin.size.s28)
                .background(
                    shape.fill(
                        isOn ? accent.opacity(skin.opacity.o10) : skin.color(.palette("foreground", skin.opacity.o05)))
                )
                .overlay(
                    shape.strokeBorder(
                        isOn ? accent.opacity(skin.opacity.o35) : skin.color(.palette("foreground", skin.opacity.o07)),
                        lineWidth: 1))
        }
        .opacity(isEnabled ? 1 : skin.opacity.o45)
        .animation(skin.animation(skin.motion.hover), value: isOn)
    }
}

/// A small segment of plain options, the chosen one accent-washed with an inset ring.
public struct AinkradMiniSegment<ID: Hashable>: View {
    private let options: [(id: ID, title: String)]
    @Binding private var selection: ID
    @Environment(\.ainkradSkin) private var skin

    public init(options: [(id: ID, title: String)], selection: Binding<ID>) {
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: skin.size.s6) {
            ForEach(options, id: \.id) { option in
                let isOn = option.id == selection
                let shape = RoundedRectangle(cornerRadius: skin.size.s8, style: .continuous)
                AinkradTapArea(action: { selection = option.id }) {
                    Text(option.title).kitFont("t11")
                        .foregroundStyle(isOn ? skin.color(.palette("foreground", 1)) : skin.color(skin.text.muted))
                        .padding(.horizontal, skin.size.s10)
                        .frame(height: skin.size.s26)
                        .background(
                            shape.fill(
                                isOn
                                    ? skin.color(skin.palette.accentPrimary).opacity(skin.opacity.o22)
                                    : skin.color(.palette("foreground", skin.opacity.o05)))
                        )
                        .overlay(
                            shape.strokeBorder(
                                isOn ? skin.color(skin.palette.accentPrimary).opacity(skin.opacity.o40) : .clear,
                                lineWidth: 1))
                }
            }
        }
        .animation(skin.animation(skin.motion.hover), value: selection)
    }
}
