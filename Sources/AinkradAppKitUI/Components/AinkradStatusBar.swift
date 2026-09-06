import SwiftUI
import AinkradAppKitContract

/// How many of `segments` should read as "filled" for `value` out of `total`.
/// Clamps the ratio into `0...1` first (so overshoot/negative values never
/// under/overflow), then rounds to the nearest segment. A non-positive
/// `total` or `segments` yields `0`. Pure — `AinkradStatusBar`'s HP-bar
/// segment math, unit-testable without SwiftUI.
public func filledSegments(value: Double, total: Double, segments: Int) -> Int {
    guard total > 0, segments > 0 else { return 0 }
    let ratio = max(0, min(value / total, 1))
    return Int((ratio * Double(segments)).rounded())
}

/// Which color source an `AinkradStatusBar` fills with.
public enum AinkradStatusBarKind: Sendable {
    /// The host theme's primary accent.
    case accent
    /// One of `\.ainkradStatusColors`, via the shared `AinkradStatus` enum.
    case status(AinkradStatus)

    func color(theme: HostThemeTokens, statusColors: AinkradStatusColors) -> Color {
        switch self {
        case .accent: return theme.accentPrimary
        case .status(let status): return status.color(in: theme, statusColors: statusColors)
        }
    }
}

/// HP-bar-style segmented gauge — a row of small chamfered blocks, the
/// leading `filledSegments(value:total:segments:)` of them lit with a
/// gradient fill in `kind`'s color, the rest dimmed. Reads theme/status
/// colors from the environment.
public struct AinkradStatusBar: View {
    private let value: Double
    private let total: Double
    private let kind: AinkradStatusBarKind
    private let segments: Int

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(value: Double, total: Double = 1, kind: AinkradStatusBarKind = .accent, segments: Int = 12) {
        self.value = value
        self.total = total
        self.kind = kind
        self.segments = segments
    }

    private var filled: Int { filledSegments(value: value, total: total, segments: segments) }
    private var color: Color { kind.color(theme: theme, statusColors: statusColors) }

    public var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max(segments, 0), id: \.self) { index in
                let isFilled = index < filled
                ChamferShape(cut: 2, corners: .all)
                    .fill(
                        isFilled
                            ? LinearGradient(colors: [color.opacity(0.65), color], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [theme.foreground.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 8)
                    .shadow(color: color.opacity(isFilled ? 0.5 : 0), radius: isFilled ? 2 : 0)
            }
        }
        .animation(reduceMotion ? nil : AinkradMotion.present, value: filled)
    }
}

/// The rotation angle (degrees) `AinkradSpinner`'s animated arc should target
/// for its `.rotationEffect`, given whether Reduce Motion is active and
/// whether the spin has been toggled on. Reduce Motion always pins the ring
/// static at `0`; otherwise the toggle drives the looping `.animation(...)`
/// between `0` and a full turn. Pure — unit-testable without SwiftUI's
/// animation runtime.
///
/// Retained for the `isSpinning` toggle semantics it documents; `AinkradSpinner`
/// itself no longer drives rotation this way (see its doc comment) since a
/// `repeatForever` `.animation` tied to an `onAppear`-toggled `@State` proved
/// unreliable on this toolchain — it drives rotation from `TimelineView`'s
/// frame clock instead, which needs no toggle/animation trigger at all.
public func spinnerRotationAngle(reduceMotion: Bool, isSpinning: Bool) -> Double {
    guard !reduceMotion else { return 0 }
    return isSpinning ? 360 : 0
}

/// The rotation angle (degrees) for `AinkradSpinner`'s frame-driven spin at a
/// given wall-clock `date`, completing one full turn every `period` seconds.
/// Pure — unit-testable without SwiftUI's animation runtime. A non-positive
/// `period` yields `0` rather than dividing by zero.
public func spinnerTimelineAngle(date: Date, period: TimeInterval = 1) -> Double {
    guard period > 0 else { return 0 }
    let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
    return (elapsed / period) * 360
}

/// The opacity (`0.35...1.0`) `AinkradSpinner`'s accent arc should pulse to
/// under Reduce Motion, at a given wall-clock `date`, completing one full
/// sine cycle every `period` seconds. A gentle breathing pulse conveys
/// ongoing activity without any rotation. Pure — unit-testable without
/// SwiftUI's animation runtime. A non-positive `period` yields the ceiling
/// (`1.0`) rather than dividing by zero.
public func spinnerPulseOpacity(date: Date, period: TimeInterval = 1.2) -> Double {
    guard period > 0 else { return 1.0 }
    let floor = 0.35
    let ceiling = 1.0
    let mid = (floor + ceiling) / 2
    let amplitude = (ceiling - floor) / 2
    let elapsed = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
    return mid + amplitude * sin(2 * Double.pi * elapsed / period)
}

/// Custom rotating arc "reactor ring" — the Cardinal HUD stand-in for
/// `ProgressView`'s spinner.
///
/// Drives the rotation from `BudgetedTimelineView`'s per-frame `date`
/// via `spinnerTimelineAngle(date:period:)` rather than a `@State` toggle
/// matched with `.animation(_:value:).repeatForever(...)` — that pattern did
/// not reliably start spinning on this toolchain (SwiftUI sometimes never
/// picks up the `onAppear`-driven state change). Reading the frame clock
/// directly sidesteps that: there is no toggle to miss, so the ring always
/// animates once mounted.
///
/// Under Reduce Motion, rotation stops (no spinning arc) but the spinner must
/// still read as "loading" rather than a frozen, dead ring — so it instead
/// pulses the accent arc's opacity gently via `spinnerPulseOpacity(date:period:)`,
/// also driven by `BudgetedTimelineView`. No position changes, only
/// opacity — this satisfies Reduce Motion while still conveying activity.
public struct AinkradSpinner: View {
    private let size: CGFloat
    /// Optional arc tint. `nil` (the default set by `init(size:)`) keeps the
    /// original `accentSecondary` arc; a non-nil value is used verbatim so an
    /// in-button spinner can match the button's foreground (e.g. white-on-
    /// primary). Additive stored field with a default so `init(size:)` stays
    /// byte-unchanged — see `init(size:tint:)`.
    private var tint: Color? = nil

    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(size: CGFloat = 20) {
        self.size = size
    }

    /// Tinted variant — colors the arc with `tint` instead of `accentSecondary`,
    /// for white-on-primary in-button spinners. NEW overload (distinct symbol);
    /// the existing `init(size:)` is untouched.
    public init(size: CGFloat, tint: Color) {
        self.size = size
        self.tint = tint
    }

    private var arcColor: Color { tint ?? theme.accentSecondary }

    public var body: some View {
        BudgetedTimelineView { date in
            if reduceMotion {
                ring(angle: .zero, arcOpacity: spinnerPulseOpacity(date: date))
            } else {
                ring(angle: .degrees(spinnerTimelineAngle(date: date)), arcOpacity: 1.0)
            }
        }
        .frame(width: size, height: size)
    }

    private func ring(angle: Angle, arcOpacity: Double) -> some View {
        ZStack {
            Circle()
                .stroke(theme.foreground.opacity(0.12), lineWidth: max(1.5, size * 0.08))
            Circle()
                .trim(from: 0, to: 0.28)
                .stroke(arcColor, style: StrokeStyle(lineWidth: max(1.5, size * 0.08), lineCap: .round))
                .shadow(color: arcColor.opacity(0.6), radius: 3)
                .opacity(arcOpacity)
                .rotationEffect(angle)
        }
    }
}
