import SwiftUI

/// One segment of an `AinkradLegendBar`: its share (`value`), the legend's label and mono `text`, and its colour.
public struct AinkradLegendSegment: Identifiable {
    public var id: String { label }
    public let label: String
    public let value: Double
    public let text: String
    public let color: Color

    public init(label: String, value: Double, text: String, color: Color) {
        self.label = label
        self.value = value
        self.text = text
        self.color = color
    }
}

/// A stacked bar with its legend: a 10 pt track (`height`) of segments with 2 pt gaps that each grow in from the
/// left, 90 ms apart (at once under Reduce Motion), and under it a wrapping legend of a square, a muted label and a
/// mono value. Segments of zero are left out of the bar but kept in the legend.
public struct AinkradLegendBar: View {
    private let segments: [AinkradLegendSegment]
    private let height: CGFloat?
    @State private var grown = false
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(segments: [AinkradLegendSegment], height: CGFloat? = nil) {
        self.segments = segments
        self.height = height
    }

    public var body: some View {
        let shown = segments.filter { $0.value > 0 }
        let total = max(shown.reduce(0) { $0 + $1.value }, 0.0001)
        VStack(alignment: .leading, spacing: skin.size.s10) {
            GeometryReader { geo in
                let gaps = skin.size.s2 * CGFloat(max(shown.count - 1, 0))
                HStack(spacing: skin.size.s2) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, segment in
                        Rectangle().fill(segment.color)
                            .frame(width: max(0, (geo.size.width - gaps) * segment.value / total))
                            .scaleEffect(x: grown || reduceMotion ? 1 : 0, anchor: .leading)
                            .animation(
                                skin.animation(AinkradAnimationToken(curve: "easeOut", duration: 0.7))
                                    .delay(Double(index) * 0.09 + 0.15), value: grown)
                    }
                }
            }
            .frame(height: height ?? skin.size.s10)
            .clipShape(RoundedRectangle(cornerRadius: skin.size.s6, style: .continuous))
            AinkradFlowLayout(spacing: skin.size.s12, lineSpacing: skin.size.s4) {
                ForEach(segments) { segment in
                    HStack(spacing: skin.size.s5) {
                        RoundedRectangle(cornerRadius: skin.size.s2).fill(segment.color)
                            .frame(width: skin.size.s7, height: skin.size.s7)
                        Text(segment.label).kitFont("t11").foregroundStyle(skin.color(skin.text.muted))
                        Text(segment.text).kitFont("t10_5", weight: "medium", mono: true)
                            .foregroundStyle(skin.color(skin.text.primary))
                    }
                }
            }
        }
        .onAppear { grown = true }
    }
}

/// A legend swatch: a small rounded square and its label.
public struct AinkradLegendSwatch: View {
    private let color: Color
    private let label: String
    @Environment(\.ainkradSkin) private var skin

    public init(color: Color, label: String) {
        self.color = color
        self.label = label
    }

    public var body: some View {
        HStack(spacing: skin.size.s5) {
            RoundedRectangle(cornerRadius: skin.size.s2).fill(color).frame(width: skin.size.s8, height: skin.size.s8)
            Text(label)
        }
    }
}
