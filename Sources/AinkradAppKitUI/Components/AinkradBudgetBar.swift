import AinkradAppKitContract
import SwiftUI

/// Where a budget stands against its warn mark and its hard limit.
public enum AinkradBudgetLevel: Equatable, Sendable {
    case ok, warning, over
}

/// The bar's fill (`value / limit`, clamped to `0...1`) and level: `.over` at
/// or past the limit, `.warning` at or past `warnFraction`. A non-positive
/// `limit` is an empty `.ok` bar. Pure — `AinkradBudgetBar`'s math.
public func budgetBarState(value: Double, limit: Double, warnFraction: Double?) -> (
    fraction: Double, level: AinkradBudgetLevel
) {
    guard limit > 0 else { return (0, .ok) }
    let ratio = value / limit
    let level: AinkradBudgetLevel =
        ratio >= 1 ? .over : (warnFraction.map { ratio >= $0 } ?? false) ? .warning : .ok
    return (max(0, min(ratio, 1)), level)
}

/// A budget or quota as a thin linear bar: the fill in the secondary accent,
/// amber past the warn mark, red at the limit, with an amber tick at the warn
/// mark and a red tick at the hard limit — the marks are data, not dividers
/// (Citadel cost 09, home 02). `tone` fixes the fill colour instead (a
/// subscription's violet). The fill eases to a new value; Reduce Motion sets it.
public struct AinkradBudgetBar: View {
    private let label: String
    private let value: Double
    private let limit: Double
    private let warnFraction: Double?
    private let showsHardLimit: Bool
    private let tone: AinkradChartTone?
    private let isThick: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - label: what VoiceOver reads ("Company · October") and the hover tooltip's start.
    ///   - warnFraction: where the amber tick sits (`0.8` = 80 %); `nil` draws none.
    ///   - showsHardLimit: draws the red tick at the limit.
    ///   - tone: a fixed fill colour; `nil` follows the level.
    ///   - isThick: the 10 pt bar of a hero card instead of 6 pt.
    public init(
        label: String, value: Double, limit: Double, warnFraction: Double? = 0.8, showsHardLimit: Bool = true,
        tone: AinkradChartTone? = nil, isThick: Bool = false
    ) {
        self.label = label
        self.value = value
        self.limit = limit
        self.warnFraction = warnFraction
        self.showsHardLimit = showsHardLimit
        self.tone = tone
        self.isThick = isThick
    }

    private var state: (fraction: Double, level: AinkradBudgetLevel) {
        budgetBarState(value: value, limit: limit, warnFraction: warnFraction)
    }

    private var fillColor: Color {
        if let tone { return tone.color(skin) }
        switch state.level {
        case .ok: return theme.accentSecondary
        case .warning: return statusColors.warning
        case .over: return statusColors.danger
        }
    }

    public var body: some View {
        let height = isThick ? skin.size.s10 : skin.size.s6
        let track = Capsule(style: .continuous)
        track.fill(skin.color(skin.palette.white).opacity(skin.opacity.o08))
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    track.fill(fillColor).frame(width: proxy.size.width * state.fraction)
                }
            }
            .frame(height: height)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    if let warnFraction, warnFraction > 0, warnFraction < 1 {
                        tick(statusColors.warning).position(x: width * warnFraction, y: proxy.size.height / 2)
                    }
                    if showsHardLimit {
                        // The mockups' `left: 99.5%`: inside the bar's end.
                        tick(statusColors.danger).position(x: width - skin.size.s2, y: proxy.size.height / 2)
                    }
                }
            }
            .frame(height: skin.size.s12)
            .animation(reduceMotion ? nil : skin.animation(skin.motion.materializeAnimation), value: state.fraction)
            .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: state.level)
            .help(helpText)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityValue(accessibilityValue)
    }

    /// A 2 × 12 pt mark on a 1.5 pt ring of the window colour, so it reads over the fill.
    private func tick(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: skin.size.s1)
            .fill(color)
            .frame(width: skin.size.s2, height: skin.size.s12)
            .padding(skin.size.s1_5)
            .background(
                RoundedRectangle(cornerRadius: skin.size.s2).fill(theme.background.opacity(skin.opacity.o90))
            )
            .accessibilityHidden(true)
    }

    private var percent: Int { limit > 0 ? Int((value / limit * 100).rounded()) : 0 }

    private var helpText: String {
        "\(label): \(percent)%" + (warnFraction.map { " · warns at \(Int(($0 * 100).rounded()))%" } ?? "")
    }

    private var accessibilityValue: String {
        let level =
            switch state.level {
            case .ok: ""
            case .warning: ", past the warning mark"
            case .over: ", at the limit"
            }
        return "\(percent) percent\(level)"
    }
}

