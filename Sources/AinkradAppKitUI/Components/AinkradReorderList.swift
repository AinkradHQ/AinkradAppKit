import AinkradAppKitContract
import SwiftUI
import UniformTypeIdentifiers

/// `items` with the element at `from` moved to `to` (both clamped). Pure —
/// `AinkradReorderList`'s drag and its VoiceOver move actions.
public func reorderedItems<T>(_ items: [T], moving from: Int, to: Int) -> [T] {
    guard items.indices.contains(from) else { return items }
    var result = items
    let item = result.remove(at: from)
    result.insert(item, at: max(0, min(to, result.count)))
    return result
}

/// An ordered list the person drags to reorder (Citadel project settings 14
/// repo cards, accounts 15 fallback chain): each entry a card with a ⠿ grip,
/// an optional 1-based number in the accent mono, and the caller's content.
/// Hover lifts a card 1 pt and brightens it; the `current` entry has an
/// accent rim, `dimmed` ones recede. Neighbours slide apart with the kit
/// spring while a card is dragged. VoiceOver gets Move up / Move down actions.
public struct AinkradReorderList<Item: Identifiable, Row: View>: View {
    @Binding private var items: [Item]
    private let isNumbered: Bool
    private let current: Item.ID?
    private let dimmed: Set<Item.ID>
    private let row: (Item) -> Row
    @State private var dragging: Item.ID?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - isNumbered: shows each entry's position (a fallback chain's 1, 2, 3).
    ///   - current: the entry in use, drawn with an accent rim ("now").
    ///   - dimmed: entries that recede (a provider that is down).
    public init(
        items: Binding<[Item]>, isNumbered: Bool = false, current: Item.ID? = nil, dimmed: Set<Item.ID> = [],
        @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self._items = items
        self.isNumbered = isNumbered
        self.current = current
        self.dimmed = dimmed
        self.row = row
    }

    /// Kit-internal: starts with `previewDragging` mid-drag, so the native
    /// sweep can shoot a drag the window server cannot be made to perform.
    init(
        items: Binding<[Item]>, isNumbered: Bool = false, current: Item.ID? = nil, dimmed: Set<Item.ID> = [],
        previewDragging: Item.ID?, @ViewBuilder row: @escaping (Item) -> Row
    ) {
        self.init(items: items, isNumbered: isNumbered, current: current, dimmed: dimmed, row: row)
        self._dragging = State(initialValue: previewDragging)
    }

    public var body: some View {
        VStack(spacing: skin.size.s6) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                KitReorderCard(
                    number: isNumbered ? index + 1 : nil, isCurrent: item.id == current,
                    isDimmed: dimmed.contains(item.id), isDragging: item.id == dragging
                ) {
                    row(item)
                }
                .onDrag {
                    dragging = item.id
                    return NSItemProvider(object: "\(index)" as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: KitReorderDropDelegate(target: item.id, items: $items, dragging: $dragging, move: move)
                )
                .accessibilityAction(named: "Move up") { move(item.id, by: -1) }
                .accessibilityAction(named: "Move down") { move(item.id, by: 1) }
                .accessibilityValue(isNumbered ? "Position \(index + 1) of \(items.count)" : "")
            }
        }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.present), value: items.map(\.id))
    }

    private func move(_ id: Item.ID, by delta: Int) {
        guard let from = items.firstIndex(where: { $0.id == id }) else { return }
        items = reorderedItems(items, moving: from, to: from + delta)
    }

    private func move(_ id: Item.ID, over target: Item.ID) {
        guard let from = items.firstIndex(where: { $0.id == id }),
            let to = items.firstIndex(where: { $0.id == target }), from != to
        else { return }
        items = reorderedItems(items, moving: from, to: to)
    }
}

/// Moves the dragged card as it enters each neighbour, so the list shows the
/// new order live; the drop only ends the drag.
private struct KitReorderDropDelegate<Item: Identifiable>: DropDelegate {
    let target: Item.ID
    @Binding var items: [Item]
    @Binding var dragging: Item.ID?
    let move: (Item.ID, Item.ID) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragging, dragging != target else { return }
        move(dragging, target)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }
}

/// One entry of `AinkradReorderList`: Neon a 6 pt chamfer card, Glass a 10 pt
/// continuous card, with the grip, the number and the content.
struct KitReorderCard<Content: View>: View {
    let number: Int?
    let isCurrent: Bool
    let isDimmed: Bool
    let isDragging: Bool
    @ViewBuilder let content: Content
    @State private var hovering = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    var body: some View {
        let shape =
            skin.usesNativeGlass
            ? AnyShape(RoundedRectangle(cornerRadius: skin.size.s10, style: .continuous))
            : AnyShape(skin.shape(cut: skin.size.s6))
        let rim =
            isCurrent
            ? theme.accentSecondary.opacity(skin.opacity.o70)
            : skin.usesNativeGlass
                ? skin.color(skin.palette.white).opacity(skin.opacity.o12)
                : theme.accentSecondary.opacity(skin.opacity.o45)
        HStack(alignment: .firstTextBaseline, spacing: skin.size.s8) {
            Text("⠿")
                .font(skin.font(AinkradFontToken(sizeKey: "t11")))
                .foregroundStyle(skin.color(hovering ? skin.text.muted : skin.text.faint))
                .accessibilityHidden(true)
            if let number {
                Text("\(number)")
                    .font(skin.font(AinkradFontToken(sizeKey: "t11", mono: "family")))
                    .foregroundStyle(theme.accentSecondary)
                    .frame(minWidth: skin.size.s10, alignment: .leading)
                    .accessibilityHidden(true)
            }
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, skin.size.s10)
        .padding(.vertical, skin.size.s8)
        .background(
            shape.fill(
                skin.usesNativeGlass
                    ? skin.color(skin.palette.white).opacity(skin.opacity.o06)
                    : theme.surfaceElevated.opacity(skin.opacity.o96))
        )
        .overlay(shape.stroke(rim, lineWidth: 1))
        .contentShape(shape)
        .opacity(isDimmed ? skin.opacity.o60 : (isDragging ? skin.opacity.o50 : 1))
        .brightness(hovering ? skin.opacity.o05 : 0)
        .offset(y: hovering && !reduceMotion ? -skin.size.s1 : 0)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
        .accessibilityElement(children: .combine)
    }
}
