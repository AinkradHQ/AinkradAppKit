import SwiftUI

/// A labelled tick under an `AinkradMarkerGauge`; a `isCap` tick is drawn in the danger colour.
public struct AinkradGaugeTick {
    public var fraction: Double
    public var label: String
    public var isCap: Bool

    public init(fraction: Double, label: String, isCap: Bool = false) {
        self.fraction = fraction
        self.label = label
        self.isCap = isCap
    }
}

/// A thick budget track: a success-to-warning fill that grows in, a "now" value above its end, labelled warn and cap
/// ticks under it, and a warning marker that slides to a proposed value. All positions are 0...1 of the track.
public struct AinkradMarkerGauge: View {
    private let fill: Double
    private let nowLabel: String
    private let ticks: [AinkradGaugeTick]
    private let marker: Double?
    @State private var grown = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(fill: Double, nowLabel: String, ticks: [AinkradGaugeTick], marker: Double? = nil) {
        self.fill = fill
        self.nowLabel = nowLabel
        self.ticks = ticks
        self.marker = marker
    }

    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let track = skin.size.s16
            let mid = skin.size.s26 + track / 2
            ZStack {
                Capsule().fill(skin.color(.palette("foreground", skin.opacity.o06)))
                    .frame(width: width, height: track).position(x: width / 2, y: mid)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [skin.color(skin.palette.success), skin.color(skin.palette.warning)],
                            startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: width * clamp(fill), height: track)
                    .scaleEffect(x: grown || reduceMotion ? 1 : 0, anchor: .leading)
                    .position(x: width * clamp(fill) / 2, y: mid)
                Text(nowLabel).kitFont("t12", weight: "semibold", mono: true)
                    .foregroundStyle(skin.color(skin.palette.warning))
                    .fixedSize()
                    .position(x: width * clamp(fill), y: skin.size.s8)
                ForEach(Array(ticks.enumerated()), id: \.offset) { _, tick in
                    let x = width * clamp(tick.fraction)
                    Rectangle()
                        .fill(
                            tick.isCap
                                ? skin.color(skin.palette.danger) : skin.color(.palette("foreground", skin.opacity.o35))
                        )
                        .frame(width: skin.size.s2, height: track + skin.size.s8)
                        .position(x: x, y: mid)
                    Text(tick.label).kitFont("t10_5", mono: true).foregroundStyle(skin.color(skin.text.faint))
                        .fixedSize()
                        .position(x: x, y: mid + track + skin.size.s4)
                }
                if let marker {
                    RoundedRectangle(cornerRadius: skin.size.s3)
                        .fill(skin.color(skin.palette.warning))
                        .frame(width: skin.size.s4, height: skin.size.s28)
                        .shadow(color: skin.color(skin.palette.warning), radius: skin.size.s6)
                        .position(x: width * clamp(marker), y: mid)
                        .animation(
                            skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 0.15)), value: marker)
                }
            }
        }
        .frame(height: skin.size.s72)
        .padding(.horizontal, skin.size.s4)
        .onAppear {
            guard !reduceMotion else {
                grown = true
                return
            }
            withAnimation(skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 1))) { grown = true }
        }
    }

    private func clamp(_ value: Double) -> Double { min(max(value, 0), 1) }
}
