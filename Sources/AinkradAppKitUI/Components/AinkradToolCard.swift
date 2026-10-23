import AinkradAppKitContract
import SwiftUI

/// Where a tool call stands; it colours the card's dot (and, waiting, its rim).
public enum AinkradToolCardStatus: Equatable, Sendable {
    /// Still running: the secondary accent.
    case running
    case succeeded
    case failed
    /// An approval for this call is pending: amber, "waiting for you", open.
    case waiting
}

/// The header's trailing result.
public enum AinkradToolCardResult: Equatable, Sendable {
    case none
    /// An edit's green +added / red −removed.
    case counts(added: Int, removed: Int)
    /// A success line in green — a command's "exit 0 · 48s".
    case success(String)
    /// A quiet summary ("412 lines", "2 secrets redacted"); red when the card failed.
    case summary(String)
}

/// What a header accessory is told: whether the header is hovered (to show a
/// "↗ Open" pill), and whether the card is wide enough for its long label.
public struct AinkradToolCardHeaderState: Equatable, Sendable {
    public let isHovered: Bool
    public let isWide: Bool

    public init(isHovered: Bool, isWide: Bool) {
        self.isHovered = isHovered
        self.isWide = isWide
    }
}

/// One tool call in an agent transcript: a dot, the tool's name, its argument
/// in mono, and its result, over a body (a diff, a command's output) that the
/// header expands and collapses. Waiting for an approval it turns amber and
/// stays open. Neon draws the mockups' 8 pt chamfer with the cyan rim; Glass a
/// 12 pt continuous card on the window's material with a white hairline.
///
/// Lifted from Grimoire's transcript so Grimoire and Citadel share one card:
/// the tool-specific parts — what the body shows, the "↗ Forge" pill — stay
/// with the caller as `detail` and `accessory`.
public struct AinkradToolCard<Detail: View, Accessory: View>: View {
    private let name: String
    private let argument: String
    private let status: AinkradToolCardStatus
    private let result: AinkradToolCardResult
    private let note: String?
    private let footnote: String?
    private let detail: Detail
    private let accessory: (AinkradToolCardHeaderState) -> Accessory
    @State private var isExpanded: Bool
    @State private var hovering = false
    @State private var isWide = true
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradTypography) private var typography
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - argument: the call's argument, one mono line truncated in the middle.
    ///   - note: a mono line under the header ("Rewritten by a hook from: …").
    ///   - footnote: a small line at the bottom (why an approval is asked).
    ///   - isInitiallyExpanded: whether `detail` shows at rest; it always shows while waiting.
    ///   - accessory: drawn between the argument and the result.
    public init(
        name: String, argument: String, status: AinkradToolCardStatus, result: AinkradToolCardResult = .none,
        note: String? = nil, footnote: String? = nil, isInitiallyExpanded: Bool = false,
        @ViewBuilder detail: () -> Detail,
        @ViewBuilder accessory: @escaping (AinkradToolCardHeaderState) -> Accessory
    ) {
        self.name = name
        self.argument = argument
        self.status = status
        self.result = result
        self.note = note
        self.footnote = footnote
        self.detail = detail()
        self.accessory = accessory
        _isExpanded = State(initialValue: isInitiallyExpanded)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: skin.size.s8) {
            header
            if let note {
                Text(note)
                    .font(AinkradFontResolver.font(size: 11, mono: true, typography: typography))
                    .foregroundStyle(skin.color(skin.text.faint))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if isExpanded || status == .waiting {
                detail
            }
            if let footnote {
                Text(footnote)
                    .font(skin.font(AinkradFontToken(sizeKey: "t11")))
                    .foregroundStyle(skin.color(skin.text.faint))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, skin.size.s12)
        .padding(.vertical, skin.size.s8)
        .frame(maxWidth: skin.size.s860, alignment: .leading)
        .onGeometryChange(for: Bool.self) {
            $0.size.width >= skin.size.s560
        } action: {
            isWide = $0
        }
        .kitCardSurface(
            theme.surface.opacity(skin.opacity.o85),
            rim: status == .waiting ? statusColors.warning.opacity(skin.opacity.o60) : nil)
    }

    /// The expander, then the accessory beside it rather than inside it, so each is its own keyboard stop.
    private var header: some View {
        HStack(spacing: skin.size.s8) {
            Button {  // design-lint: allow raw-control keyboard-reachable expander (kit has no disclosure row)
                isExpanded.toggle()
            } label: {
                headerLabel
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded || status == .waiting ? "Expanded" : "Collapsed")
            accessory(AinkradToolCardHeaderState(isHovered: hovering, isWide: isWide))
            resultLabel
                .contentShape(Rectangle())
                .onTapGesture { isExpanded.toggle() }
        }
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
    }

    private var headerLabel: some View {
        HStack(spacing: skin.size.s8) {
            Circle().fill(dotColor).frame(width: skin.size.s7, height: skin.size.s7)
                .accessibilityHidden(true)
            Text(name)
                .font(skin.font(AinkradFontToken(sizeKey: "t13", weight: "semibold")))
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o90))
                .fixedSize()  // never "Re ad": the argument gives way instead
            Text(argument)
                .font(AinkradFontResolver.font(size: 11, mono: true, typography: typography))
                .foregroundStyle(skin.color(skin.text.muted))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: skin.size.s8)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder private var resultLabel: some View {
        let font = skin.font(AinkradFontToken(sizeKey: "t11", monospacedDigits: true))
        if status == .waiting {
            Text("waiting for you").font(font).foregroundStyle(statusColors.warning)
        } else {
            switch result {
            case .none:
                EmptyView()
            case .counts(let added, let removed):
                HStack(spacing: skin.size.s4) {
                    Text("+\(added)").foregroundStyle(statusColors.success)
                    Text("−\(removed)").foregroundStyle(statusColors.danger)
                }
                .font(font)
            case .success(let text):
                Text(text).font(font).foregroundStyle(statusColors.success).lineLimit(1)
            case .summary(let text):
                Text(text)
                    .font(font)
                    .foregroundStyle(status == .failed ? statusColors.danger : skin.color(skin.text.faint))
                    .lineLimit(1)
            }
        }
    }

    private var dotColor: Color {
        switch status {
        case .waiting: statusColors.warning
        case .running: theme.accentSecondary
        case .failed: statusColors.danger
        case .succeeded: statusColors.success
        }
    }
}

