import AinkradAppKitContract
import SwiftUI

/// Renders assistant transcript text as markdown blocks. Prose/heading/list
/// items resolve inline markdown via `AttributedString`; fenced code reuses
/// the kit's `AinkradCodeBlock` (mono chamfer surface + copy button). Block
/// parsing is incremental (see `AinkradMarkdownStreamParser`) and inline markdown
/// resolution is memoised via `AinkradInlineMarkdownCache`, so re-evaluating this
/// view on every streaming update stays cheap.
public struct AinkradMarkdownText: View {
    @Environment(\.ainkradSkin) private var skin
    private let blocks: [AinkradMarkdownBlock]
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var environmentTypography
    /// `nil` follows the environment's typography (the user's font and scale).
    private let typographyOverride: AinkradTypography?
    private var typography: AinkradTypography { typographyOverride ?? environmentTypography }
    /// Set by `replyStyle()`.
    var usesReplyStyle = false

    /// Primary path for streaming: blocks are already parsed incrementally by
    /// `AinkradMarkdownStreamParser`, so this does no parsing at all.
    public init(blocks: [AinkradMarkdownBlock], typography: AinkradTypography? = nil) {
        self.blocks = blocks
        self.typographyOverride = typography
    }

    /// Committed transcript messages, which are parsed once and never change.
    public init(text: String, typography: AinkradTypography? = nil) {
        self.init(blocks: AinkradMarkdownBlocks.parse(text), typography: typography)
    }

    /// Grimoire's reply markdown (mockup 10): inline `code` as a tinted chip —
    /// mono, the secondary accent, on a quiet fill — and fenced code as a
    /// quiet block with no rim, a text "Copy" on hover and syntax colours.
    public func replyStyle() -> Self {
        var copy = self
        copy.usesReplyStyle = true
        return copy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.sm) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: AinkradMarkdownBlock) -> some View {
        switch block {
        case .paragraph(let src):
            inline(src).font(AinkradFontResolver.font(size: 13, typography: typography)).foregroundStyle(
                theme.foreground.opacity(skin.opacity.o90))
        case .heading(let level, let src) where level >= 3:
            // Minor headings read as a section label, like a card header.
            Text(skin.labelCased(src.replacingOccurrences(of: "*", with: "").replacingOccurrences(of: "`", with: "")))
                .font(AinkradFontResolver.font(size: 12, weight: .semibold, typography: typography))
                .tracking(skin.components.codeBlock.headerFont.tracking ?? 0)
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o60))
                .padding(.top, skin.size.s4)
        case .heading(let level, let src):
            inline(src)
                .font(AinkradFontResolver.font(size: headingSize(level), weight: .semibold, typography: typography))
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o95))
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: skin.size.s3) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: skin.size.s6) {
                        Text("•").foregroundStyle(theme.accentSecondary)
                        inline(item).foregroundStyle(theme.foreground.opacity(skin.opacity.o90))
                    }
                    .font(AinkradFontResolver.font(size: 13, typography: typography))
                }
            }
        case .orderedList(let items):
            VStack(alignment: .leading, spacing: skin.size.s3) {
                ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                    HStack(alignment: .firstTextBaseline, spacing: skin.size.s6) {
                        Text("\(idx + 1).")
                            .font(AinkradFontResolver.font(size: 11.5, mono: true, typography: typography))
                            .foregroundStyle(theme.foreground.opacity(skin.opacity.o55))
                        inline(item).foregroundStyle(theme.foreground.opacity(skin.opacity.o90))
                    }
                    .font(AinkradFontResolver.font(size: 13, typography: typography))
                }
            }
        case .codeBlock(let language, let code):
            codeBlock(code, language: language)
        case .table(let table):
            AinkradMarkdownTableView(table: table, typography: typography, inline: inline)
        case .blockQuote(let src):
            inline(src)
                .font(AinkradFontResolver.font(size: 13, typography: typography))
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o65))
                .padding(.leading, skin.size.s12)
                .overlay(alignment: .leading) {
                    Rectangle().fill(theme.accentPrimary).frame(width: skin.size.s2)
                }
        case .thematicBreak:
            Rectangle()
                .fill(theme.foreground.opacity(skin.opacity.o12))
                .frame(height: skin.size.s1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, skin.spacing.xs)
        }
    }

    private func codeBlock(_ code: String, language: String?) -> AinkradCodeBlock {
        var block = AinkradCodeBlock(code, language: language)
        block.usesReplyStyle = usesReplyStyle
        return block
    }

    /// Resolves inline markdown (bold/italic/`code`/links) through a shared
    /// bounded cache — see `AinkradInlineMarkdownCache` for why. Never throws into
    /// the view; unparseable source renders as itself.
    private func inline(_ src: String) -> Text {
        let attributed = AinkradInlineMarkdownCache.attributed(src)
        return Text(usesReplyStyle ? codeChips(attributed) : attributed)
    }

    /// Inline code runs as chips. A Text run cannot be padded or rounded, so a
    /// thin space either side carries the fill past the glyphs (the mockup's
    /// chip is square under Neon anyway).
    private func codeChips(_ source: AttributedString) -> AttributedString {
        let fill =
            skin.usesNativeGlass
            ? skin.color(skin.palette.white).opacity(skin.opacity.o06) : theme.surfaceElevated.opacity(skin.opacity.o60)
        var out = AttributedString()
        for run in source.runs {
            var piece = AttributedString(source[run.range])
            if run.inlinePresentationIntent?.contains(.code) == true {
                piece = AttributedString("\u{2009}") + piece + AttributedString("\u{2009}")
                piece.font = AinkradFontResolver.font(size: 11.5, mono: true, typography: typography)
                piece.foregroundColor = theme.accentSecondary
                piece.backgroundColor = fill
            }
            out += piece
        }
        return out
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 18
        case 2: return 16
        default: return 14
        }
    }
}
