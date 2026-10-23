import AinkradAppKitContract
import SwiftUI

/// Who wrote a chat message.
public enum AinkradChatRole: Equatable, Sendable {
    /// The person: a tinted card on the right.
    case user
    /// An agent: its reply on the left, markdown in the reply style, beside an optional avatar.
    case agent
}

/// One message of an agent conversation.
///
/// - `.user`: the person's message as a primary-tinted card on the right, its
///   attachments as chips above the text. Prose stays one hugging `Text`
///   (inline markdown only); a code block, list or table takes the kit's
///   markdown renderer.
/// - `.agent`: the reply as `AinkradMarkdownText` in the reply style (inline
///   code as cyan chips, quiet fenced code), up to 860 pt wide, after the
///   `avatar`.
///
/// `author` and `meta` add a header ("You · 09:40", "Quill · Writer · 10:02");
/// without them the message stands alone, as Grimoire's transcript shows it.
/// Lifted from Grimoire so Grimoire and Citadel share one bubble.
public struct AinkradChatBubble<Avatar: View>: View {
    private let text: String
    private let role: AinkradChatRole
    private let attachments: [String]
    private let author: String?
    private let meta: String?
    private let avatar: Avatar
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme

    /// - Parameter attachments: names of files sent with a user message, shown as chips.
    public init(
        text: String, role: AinkradChatRole, attachments: [String] = [], author: String? = nil, meta: String? = nil,
        @ViewBuilder avatar: () -> Avatar
    ) {
        self.text = text
        self.role = role
        self.attachments = attachments
        self.author = author
        self.meta = meta
        self.avatar = avatar()
    }

    public var body: some View {
        switch role {
        case .user: userBody
        case .agent: agentBody
        }
    }

    private var userBody: some View {
        HStack {
            Spacer(minLength: skin.size.s120)
            VStack(alignment: .trailing, spacing: skin.size.s6) {
                header
                VStack(alignment: .trailing, spacing: skin.size.s8) {
                    if !attachments.isEmpty {
                        ChatFlowLayout(spacing: skin.size.s6) {
                            ForEach(Array(attachments.enumerated()), id: \.offset) { _, name in
                                AinkradChip(label: name, systemName: "photo").fixedSize()
                            }
                        }
                    }
                    userMessage
                }
                .textSelection(.enabled)
                .padding(.horizontal, skin.size.s14)
                .padding(.vertical, skin.size.s10)
                .background(skin.shape(cut: AinkradRadius.md).fill(theme.accentPrimary.opacity(skin.opacity.o22)))
                .overlay(
                    skin.shape(cut: AinkradRadius.md).stroke(
                        theme.accentPrimary.opacity(skin.opacity.o55), lineWidth: 1))
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var userMessage: some View {
        let blocks = AinkradMarkdownBlocks.parse(text)
        if blocks.allSatisfy({ if case .paragraph = $0 { true } else { false } }) {
            Text(
                (try? AttributedString(
                    markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                    ?? AttributedString(text)
            )
            .font(skin.font(AinkradFontToken(sizeKey: "t13")))
            .foregroundStyle(theme.foreground.opacity(skin.opacity.o95))
        } else {
            AinkradMarkdownText(blocks: blocks)
        }
    }

    private var agentBody: some View {
        HStack(alignment: .top, spacing: skin.size.s10) {
            avatar
            VStack(alignment: .leading, spacing: skin.size.s4) {
                header
                AinkradMarkdownText(text: text)
                    .replyStyle()
                    .textSelection(.enabled)
            }
            .frame(maxWidth: skin.size.s860, alignment: .leading)
        }
        .accessibilityElement(children: .contain)
    }

    /// "Author · meta": the author in semibold, the meta faint.
    @ViewBuilder private var header: some View {
        if author != nil || meta != nil {
            HStack(spacing: skin.size.s4) {
                if let author {
                    Text(author)
                        .font(skin.font(AinkradFontToken(sizeKey: "t12", weight: "semibold")))
                        .foregroundStyle(theme.foreground.opacity(skin.opacity.o90))
                }
                if let meta {
                    Text(author == nil ? meta : "· \(meta)")
                        .font(skin.font(AinkradFontToken(sizeKey: "t11")))
                        .foregroundStyle(skin.color(skin.text.faint))
                }
            }
        }
    }
}

extension AinkradChatBubble where Avatar == EmptyView {
    /// A message with no avatar.
    public init(
        text: String, role: AinkradChatRole = .user, attachments: [String] = [], author: String? = nil,
        meta: String? = nil
    ) {
        self.init(text: text, role: role, attachments: attachments, author: author, meta: meta) { EmptyView() }
    }
}

/// Lays its children out in rows, wrapping only between them; each centred in
/// its row's height. Grimoire's `FlowLayout`, for the bubble's attachment chips.
struct ChatFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, point) in zip(subviews, arrange(width: bounds.width, subviews).points) {
            subview.place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), anchor: .leading,
                proposal: .unspecified)
        }
    }

    /// Each subview's leading-centre point.
    private func arrange(width: CGFloat, _ subviews: Subviews) -> (points: [CGPoint], size: CGSize) {
        var rows: [[(x: CGFloat, height: CGFloat)]] = [[]]
        var x: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append((x, size.height))
            x += size.width + spacing
            widest = max(widest, x - spacing)
        }
        var points: [CGPoint] = []
        var y: CGFloat = 0
        for row in rows where !row.isEmpty {
            let height = row.map(\.height).max() ?? 0
            points += row.map { CGPoint(x: $0.x, y: y + height / 2) }
            y += height + spacing
        }
        return (points, CGSize(width: widest, height: max(y - spacing, 0)))
    }
}
