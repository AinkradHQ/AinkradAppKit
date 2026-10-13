import SwiftUI

/// `label` split into runs of matched / unmatched characters, in order.
/// `matched` holds Character offsets into `label`; out-of-range ones are ignored.
/// Pure, so the highlight is testable without a view.
func ainkradMatchRuns(_ label: String, matched: Set<Int>) -> [(text: String, isMatch: Bool)] {
    var runs: [(text: String, isMatch: Bool)] = []
    for (offset, character) in label.enumerated() {
        let isMatch = matched.contains(offset)
        if let last = runs.last, last.isMatch == isMatch {
            runs[runs.count - 1].text.append(character)
        } else {
            runs.append((String(character), isMatch))
        }
    }
    return runs
}

/// The mockups' palette row (Forge quick open / command palette `.palette .r`,
/// Grimoire's slash panel `.panel .row`): one flat line — optional glyph,
/// title with its matched letters bold in the accent, faint mono detail
/// (inline after the title, or pushed to the trailing edge), then outlined
/// keycaps. Only the highlighted row is filled (primary accent, 30 %); hover
/// is a faint wash. No per-row chrome, stroke or glow.
struct AinkradPaletteRow: View {
    let icon: String
    let label: String
    let matched: Set<Int>
    let detail: String?
    /// Space-separated keycaps (`"⌘K ⌘\\"` draws two caps).
    let value: String?
    let isHighlighted: Bool
    /// Grimoire's slash panel pushes the detail to the row's end.
    var detailTrailing = false
    var cornerRadius: CGFloat = 8
    /// Forge's quick open shows a `↵` cap on the highlighted row that has no
    /// shortcut of its own.
    var showsReturnKey = false
    /// Forge's quick open draws file types as text glyphs (`◆`, `≡`, `#`)
    /// rather than SF Symbols, each in its own colour.
    var iconIsGlyph = false
    var iconTint: Color?
    let action: () -> Void

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: skin.size.s10) {
                if !icon.isEmpty {
                    iconView
                        .foregroundStyle(iconTint ?? theme.accentSecondary)
                        .frame(width: skin.size.s16)
                }
                Text(title).lineLimit(1).layoutPriority(1)
                if detailTrailing { Spacer(minLength: skin.size.s10) }
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(AinkradFontResolver.font(size: 11, mono: true, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(skin.opacity.o35))
                        .lineLimit(1).truncationMode(.middle)
                }
                if !detailTrailing { Spacer(minLength: skin.size.s10) }
                keycaps
            }
            .font(AinkradFontResolver.font(size: 13, typography: typo))
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, skin.size.s10)
            .padding(.vertical, skin.size.s7)
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(fill))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: hovering)
    }

    /// A glyph sits at the row's 13 pt, as the mockup's `.ic` inherits it.
    @ViewBuilder private var iconView: some View {
        if iconIsGlyph {
            Text(icon).font(AinkradFontResolver.font(size: 13, typography: typo))
        } else {
            Image(systemName: icon).font(AinkradFontResolver.font(size: 11, typography: typo))
        }
    }

    private var fill: Color {
        if isHighlighted { return theme.accentPrimary.opacity(skin.opacity.o30) }
        return hovering ? theme.foreground.opacity(skin.opacity.o05) : .clear
    }

    /// Matched letters: semibold, the secondary accent under Neon, white under
    /// Glass (the mockups' `.n b`).
    private var title: AttributedString {
        let accent = skin.usesNativeGlass ? theme.foreground : theme.accentSecondary
        let bold = AinkradFontResolver.font(size: 13, weight: .semibold, typography: typo)
        var out = AttributedString()
        for run in ainkradMatchRuns(label, matched: matched) {
            var piece = AttributedString(run.text)
            if run.isMatch {
                piece.foregroundColor = accent
                piece.font = bold
            }
            out += piece
        }
        return out
    }

    @ViewBuilder private var keycaps: some View {
        let keys = (value ?? "").split(separator: " ").map(String.init)
        if !keys.isEmpty {
            HStack(spacing: skin.size.s4) {
                ForEach(Array(keys.enumerated()), id: \.offset) { _, key in AinkradKbd(key).outlined() }
            }
            .fixedSize()
        } else if showsReturnKey, isHighlighted {
            AinkradKbd("↵").outlined()
        }
    }
}

/// A palette group caption (`.grp label` / `.sec label`): 10 pt semibold,
/// muted, in the skin's label case.
struct AinkradPaletteSectionHeader: View {
    let title: String

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    var body: some View {
        Text(skin.labelCased(title))
            .font(AinkradFontResolver.font(size: 10, weight: .semibold, typography: typo))
            .tracking(skin.usesNativeGlass ? 0 : 0.8)
            .foregroundStyle(theme.foreground.opacity(skin.opacity.o55))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, skin.size.s10)
            .padding(.top, skin.size.s8)
            .padding(.bottom, skin.size.s4)
    }
}
