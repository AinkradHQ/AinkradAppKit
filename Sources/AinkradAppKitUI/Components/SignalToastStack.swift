import AinkradAppKitContract
import AinkradSignal
import SwiftUI

/// A stack of transient toasts; the host places it top-trailing, under the bell.
///
/// Each toast is its own layer with its own transition, so the stack settles as
/// separated live layers rather than one image sliding — the host's motion rule.
public struct SignalToastStack: View {
    public let model: SignalToastModel
    public var now: Date = Date()
    public var onActivate: (SignalEvent) -> Void = { _ in }
    /// Runs an action the user chose from the toast itself.
    public var onAction: (SignalEvent, SignalAction) -> Void = { _, _ in }

    /// Explicit, because a public struct's implicit memberwise
    /// initialiser is INTERNAL — the components were public and
    /// unconstructible outside the module until this existed.
    public init(
        model: SignalToastModel,
        now: Date = Date(),
        onActivate: @escaping (SignalEvent) -> Void = { _ in }
    ) {
        self.model = model
        self.now = now
        self.onActivate = onActivate
    }

    /// Separate, not a defaulted parameter — library evolution, same reason as
    /// `SignalFeedRow`'s.
    public init(
        model: SignalToastModel,
        now: Date,
        onActivate: @escaping (SignalEvent) -> Void,
        onAction: @escaping (SignalEvent, SignalAction) -> Void
    ) {
        self.model = model
        self.now = now
        self.onActivate = onActivate
        self.onAction = onAction
    }

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @Environment(\.ainkradSignalIdentity) private var identities
    @State private var hovered: UUID?
    /// Toasts showing their whole body. An expanded toast holds its clock:
    /// the user asked to read it, so it must not leave mid-sentence.
    @State private var expanded: Set<UUID> = []
    /// Toasts whose body does not fit on one line, measured, not guessed from
    /// a character count, so the chevron appears exactly when text is cut.
    @State private var overflowing: Set<UUID> = []

