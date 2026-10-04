import AinkradAppKitContract
import SwiftUI

/// Square, icon-only Cardinal HUD button — chamfered corners, accent glow on
/// hover. Use for compact toolbar/utility actions.
public struct AinkradIconButton: View {
    private let systemName: String
    private let action: () -> Void
    /// Button frame edge (width == height). Defaults to the historical fixed
    /// 30×30 so the original `init(systemName:action:)` keeps its exact look.
    private let size: CGFloat
    /// Self-managed hover tooltip; `nil` = no tooltip (original behavior).
    private let tooltip: String?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(systemName: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
        self.size = 30
        self.tooltip = nil
    }

    /// Tooltipped variant at the default 30×30. `tooltip` is non-defaulted, so
    /// this is a distinct mangled symbol from `init(systemName:action:)` and
    /// that existing symbol is untouched.
    ///
    /// Exists because the plain initializer takes no `tooltip:`, and the only
    /// way to get one was to also pass a `size:` — so a caller who wanted a
    /// hover hint at the default size had to restate 30 as a literal, pinning
    /// the frame against any future change to the default. Every icon-only
    /// button wants a tooltip; needing a magic number to ask for one is why
    /// callers quietly went without.
    public init(systemName: String, tooltip: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
        self.size = 30
        self.tooltip = tooltip
    }

    /// Sized (and optionally tooltipped) variant. `size` is non-defaulted, so
    /// this is a distinct mangled symbol from `init(systemName:action:)` — the
    /// existing symbol is untouched. The chamfer cut and glyph scale with `size`.
    public init(systemName: String, size: CGFloat, tooltip: String? = nil, action: @escaping () -> Void) {
        self.systemName = systemName
        self.action = action
        self.size = size
        self.tooltip = tooltip
    }

    /// Chamfer cut scaled off the frame — 6 at the historical 30×30.
    private var cut: CGFloat { size * 0.2 }
    /// Glyph point size scaled off the frame — ~13 at the historical 30×30.
    private var glyphSize: CGFloat { size * 0.433 }

    public var body: some View {
        let button = Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: glyphSize, weight: .semibold))
                .foregroundStyle(theme.foreground.opacity(hovering ? 1.0 : 0.75))
                .frame(width: size, height: size)
                .background(ChamferShape(cut: cut).fill(theme.surfaceElevated.opacity(hovering ? 0.7 : 0.4)))
                .overlay(
                    ChamferShape(cut: cut).strokeBorder(
                        theme.accentSecondary.opacity(hovering ? 0.85 : 0.35), lineWidth: 1)
                )
                .shadow(color: theme.accentSecondary.opacity(hovering ? 0.5 : 0), radius: hovering ? 5 : 0)
                .contentShape(ChamferShape(cut: cut))
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? 1.05 : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .onHover { hovering = $0 }

        if let tooltip {
            button.ainkradTooltip(tooltip)
        } else {
            button
        }
    }
}

/// Latch-style toggle button — stays lit while `isOn` is true, distinct from
/// the switch-style `AinkradToggle`. Supply either (or both) of `systemName`
/// and `title`.
public struct AinkradToggleButton: View {
    @Binding private var isOn: Bool
    private let systemName: String?
    private let title: String?

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(isOn: Binding<Bool>, systemName: String? = nil, title: String? = nil) {
        self._isOn = isOn
        self.systemName = systemName
        self.title = title
    }

    /// Mirrors the `isOn` binding — exposed for testing the latch state.
    public var isActive: Bool { isOn }

    public var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: AinkradSpacing.xs) {
                if let systemName {
                    Image(systemName: systemName).font(.system(size: 12, weight: .semibold))
                }
                if let title {
                    Text(title.uppercased())
                        .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                        .tracking(0.8)
                }
            }
            .foregroundStyle(isActive ? theme.accentPrimary.contrastingText : theme.foreground.opacity(0.75))
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(
                ChamferShape(cut: 6).fill(
                    isActive ? theme.accentPrimary.opacity(0.85) : theme.surfaceElevated.opacity(hovering ? 0.6 : 0.4))
            )
            .overlay(
                ChamferShape(cut: 6).strokeBorder(
                    theme.accentSecondary.opacity(isActive ? 0.95 : (hovering ? 0.6 : 0.3)), lineWidth: 1.25)
            )
            .shadow(color: theme.accentSecondary.opacity(isActive ? 0.55 : 0), radius: isActive ? 5 : 0)
            .contentShape(ChamferShape(cut: 6))
        }
        .buttonStyle(.plain)
        .scaleEffect(hovering && !reduceMotion ? 1.02 : 1.0)
        .animation(AinkradMotion.hover, value: hovering)
        .animation(AinkradMotion.hover, value: isActive)
        .onHover { hovering = $0 }
    }
}