extension AinkradToolCard where Accessory == EmptyView {
    /// A card with no header accessory.
    public init(
        name: String, argument: String, status: AinkradToolCardStatus, result: AinkradToolCardResult = .none,
        note: String? = nil, footnote: String? = nil, isInitiallyExpanded: Bool = false,
        @ViewBuilder detail: () -> Detail
    ) {
        self.init(
            name: name, argument: argument, status: status, result: result, note: note, footnote: footnote,
            isInitiallyExpanded: isInitiallyExpanded, detail: detail, accessory: { _ in EmptyView() })
    }
}

extension AinkradToolCard where Detail == EmptyView, Accessory == EmptyView {
    /// A one-line card with nothing to expand.
    public init(
        name: String, argument: String, status: AinkradToolCardStatus, result: AinkradToolCardResult = .none,
        note: String? = nil, footnote: String? = nil
    ) {
        self.init(
            name: name, argument: argument, status: status, result: result, note: note, footnote: footnote,
            detail: { EmptyView() })
    }
}

/// The mockups' `.cut` transcript card. Neon: an 8 pt chamfer, `fill`, and a
/// 1 pt rim (the cyan stroke unless the card has its own). Glass: a 12 pt
/// continuous card on the window's material, `glassFill` over it, and a white
/// 12 % hairline. Grimoire's `CardSurface`.
struct KitCardSurface: ViewModifier {
    let fill: Color
    var glassFill: Color?
    var rim: Color?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme

    @ViewBuilder func body(content: Content) -> some View {
        if skin.usesNativeGlass {
            let shape = RoundedRectangle(cornerRadius: skin.size.s12, style: .continuous)
            content
                .background {
                    shape.fill(.ultraThinMaterial).overlay(shape.fill(glassFill ?? fill))
                }
                .overlay(
                    shape.strokeBorder(rim ?? skin.color(skin.palette.white).opacity(skin.opacity.o12), lineWidth: 1))
        } else {
            let shape = skin.shape(cut: skin.size.s8)
            content
                .background(shape.fill(fill))
                .overlay(shape.strokeBorder(rim ?? theme.accentSecondary.opacity(skin.opacity.o45), lineWidth: 1))
        }
    }
}

extension View {
    func kitCardSurface(_ fill: Color, glass glassFill: Color? = nil, rim: Color? = nil) -> some View {
        modifier(KitCardSurface(fill: fill, glassFill: glassFill, rim: rim))
    }
}