/// A secret the log never saw: a lock and the secret's name in amber mono on
/// an amber wash (Citadel run 05). `reason` is the hover tooltip ("Redacted
/// before it was written to the log").
public struct AinkradRedactedChip: View {
    private let name: String
    private let reason: String?
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    public init(_ name: String, reason: String? = nil) {
        self.name = name
        self.reason = reason
    }

    public var body: some View {
        HStack(spacing: skin.size.s4) {
            Image(systemName: "lock.fill").imageScale(.small)
            Text(name)
        }
        .font(skin.font(AinkradFontToken(sizeKey: "t10_5", mono: "family")))
        .foregroundStyle(statusColors.warning)
        .padding(.horizontal, skin.size.s6)
        .padding(.vertical, skin.size.s1)
        .background(
            RoundedRectangle(cornerRadius: skin.size.s4, style: .continuous)
                .fill(statusColors.warning.opacity(hovering ? skin.opacity.o20 : skin.opacity.o12))
        )
        .fixedSize()
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : skin.animation(skin.motion.hover), value: hovering)
        .help(reason ?? "")
        .accessibilityElement()
        .accessibilityLabel("Redacted secret: \(name)")
        .accessibilityHint(reason ?? "")
    }
}

/// A list row that is still loading: an avatar circle, a text bar of
/// `widthFraction` of the free width, and a short trailing bar, under a slow
/// shimmer (Citadel 11 first load). The shimmer runs on the motion budget and
/// stands still under Reduce Motion. VoiceOver reads one "Loading".
public struct AinkradSkeletonRow: View {
    private let widthFraction: Double
    private let showsAvatar: Bool
    private let showsTrailing: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(widthFraction: Double = 1, showsAvatar: Bool = true, showsTrailing: Bool = true) {
        self.widthFraction = max(0, min(widthFraction, 1))
        self.showsAvatar = showsAvatar
        self.showsTrailing = showsTrailing
    }

    public var body: some View {
        Group {
            if reduceMotion {
                row(phase: 0.5)
            } else {
                BudgetedTimelineView { date in
                    // One sweep every 1.4 s, as the mockup's `shimmer`.
                    row(phase: date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.4) / 1.4)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }

    private func row(phase: Double) -> some View {
        HStack(spacing: skin.size.s10) {
            if showsAvatar {
                Circle().fill(shimmer(phase)).frame(width: skin.size.s24, height: skin.size.s24)
            }
            GeometryReader { proxy in
                bar(phase).frame(width: proxy.size.width * widthFraction, height: skin.size.s12)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: skin.size.s24)
            if showsTrailing {
                bar(phase).frame(width: skin.size.s60, height: skin.size.s12)
            }
        }
    }

    private func bar(_ phase: Double) -> some View {
        RoundedRectangle(cornerRadius: skin.size.s4, style: .continuous).fill(shimmer(phase))
    }

    /// The mockup's 5 % → 11 % → 5 % white band, swept left to right.
    private func shimmer(_ phase: Double) -> LinearGradient {
        let white = skin.color(skin.palette.white)
        let start = UnitPoint(x: -1.5 + 2 * phase, y: 0.5)
        return LinearGradient(
            colors: [
                white.opacity(skin.opacity.o05), white.opacity(skin.opacity.o12), white.opacity(skin.opacity.o05),
            ],
            startPoint: start, endPoint: UnitPoint(x: start.x + 2, y: 0.5))
    }
}