    public var body: some View {
        let tokens = skin.components.signalToast
        VStack(alignment: .trailing, spacing: tokens.stackGap) {
            ForEach(model.visible) { event in
                toast(event)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                // Shrinking away toward the corner the bell lives
                                // in: the dismissal is where the user learns that
                                // notifications go somewhere rather than vanish.
                                removal: .opacity.combined(with: .scale(scale: tokens.removalScale))
                                    .combined(with: .offset(x: 40, y: -60))))
            }
            // Below the stack, not above it: the chip counts what is WAITING,
            // so it belongs after the toasts it is queued behind. Above them it
            // read as a badge hanging off whatever sits over the stack.
            if model.overflowCount > 0 {
                AinkradBadge(
                    text: "+\(model.overflowCount) more",
                    tint: skin.color(skin.palette.accentSecondary)
                )
                .transition(.opacity)
            }
        }
        .padding(tokens.stackPadding)
        .animation(
            reduceMotion ? nil : skin.animation(tokens.listSpring),
            value: model.visible.map(\.id)
        )
        .animation(
            reduceMotion ? nil : skin.animation(tokens.listSpring),
            value: model.overflowCount)
    }

    /// A thin remaining-time hairline. Only while hovered — a countdown on
    /// every toast would be a row of progress bars competing with the words.
    @ViewBuilder
    private func dwellBar(_ event: SignalEvent) -> some View {
        if hovered == event.id,
            let fraction = model.remainingFraction(
                id: event.id, severity: event.severity,
                now: now)
        {
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        skin.color(
                            skin.components.signalToast.dwellBarColor,
                            tint: SignalPresentation.color(
                                for: event.severity, in: AinkradStatusColors(skin: skin)))
                    )
                    .frame(width: geo.size.width * fraction, height: skin.components.signalToast.dwellBarHeight)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: skin.components.signalToast.dwellBarHeight)
            .allowsHitTesting(false)
        }
    }

    /// An action as an icon: the toast is too narrow for labelled chips
    /// beside its text. The label becomes the tooltip and the accessible name.
    /// An action without a symbol gets a generic one.
    private func toastAction(_ event: SignalEvent, _ action: SignalAction) -> some View {
        let statusColors = AinkradStatusColors(skin: skin)
        let tint = action.isDestructive ? statusColors.danger : HostThemeTokens(skin: skin).accentPrimary
        let tokens = skin.components.signalToast
        let actionShape = AinkradSkinShape(token: tokens.actionShape)
        return Button {
            onAction(event, action)
        } label: {
            Image(systemName: action.symbol ?? "arrow.up.forward.circle")
                .font(skin.font(tokens.actionFont, typography: typo))
                .foregroundStyle(tint)
                .frame(width: tokens.actionWidth, height: tokens.actionHeight)
                .background(actionShape.fill(skin.color(tokens.actionFill, tint: tint)))
                .overlay(
                    actionShape.strokeBorder(
                        skin.color(tokens.actionStroke.color, tint: tint),
                        lineWidth: tokens.actionStroke.width.resolve([]))
                )
                .contentShape(actionShape)
        }
        .buttonStyle(.plain)
        .help(action.label)
        .accessibilityLabel(action.label)
    }

    /// The severity colour, from the same mapping feed rows use, so an info
    /// event reads the same in a toast and in the dropdown.
    private func accent(_ event: SignalEvent) -> Color {
        SignalPresentation.status(for: event.severity).color(
            in: HostThemeTokens(skin: skin), statusColors: AinkradStatusColors(skin: skin))
    }

    /// The sending app's launcher icon, large, as the toast's anchor. Without
    /// a resolver (a plugin hosting the stack itself) it falls back to the
    /// severity glyph.
    @ViewBuilder
    private func leadingIcon(_ event: SignalEvent) -> some View {
        let tokens = skin.components.signalToast
        if let identity = identities.identity(for: event.source) {
            AinkradAppTile(symbol: identity.symbol, size: tokens.appTileSize)
                .allowsHitTesting(false)
                .accessibilityLabel(identity.name)
        } else {
            Image(systemName: SignalPresentation.iconSymbol(for: event.severity))
                .font(skin.font(tokens.fallbackGlyphFont, typography: typo))
                .foregroundStyle(accent(event))
                .frame(width: tokens.fallbackGlyphSize, height: tokens.fallbackGlyphSize)
        }
    }

    private func bodyText(_ event: SignalEvent) -> Text {
        let tokens = skin.components.signalToast
        return Text(event.body.flatMap { $0.isEmpty ? nil : $0 } ?? " ")
            .font(skin.font(tokens.bodyFont, typography: typo))
            .foregroundStyle(skin.color(tokens.bodyColor))
    }

    private func toggleExpanded(_ event: SignalEvent) {
        if expanded.contains(event.id) {
            collapse(event.id)
            if hovered != event.id { model.resume(id: event.id) }
        } else {
            expanded.insert(event.id)
            model.pause(id: event.id)
        }
    }

    private func collapse(_ id: UUID) {
        expanded.remove(id)
        overflowing.remove(id)
    }

    /// Two on the toast and the rest behind "⋯": the same set the feed row
    /// offers, so one event never offers different things in two places.
    @ViewBuilder
    private func actionRow(_ event: SignalEvent) -> some View {
        let tokens = skin.components.signalToast
        let actionShape = AinkradSkinShape(token: tokens.actionShape)
        let more = Array(event.actions.dropFirst(2))
        HStack(spacing: AinkradSpacing.xs + 1) {
            ForEach(Array(event.actions.prefix(2)), id: \.id) { action in toastAction(event, action) }
            if !more.isEmpty {
                AinkradMenuButton(
                    items: more.map { action in
                        AinkradMenuItem(title: action.label, isDestructive: action.isDestructive) {
                            onAction(event, action)
                        }
                    }
                ) {
                    Image(systemName: "ellipsis")
                        .font(skin.font(tokens.moreFont, typography: typo))
                        .foregroundStyle(skin.color(tokens.moreColor))
                        .frame(width: tokens.moreWidth, height: tokens.moreHeight)
                        .background(actionShape.fill(skin.color(tokens.moreFill)))
                }
            }
        }
    }

    private func toast(_ event: SignalEvent) -> some View {
        let tokens = skin.components.signalToast
        let shape = AinkradSkinShape(token: tokens.shape)
        let accent = accent(event)
        let repeats = model.repeatCount(for: event.id)
        let isHovered = hovered == event.id
        let strokeState: AinkradControlState = isHovered ? [.hover] : []
        return HStack(alignment: .top, spacing: AinkradSpacing.sm + 2) {
            leadingIcon(event)
            VStack(alignment: .leading, spacing: tokens.contentGap) {
                // Who: the thing it is about (the chat's service, when the
                // link names one) and the title. When, and the way out, trail.
                HStack(spacing: AinkradSpacing.xs + 1) {
                    if let symbol = event.deepLink?.symbol {
                        Image(systemName: symbol)
                            .font(skin.font(tokens.titleGlyphFont, typography: typo))
                            .foregroundStyle(skin.color(skin.palette.accentSecondary))
                    }
                    Text(event.title)
                        .font(skin.font(tokens.titleFont, typography: typo))
                        .foregroundStyle(skin.color(skin.text.primary))
                        .lineLimit(1)
                    if repeats > 1 {
                        Text("×\(repeats)")
                            .font(skin.font(tokens.repeatFont, typography: typo))
                            .monospacedDigit()
                            .foregroundStyle(skin.color(skin.palette.accentSecondary))
                    }
                    Spacer(minLength: skin.spacing.xs)
                    Text(SignalPresentation.relativeTime(event.timestamp, now: now))
                        .font(skin.font(tokens.timeFont, typography: typo))
                        .foregroundStyle(skin.color(tokens.timeColor))
                    if overflowing.contains(event.id) || expanded.contains(event.id) {
                        Button {
                            toggleExpanded(event)
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(skin.font(tokens.chevronCloseFont, typography: typo))
                                .foregroundStyle(skin.color(tokens.chevronCloseColor, state: strokeState))
                                .rotationEffect(.degrees(expanded.contains(event.id) ? 180 : 0))
                                .frame(width: tokens.chevronCloseSize, height: tokens.chevronCloseSize)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(expanded.contains(event.id) ? "Show less" : "Show the whole message")
                    }
                    Button {
                        collapse(event.id)
                        model.dismiss(id: event.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(skin.font(tokens.chevronCloseFont, typography: typo))
                            .foregroundStyle(skin.color(tokens.chevronCloseColor, state: strokeState))
                            .frame(width: tokens.chevronCloseSize, height: tokens.chevronCloseSize)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss")
                }
                // What, with the actions under the ✕ while the pointer is on
                // the tokens. They float over the text's end rather than take
                // a row, so nothing reflows when they appear.
                // The actions sit beside the text, under ✕, shown while
                // hovered; their space is reserved so nothing moves.
                HStack(alignment: .top, spacing: AinkradSpacing.xs + 2) {
                    bodyText(event)
                        .lineLimit(expanded.contains(event.id) ? 30 : 1)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Measure the body's natural height against one
                        // line's: the same text, laid out unclamped, invisible.
                        .background {
                            GeometryReader { oneLine in
                                bodyText(event)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(width: oneLine.size.width, alignment: .leading)
                                    .hidden()
                                    .background(
                                        GeometryReader { full in
                                            Color.clear.preference(
                                                key: ToastBodyOverflowKey.self,
                                                value: full.size.height
                                                    > (expanded.contains(event.id) ? 0 : oneLine.size.height) + 1
                                                    ? [event.id] : [])
                                        })
                            }
                            .allowsHitTesting(false)
                        }
                    // Always laid out, only faded: appearing on hover made the
                    // toast grow and its text re-truncate under the pointer.
                    if !event.actions.isEmpty {
                        actionRow(event)
                            .opacity(isHovered ? 1 : 0)
                            .allowsHitTesting(isHovered)
                    }
                }
            }
        }
        .padding(.leading, AinkradSpacing.sm + 3)
        .padding(.trailing, AinkradSpacing.sm + 2)
        .padding(.vertical, AinkradSpacing.sm + 1)
        // A fixed width, not content-sized: a stack of toasts with ragged
        // right edges reads as a layout accident rather than one surface.
        .frame(width: tokens.width, alignment: .leading)
        // Chamfered and accent-stroked like every other Ainkrad surface; a
        // continuous rounded rectangle read as a foreign toast library.
        .background(shape.fill(skin.color(tokens.fill)))
        .overlay(
            shape.strokeBorder(
                event.severity == .failure
                    ? skin.color(tokens.failureStrokeColor, tint: accent)
                    : skin.color(tokens.stroke.color, tint: accent, state: strokeState),
                lineWidth: tokens.stroke.width.resolve(strokeState))
        )
        // Severity as an edge, not a second icon: the app icon says who, the
        // edge says how bad. Info has none, so a quiet message stays quiet.
        .overlay(alignment: .leading) {
            if event.severity != .info {
                Capsule().fill(accent).frame(width: tokens.severityEdgeWidth).padding(
                    .vertical, tokens.severityEdgePadding
                )
                .shadow(
                    color: skin.color(tokens.severityEdgeGlow.color, tint: accent),
                    radius: tokens.severityEdgeGlow.radius.resolve([]))
            }
        }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: isHovered)
        .animation(
            reduceMotion ? nil : skin.animation(tokens.expandSpring),
            value: expanded.contains(event.id)
        )
        .onPreferenceChange(ToastBodyOverflowKey.self) { ids in
            if ids.contains(event.id) {
                overflowing.insert(event.id)
            } else if !expanded.contains(event.id) {
                overflowing.remove(event.id)
            }
        }
        // The clock stops while the pointer is over it: an eight-second
        // warning expiring mid-read is the most irritating thing a toast does.
        .onHover { isOver in
            hovered = isOver ? event.id : nil
            if isOver { model.pause(id: event.id) } else if !expanded.contains(event.id) { model.resume(id: event.id) }
        }
        .overlay(alignment: .bottom) { dwellBar(event) }
        .contentShape(shape)
        .onTapGesture { onActivate(event) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            SignalPresentation.accessibilityLabel(
                for: event, repeatCount: model.repeatCount(for: event.id), isUnread: true, now: now)
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onActivate(event) }
        .accessibilityActions {
            ForEach(event.actions, id: \.id) { action in
                Button(action.label) { onAction(event, action) }
            }
            Button("Dismiss") { model.dismiss(id: event.id) }
        }
    }
}

/// Ids of toasts whose body is taller than the line it is clamped to.
private struct ToastBodyOverflowKey: PreferenceKey {
    static let defaultValue: Set<UUID> = []
    static func reduce(value: inout Set<UUID>, nextValue: () -> Set<UUID>) { value.formUnion(nextValue()) }
}
