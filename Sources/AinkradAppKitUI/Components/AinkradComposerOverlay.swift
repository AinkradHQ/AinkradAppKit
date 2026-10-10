import AinkradAppKitContract
import AppKit
import SwiftUI

/// The `/` and `@` overlay's rows, drawn in the floating panel anchored to the
/// composer: optional section headers, one highlighted row, a compact empty
/// state and a keyboard-hint footer. The panel window is transparent, so this
/// draws its own chrome — the same fill, stroke and glow the kit's dropdowns use.
struct AinkradComposerOverlayList: View {
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typography
    let trigger: AinkradComposerTrigger
    let suggestions: [AinkradComposerSuggestion]
    let selectedIndex: Int
    let onSelect: (AinkradComposerSuggestion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: skin.spacing.xs) {
            if suggestions.isEmpty {
                emptyState
            } else {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    if let section = suggestion.section, section != suggestions[safe: index - 1]?.section {
                        sectionHeader(section)
                    }
                    AinkradListRow(
                        isSelected: index == selectedIndex,
                        onTap: { onSelect(suggestion) },
                        leading: {
                            Image(systemName: suggestion.icon)
                                .font(skin.font(AinkradFontToken(sizeKey: "t12", weight: "semibold", scaled: false)))
                                .foregroundStyle(theme.accentSecondary)
                        },
                        title: suggestion.title,
                        subtitle: suggestion.subtitle,
                        trailing: { EmptyView() }
                    )
                }
                hintFooter
            }
        }
        .padding(skin.size.s6)
        .background(skin.shape(cut: skin.cut.c8).fill(theme.surfaceElevated.opacity(skin.opacity.o97)))
        .overlay(
            skin.shape(cut: skin.cut.c8).strokeBorder(theme.accentSecondary.opacity(skin.opacity.o55), lineWidth: 1.25)
        )
        .shadow(color: theme.accentSecondary.opacity(skin.opacity.o35), radius: skin.size.s10, y: 4)
        .frame(minWidth: skin.size.s280)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(skin.labelCased(title))
            .font(AinkradFontResolver.font(size: 10, weight: .medium, typography: typography))
            .kerning(0.6)
            .foregroundStyle(theme.foreground.opacity(skin.opacity.o50))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, skin.size.s10)
            .padding(.top, skin.size.s6)
            .padding(.bottom, skin.size.s2)
    }

    /// One muted glyph over one muted line — `AinkradEmptyState` is too tall
    /// for a ~280 pt panel.
    private var emptyState: some View {
        VStack(spacing: skin.size.s6) {
            Image(systemName: isCommand ? "magnifyingglass" : "doc.text.magnifyingglass")
                .font(skin.font(AinkradFontToken(sizeKey: "t18", weight: "regular", scaled: false)))
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o40))
            Text(isCommand ? "No matching commands" : "No matching files")
                .font(AinkradFontResolver.font(size: 12, typography: typography))
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o50))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, skin.size.s14)
    }

    /// Muted keyboard hint — no separator line.
    private var hintFooter: some View {
        Text("↑↓ navigate · ↵ select · esc dismiss")
            .font(AinkradFontResolver.font(size: 10, typography: typography))
            .foregroundStyle(theme.foreground.opacity(skin.opacity.o35))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, skin.size.s6)
            .padding(.top, skin.size.s2)
    }

    private var isCommand: Bool {
        if case .command = trigger { return true }
        return false
    }
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// App-scoped local `keyDown` monitor that swallows Up/Down/Return while the
/// overlay is open — the overlay has no text field of its own, its query is the
/// composer's draft. Zero-size; rides the composer's lifetime.
struct AinkradComposerOverlayKeyMonitor: NSViewRepresentable {
    let isActive: () -> Bool
    let onKey: (AinkradComposerOverlayKey) -> Void

    func makeNSView(context: Context) -> MonitoringView {
        let view = MonitoringView()
        view.isActive = isActive
        view.onKey = onKey
        return view
    }

    func updateNSView(_ nsView: MonitoringView, context: Context) {
        nsView.isActive = isActive
        nsView.onKey = onKey
    }

    final class MonitoringView: NSView {
        var isActive: (() -> Bool)?
        var onKey: ((AinkradComposerOverlayKey) -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil {
                guard monitor == nil else { return }
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    guard let self, self.isActive?() == true,
                        let key = AinkradComposerOverlayKey.key(for: event.keyCode)
                    else { return event }
                    self.onKey?(key)
                    return nil
                }
            } else if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
    }
}
