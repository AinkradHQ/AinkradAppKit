import Foundation

/// Named house curves, so a call site writes `skin.animation(.arrive)` instead of its own literal. Static, like
/// `AinkradMotion`: they do not follow a theme's `motion` keys.
extension AinkradAnimationToken {
    /// One-shot arrival: the fade `ainkradRiseIn` uses.
    public static let arrive = AinkradAnimationToken(curve: "easeOut", duration: 0.35)
    /// Slow flash-off after an arrival.
    public static let arriveFlash = AinkradAnimationToken(curve: "easeOut", duration: 1.6)
    /// Bar, arc and segment grow.
    public static let grow = AinkradAnimationToken(curve: "easeOut", duration: 0.7)
    /// Drawer and fold slide.
    public static let fold = AinkradAnimationToken(curve: "easeOut", duration: 0.28)
    /// Quick spring for small, close moves (a press, a chip).
    public static let springSnappy = AinkradAnimationToken(curve: "spring", response: 0.25, damping: 0.7)
    /// Default spring: hover lifts and most state changes.
    public static let springStandard = AinkradAnimationToken(curve: "spring", response: 0.3, damping: 0.75)
    /// Slow, settled spring for large surfaces.
    public static let springSoft = AinkradAnimationToken(curve: "spring", response: 0.5, damping: 0.75)

    /// Ambient loop over `seconds`; the caller adds the repeat.
    public static func ambient(_ seconds: Double) -> AinkradAnimationToken {
        AinkradAnimationToken(curve: "easeInOut", duration: seconds)
    }
}
