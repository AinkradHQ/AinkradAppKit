import SwiftUI
import UniformTypeIdentifiers

/// One entry of an `AinkradChainEditor`. `kind` is an opaque key the editor hands to its `leading` view (a harness
/// name for a tag); `title` is the entry, `detail` the line under it (drawn in the warning colour when
/// `detailWarns`), `chip` a pill beside the title ("serving", "first").
public struct AinkradChainLink: Identifiable, Equatable {
    public let id: String
    public var kind: String
    public var title: String
    public var detail: String
    public var detailWarns: Bool
    public var chip: String?
    public var isCurrent: Bool
    /// Neither moved nor removed (the agent's own entry).
    public var isFixed: Bool

    public init(
        id: String, kind: String, title: String, detail: String, detailWarns: Bool = false, chip: String? = nil,
        isCurrent: Bool = false, isFixed: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.detailWarns = detailWarns
        self.chip = chip
        self.isCurrent = isCurrent
        self.isFixed = isFixed
    }
}

/// A fallback chain: a vertical rail behind numbered discs (the serving one in a gradient), rows that drag to
/// reorder and lift while dragged, and ✕ to remove. `editable: false` is the read-only list. `leading` draws each
/// entry's tag from its `kind`.
public struct AinkradChainEditor<Leading: View>: View {
    private let links: [AinkradChainLink]
    private let editable: Bool
    private let reorder: ([AinkradChainLink]) -> Void
    private let remove: (AinkradChainLink) -> Void
    private let leading: (String) -> Leading
    @State private var order: [AinkradChainLink]?
    @State private var dragging: String?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(
        links: [AinkradChainLink], editable: Bool = true, reorder: @escaping ([AinkradChainLink]) -> Void = { _ in },
        remove: @escaping (AinkradChainLink) -> Void = { _ in }, @ViewBuilder leading: @escaping (String) -> Leading
    ) {
        self.links = links
        self.editable = editable
        self.reorder = reorder
        self.remove = remove
        self.leading = leading
    }

    private var shown: [AinkradChainLink] { order ?? links }

