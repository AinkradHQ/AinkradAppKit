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
                    HStack(alignment: .top, spacing: skin.size.s6) {
                        Text("\(idx + 1).").foregroundStyle(theme.accentSecondary)
                        inline(item).foregroundStyle(theme.foreground.opacity(skin.opacity.o90))
                    }
                    .font(AinkradFontResolver.font(size: 13, typography: typography))
                }
            }
        case .codeBlock(let language, let code):
            AinkradCodeBlock(code, language: language)
        case .thematicBreak:
            Rectangle()
                .fill(theme.foreground.opacity(skin.opacity.o12))
                .frame(height: skin.size.s1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, skin.spacing.xs)
        }
    }

    /// Resolves inline markdown (bold/italic/`code`/links) through a shared
    /// bounded cache — see `AinkradInlineMarkdownCache` for why. Never throws into
    /// the view; unparseable source renders as itself.
    private func inline(_ src: String) -> Text {
        Text(AinkradInlineMarkdownCache.attributed(src))
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 18
        case 2: return 16
        default: return 14
        }
    }
}
