import SwiftUI
import AinkradAppKitContract

/// The control that moves a pane between basic and advanced.
///
/// Standalone rather than buried in `AinkradBasicShell`, because it is needed
/// in BOTH modes: basic needs a way out, and advanced needs the way back. An
/// app renders it in its basic root via the shell, and once more wherever its
/// advanced root puts its own chrome.
///
/// It must read as *expanding this app*, not as opening a different one — so it
/// is one control that changes label and direction, never two buttons.
///
/// Outside a host pane (previews, tests) `\.ainkradSetPaneMode` is a no-op and
/// `\.ainkradPaneMode` reads `.advanced`, so this renders as "Simplify" and does
/// nothing. Only an app that opted into `AinkradAppModes` ever places it, so
/// there is no way for a pane with no basic mode to show a dead control.
public struct AinkradModeSwitch: View {
    private let expandedTitle: String
    private let collapsedTitle: String

    @Environment(\.ainkradPaneMode) private var mode
    @Environment(\.ainkradSetPaneMode) private var setMode
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var isHovering = false

    /// - Parameters:
    ///   - expandedTitle: shown in basic mode — what pressing it gets you.
    ///   - collapsedTitle: shown in advanced mode.
    public init(expandedTitle: String = "Show everything",
                collapsedTitle: String = "Simplify") {
        self.expandedTitle = expandedTitle
        self.collapsedTitle = collapsedTitle
    }

    private var isBasic: Bool { mode == .basic }
    private var title: String { isBasic ? expandedTitle : collapsedTitle }

    public var body: some View {
        Button {
            setMode(isBasic ? .advanced : .basic)
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                Image(systemName: isBasic
                      ? "arrow.down.left.and.arrow.up.right"
                      : "arrow.up.right.and.arrow.down.left")
                    .font(.system(size: 9, weight: .semibold))
                Text(title)
                    .font(AinkradFontResolver.font(.caption, weight: .medium, typography: typo))
            }
            .foregroundStyle(theme.foreground.opacity(isHovering ? 0.95 : 0.55))
            .padding(.horizontal, AinkradSpacing.sm)
            .padding(.vertical, AinkradSpacing.xs)
            .background(
                RoundedRectangle(cornerRadius: AinkradRadius.sm, style: .continuous)
                    .fill(theme.foreground.opacity(isHovering ? 0.08 : 0))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            guard !reduceMotion else { isHovering = hovering; return }
            withAnimation(.easeOut(duration: 0.12)) { isHovering = hovering }
        }
        .accessibilityLabel(title)
    }
}

/// The shared surface every app's **basic** mode is built on.
///
/// One component rather than nine local ones, so basic mode is the same shape
/// wherever you meet it: a compact header naming what you are acting on, the
/// one thing you came for, and at most a few primary actions. No rail, no tabs,
/// no sidebar — if it needs those, it belongs in advanced.
///
/// Sized to work at pane width and inside the host's floating overlay
/// (~560–700 wide), because basic mode and `.overlay` presentation are the
/// combination most apps will ship.
///
/// House rules it follows: no separator lines (spacing carries the structure),
/// colours from the theme rather than literals, motion gated on
/// `\.ainkradReduceMotion`, hover states treated as first-class.
public struct AinkradBasicShell<Content: View, Actions: View>: View {
    private let icon: String?
    private let title: String
    private let subtitle: String?
    private let showsModeSwitch: Bool
    private let actions: Actions
    private let content: Content

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    /// - Parameters:
    ///   - icon: SF Symbol naming the target, tinted from the theme.
    ///   - title: what this pane is acting on — a repo, a note, a connection.
    ///   - subtitle: the qualifier that makes the title unambiguous — a branch,
    ///     a path, a host.
    ///   - showsModeSwitch: false only when the app places its own switch
    ///     somewhere the header cannot reach.
    ///   - actions: the primary actions. Keep to three; a fourth is a sign this
    ///     screen belongs in advanced.
    ///   - content: the one thing this mode exists to show.
    public init(icon: String? = nil,
                title: String,
                subtitle: String? = nil,
                showsModeSwitch: Bool = true,
                @ViewBuilder actions: () -> Actions,
                @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showsModeSwitch = showsModeSwitch
        self.actions = actions()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.md) {
            header
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(AinkradSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: AinkradSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.accentPrimary)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AinkradFontResolver.font(.headline, weight: .medium, typography: typo))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let subtitle {
                    Text(subtitle)
                        .font(AinkradFontResolver.font(.caption, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(0.55))
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: AinkradSpacing.sm)
            HStack(spacing: AinkradSpacing.xs) {
                actions
                if showsModeSwitch { AinkradModeSwitch() }
            }
        }
    }
}

public extension AinkradBasicShell where Actions == EmptyView {
    /// Convenience for a basic mode whose content carries its own actions —
    /// a document, a log, a thread.
    init(icon: String? = nil,
         title: String,
         subtitle: String? = nil,
         showsModeSwitch: Bool = true,
         @ViewBuilder content: () -> Content) {
        self.init(icon: icon, title: title, subtitle: subtitle,
                  showsModeSwitch: showsModeSwitch,
                  actions: { EmptyView() }, content: content)
    }
}