    public var body: some View {
        VStack(spacing: skin.size.s8) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, link in
                row(link, number: index + 1)
                    .onDrag {
                        guard editable, !link.isFixed else { return NSItemProvider() }
                        dragging = link.id
                        order = links
                        return NSItemProvider(object: link.id as NSString)
                    }
                    .onDrop(
                        of: [UTType.text],
                        delegate: ChainDrop(
                            target: link, order: $order, dragging: $dragging, links: links, commit: reorder))
            }
        }
        .background(alignment: .topLeading) {
            LinearGradient(
                colors: [theme.accentSecondary, skin.color(.palette("foreground", skin.opacity.o08))],
                startPoint: .top, endPoint: .bottom
            )
            .frame(width: skin.size.s2)
            .padding(.vertical, skin.size.s20)
            .padding(.leading, editable ? skin.size.s46 : skin.size.s22)
        }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.present), value: shown.map(\.id))
        .onChange(of: links) { _, _ in order = nil }
    }

    private func row(_ link: AinkradChainLink, number: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: skin.size.s14, style: .continuous)
        let cyan = theme.accentSecondary
        let isDragging = dragging == link.id
        return HStack(spacing: skin.size.s10) {
            if editable {
                Text("⋮⋮").kitFont("t11").foregroundStyle(skin.color(skin.text.faint))
                    .frame(width: skin.size.s14).opacity(link.isFixed ? 0 : 1)
            }
            Text("\(number)").kitFont("t11", weight: "bold", mono: true)
                .foregroundStyle(skin.color(.palette("foreground", 1)))
                .frame(width: skin.size.s26, height: skin.size.s26)
                .background {
                    if link.isCurrent {
                        Circle().fill(
                            LinearGradient(
                                colors: [cyan, skin.color(skin.palette.accentPrimary)], startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                    } else {
                        Circle().fill(skin.color(.palette("background", skin.opacity.o90)))
                            .overlay(Circle().fill(skin.color(.palette("foreground", skin.opacity.o12))))
                    }
                }
                .overlay(Circle().strokeBorder(skin.color(.palette("background", 1)), lineWidth: skin.size.s3))
            VStack(alignment: .leading, spacing: skin.size.s2) {
                HStack(spacing: skin.size.s6) {
                    leading(link.kind)
                    Text(link.title).kitFont("t12_5", weight: "semibold")
                        .foregroundStyle(skin.color(skin.text.primary)).lineLimit(1)
                    if let chip = link.chip { AinkradStatePill(text: chip, tint: cyan) }
                }
                Text(link.detail).kitFont("t10_5")
                    .foregroundStyle(link.detailWarns ? skin.color(skin.palette.warning) : skin.color(skin.text.faint))
                    .lineLimit(1)
            }
            Spacer(minLength: skin.size.s4)
            if editable && !link.isFixed && links.count > 1 {
                AinkradTapArea(help: "Remove", action: { remove(link) }) {
                    Image(systemName: "xmark").kitFont("t10", weight: "semibold")
                        .foregroundStyle(skin.color(skin.text.faint))
                        .frame(width: skin.size.s22, height: skin.size.s22)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, skin.size.s10)
        .padding(.vertical, skin.size.s9)
        .background(
            shape.fill(
                isDragging
                    ? skin.color(.palette("background", skin.opacity.o98))
                    : link.isCurrent
                        ? cyan.opacity(skin.opacity.o07) : skin.color(.palette("foreground", skin.opacity.o05)))
        )
        .overlay(
            shape.strokeBorder(
                link.isCurrent ? cyan.opacity(skin.opacity.o45) : skin.color(.palette("foreground", skin.opacity.o07)),
                lineWidth: 1)
        )
        .shadow(
            color: isDragging ? skin.color(.palette("black", skin.opacity.o45)) : .clear, radius: skin.size.s14,
            y: skin.size.s14)
    }
}

/// Moves the dragged entry as it passes each neighbour; the drop commits the new order.
private struct ChainDrop: DropDelegate {
    let target: AinkradChainLink
    @Binding var order: [AinkradChainLink]?
    @Binding var dragging: String?
    let links: [AinkradChainLink]
    let commit: ([AinkradChainLink]) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target.id, !target.isFixed, var current = order,
            let from = current.firstIndex(where: { $0.id == dragging }),
            let to = current.firstIndex(where: { $0.id == target.id })
        else { return }
        current.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        order = current
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        if let order, order.map(\.id) != links.map(\.id) { commit(order) }
        dragging = nil
        return true
    }
}

/// A chain read left to right: a tag and a title per step joined by arrows, wrapping. `leading` draws each tag from
/// the step's `kind`.
public struct AinkradChainFlow<Leading: View>: View {
    private let steps: [(kind: String, title: String)]
    private let leading: (String) -> Leading
    @Environment(\.ainkradSkin) private var skin

    public init(steps: [(kind: String, title: String)], @ViewBuilder leading: @escaping (String) -> Leading) {
        self.steps = steps
        self.leading = leading
    }

    public var body: some View {
        AinkradFlowLayout(spacing: skin.size.s4, lineSpacing: skin.size.s6) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: skin.size.s4) {
                    if index > 0 {
                        Image(systemName: "arrow.right").kitFont("t10")
                            .foregroundStyle(skin.color(.palette("foreground", skin.opacity.o30)))
                    }
                    HStack(spacing: skin.size.s6) {
                        leading(step.kind)
                        Text(step.title).kitFont("t11").foregroundStyle(skin.color(skin.text.primary))
                            .lineLimit(1)
                    }
                    .padding(.leading, skin.size.s4)
                    .padding(.trailing, skin.size.s9)
                    .frame(height: skin.size.s30)
                    .background(
                        skin.color(.palette("black", skin.opacity.o20)),
                        in: RoundedRectangle(cornerRadius: skin.size.s9, style: .continuous))
                }
            }
        }
    }
}

/// Overlapping figures with a ring in the background colour between them.
public struct AinkradAvatarStack<Item: Identifiable, Face: View>: View {
    private let items: [Item]
    private let size: CGFloat
    private let face: (Item) -> Face
    @Environment(\.ainkradSkin) private var skin

    public init(items: [Item], size: CGFloat, @ViewBuilder face: @escaping (Item) -> Face) {
        self.items = items
        self.size = size
        self.face = face
    }

    public var body: some View {
        HStack(spacing: -size * 0.32) {
            ForEach(items) { item in
                face(item)
                    .frame(width: size, height: size)
                    .background(Circle().fill(skin.color(.palette("background", 1))).padding(-skin.size.s2))
            }
        }
    }
}
