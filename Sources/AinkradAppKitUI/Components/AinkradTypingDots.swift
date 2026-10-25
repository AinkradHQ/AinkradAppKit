import SwiftUI

/// The three-dot "typing" bounce: dots that rise and fade in turn, 0.15 s apart over a 1.2 s cycle. `bubble` sits
/// them in a soft bubble (a chat thread); without it they are bare, inline in a system line. Still, and dimmed,
/// under Reduce Motion.
public struct AinkradTypingDots: View {
    private let bubble: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    public init(bubble: Bool = true) { self.bubble = bubble }

    public var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(spacing: skin.size.s4) {
                ForEach(0..<3, id: \.self) { index in
                    let phase = Self.phase(t - Double(index) * 0.15)
                    Circle().fill(skin.color(skin.text.muted))
                        .frame(width: skin.size.s6, height: skin.size.s6)
                        .opacity(reduceMotion ? skin.opacity.o60 : skin.opacity.o30 + (1 - skin.opacity.o30) * phase)
                        .offset(y: reduceMotion ? 0 : -skin.size.s3 * phase)
                }
            }
        }
        .padding(.horizontal, bubble ? skin.size.s14 : 0)
        .padding(.vertical, bubble ? skin.size.s10 : 0)
        .background(
            skin.color(.palette("foreground", bubble ? skin.opacity.o05 : 0)),
            in: RoundedRectangle(cornerRadius: skin.size.s12, style: .continuous)
        )
        .accessibilityLabel("typing")
    }

    /// 0, up to 1 and back to 0 over the first 60% of a 1.2 s cycle (the peak at 30%), then 0 until it repeats.
    static func phase(_ t: Double) -> Double {
        let p = (t.truncatingRemainder(dividingBy: 1.2) + 1.2).truncatingRemainder(dividingBy: 1.2) / 1.2
        guard p < 0.6 else { return 0 }
        return p < 0.3 ? p / 0.3 : (0.6 - p) / 0.3
    }
}
