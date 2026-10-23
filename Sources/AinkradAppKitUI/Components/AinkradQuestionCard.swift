import AinkradAppKitContract
import SwiftUI

/// An agent's question to the person (Citadel requirements 12): an amber card
/// with "asked by **Kestrel (Dev)** on CIT-62 · while estimating for S5" and
/// its age, the question (inline markdown), quick replies, and the route line
/// that says where an answer goes ("↪ Your answer goes to Kestrel on CIT-62
/// and wakes it — not to the CEO"). It slides in with one amber pulse of its
/// rim (none under Reduce Motion). The asker's avatar is the caller's.
public struct AinkradQuestionCard<Avatar: View>: View {
    private let asker: String
    private let issueKey: String?
    private let context: String?
    private let age: String?
    private let question: String
    private let replies: [String]
    private let route: String?
    private let onReply: (String) -> Void
    private let avatar: Avatar
    @State private var pulsing = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - asker: who asks, bold ("Kestrel (Dev)").
    ///   - issueKey: the issue it is asked on, in the accent mono ("CIT-62").
    ///   - context: what the agent was doing ("while estimating for S5").
    ///   - replies: quick answers; tapping one calls `onReply` with it.
    public init(
        asker: String, issueKey: String? = nil, context: String? = nil, age: String? = nil, question: String,
        replies: [String] = [], route: String? = nil, onReply: @escaping (String) -> Void = { _ in },
        @ViewBuilder avatar: () -> Avatar
    ) {
        self.asker = asker
        self.issueKey = issueKey
        self.context = context
        self.age = age
        self.question = question
        self.replies = replies
        self.route = route
        self.onReply = onReply
        self.avatar = avatar()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: skin.size.s8) {
            HStack(spacing: skin.size.s8) {
                avatar
                fromLine
                Spacer(minLength: skin.size.s8)
                if let age {
                    Text(age)
                        .font(skin.font(AinkradFontToken(sizeKey: "t11", mono: "family")))
                        .foregroundStyle(skin.color(skin.text.faint))
                }
            }
            Text(markdown(question))
                .font(skin.font(AinkradFontToken(sizeKey: "t13")))
                .foregroundStyle(theme.foreground)
                .lineSpacing(skin.size.s3)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
            if !replies.isEmpty {
                ChatFlowLayout(spacing: skin.size.s6) {
                    ForEach(Array(replies.enumerated()), id: \.offset) { _, reply in
                        KitReplyChip(title: reply, tint: statusColors.warning) { onReply(reply) }
                    }
                }
            }
            if let route {
                Text("↪ \(route)")
                    .font(skin.font(AinkradFontToken(sizeKey: "t11")))
                    .foregroundStyle(statusColors.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, skin.size.s14)
        .padding(.vertical, skin.size.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitCardSurface(
            statusColors.warning.opacity(skin.opacity.o14), glass: statusColors.warning.opacity(skin.opacity.o07),
            rim: statusColors.warning.opacity(
                pulsing ? 1 : (skin.usesNativeGlass ? skin.opacity.o45 : skin.opacity.o65))
        )
        .onAppear {
            guard !reduceMotion else { return }
            pulsing = true
            withAnimation(skin.animation(skin.motion.materializeAnimation)) { pulsing = false }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Question from \(asker)")
    }

    private var fromLine: some View {
        var line = Text("asked by ").foregroundStyle(skin.color(skin.text.muted))
        line = line + Text(asker).fontWeight(.semibold).foregroundStyle(theme.foreground)
        if let issueKey {
            line = line + Text(" on ").foregroundStyle(skin.color(skin.text.muted))
            line =
                line
                + Text(issueKey).font(skin.font(AinkradFontToken(sizeKey: "t11", mono: "family")))
                .foregroundStyle(theme.accentSecondary)
        }
        if let context {
            line = line + Text(" · \(context)").foregroundStyle(skin.color(skin.text.muted))
        }
        return line.font(skin.font(AinkradFontToken(sizeKey: "t12"))).lineLimit(2)
    }
}

/// Inline markdown (bold, code) or the plain text when it does not parse.
func markdown(_ text: String) -> AttributedString {
    (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
        ?? AttributedString(text)
}

/// A quick reply: a small outlined chip in `tint` (Neon a 4 pt chamfer, Glass
/// a capsule) that fills with the primary accent on hover and press.
struct KitReplyChip: View {
    let title: String
    let tint: Color
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        let shape =
            skin.usesNativeGlass ? AnyShape(Capsule(style: .continuous)) : AnyShape(skin.shape(cut: skin.size.s4))
        Button(action: action) {  // design-lint: allow raw-control quick-reply chip
            Text(title)
                .font(skin.font(AinkradFontToken(sizeKey: "t12")))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)
                .padding(.horizontal, skin.size.s8)
                .padding(.vertical, skin.size.s3)
                .background(shape.fill(hovering ? theme.accentPrimary.opacity(skin.opacity.o30) : .clear))
                .overlay(shape.stroke(tint.opacity(hovering ? skin.opacity.o90 : skin.opacity.o60), lineWidth: 1))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
        .fixedSize()
    }
}

/// A change an agent proposes to a setting (Citadel project settings 14,
/// decision #48): who and what ("**Toma (Lead)** · Lint command" and an
/// optional tag such as the repo it touches), the diff — the old value struck
/// through in red, → the new in green — the reason, and Reject… / Accept. The
/// card is violet, the colour of the Lead role. The author's avatar is the caller's.
public struct AinkradProposalCard<Avatar: View>: View {
    private let author: String
    private let title: String
    private let tag: String?
    private let oldValue: String?
    private let newValue: String
    private let reason: String?
    private let onAccept: () -> Void
    private let onReject: () -> Void
    private let avatar: Avatar
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors

    /// - Parameters:
    ///   - oldValue: today's value; `nil` for an addition ("+ API changes regenerate…").
    ///   - newValue: the proposed value.
    public init(
        author: String, title: String, tag: String? = nil, oldValue: String? = nil, newValue: String,
        reason: String? = nil, onAccept: @escaping () -> Void, onReject: @escaping () -> Void,
        @ViewBuilder avatar: () -> Avatar
    ) {
        self.author = author
        self.title = title
        self.tag = tag
        self.oldValue = oldValue
        self.newValue = newValue
        self.reason = reason
        self.onAccept = onAccept
        self.onReject = onReject
        self.avatar = avatar()
    }

    private var violet: Color { skin.color(skin.palette.accentViolet) }

    public var body: some View {
        HStack(alignment: .top, spacing: skin.size.s10) {
            avatar
            // The buttons sit beside the title while it fits, else under the reason: the author never truncates.
            ViewThatFits(in: .horizontal) {
                content(wide: true)
                content(wide: false)
            }
        }
        .padding(.horizontal, skin.size.s12)
        .padding(.vertical, skin.size.s10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .kitCardSurface(
            violet.opacity(skin.opacity.o12), glass: violet.opacity(skin.opacity.o08),
            rim: violet.opacity(skin.usesNativeGlass ? skin.opacity.o40 : skin.opacity.o55)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Proposal from \(author): \(title)")
    }

    private func content(wide: Bool) -> some View {
        VStack(alignment: .leading, spacing: skin.size.s4) {
            HStack(spacing: skin.size.s8) {
                titleLine
                if wide {
                    Spacer(minLength: skin.size.s8)
                    buttons
                }
            }
            diffLine
            if let reason {
                Text(reason)
                    .font(skin.font(AinkradFontToken(sizeKey: "t12")))
                    .foregroundStyle(skin.color(skin.text.faint))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !wide {
                HStack {
                    Spacer(minLength: 0)
                    buttons
                }
                .padding(.top, skin.size.s4)
            }
        }
    }

    private var titleLine: some View {
        HStack(spacing: skin.size.s8) {
            (Text(author).fontWeight(.semibold) + Text(" · \(title)"))
                .font(skin.font(AinkradFontToken(sizeKey: "t12_5")))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)
                .fixedSize()
            if let tag {
                Text(tag)
                    .font(skin.font(AinkradFontToken(sizeKey: "t10_5", mono: "family")))
                    .foregroundStyle(theme.foreground)
                    .padding(.horizontal, skin.size.s6)
                    .padding(.vertical, skin.size.s1)
                    .background(
                        skin.color(skin.palette.white).opacity(skin.opacity.o07),
                        in: RoundedRectangle(cornerRadius: skin.size.s4, style: .continuous)
                    )
                    .fixedSize()
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: skin.size.s6) {
            AinkradButton(title: "Reject…", style: .ghost, action: onReject).borderless().secondaryAccent().compact()
            AinkradButton(title: "Accept", style: .primary, action: onAccept).compact()
        }
        .fixedSize()
    }

    private var diffLine: some View {
        var line = Text("")
        if let oldValue {
            line = Text(oldValue).strikethrough().foregroundStyle(statusColors.danger)
            line = line + Text("  →  ").foregroundStyle(skin.color(skin.text.muted))
        } else {
            line = Text("+ ").foregroundStyle(statusColors.success)
        }
        line = line + Text(newValue).foregroundStyle(statusColors.success)
        return
            line
            .font(skin.font(AinkradFontToken(sizeKey: "t11", mono: "family")))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(oldValue.map { "Change \($0) to \(newValue)" } ?? "Add \(newValue)")
    }
}
