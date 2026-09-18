import Foundation

/// How large the host draws an `.overlay`-presentation app.
///
/// A third axis beside presentation and mode, and a real one: the size that
/// suits Rune running one command is not the size that suits Leyline listing
/// thirty hosts, and until now every overlay got the same hardcoded frame.
///
/// The values are FRACTIONS of the window with a floor and a ceiling, not fixed
///点 sizes — an overlay that is comfortable on a 14" laptop and an overlay that
/// is comfortable on a 32" display are not the same number of points, and
/// picking one number means being wrong on one of them.
public enum PluginOverlaySize: String, Codable, Sendable, CaseIterable {
    case small
    case medium
    case large

    /// The width fraction of the host window, and the points it is clamped to.
    public var width: (fraction: Double, min: Double, max: Double) {
        switch self {
        case .small:  return (0.30, 420, 520)
        case .medium: return (0.42, 560, 700)
        case .large:  return (0.58, 720, 980)
        }
    }

    /// The height fraction, and its clamps.
    public var height: (fraction: Double, min: Double, max: Double) {
        switch self {
        case .small:  return (0.48, 340, 520)
        case .medium: return (0.66, 460, 760)
        case .large:  return (0.80, 620, 1040)
        }
    }

    /// `medium` is what every overlay was before this existed, so an app that
    /// says nothing keeps exactly the size it had.
    public static let `default` = PluginOverlaySize.medium

    public var title: String {
        switch self {
        case .small:  return "Small"
        case .medium: return "Medium"
        case .large:  return "Large"
        }
    }
}

/// Reads and overrides the size the host draws this app's overlay at. Per app,
/// persisted, edited in that app's settings — the same shape as
/// `PluginPresentationControl` and `PluginModeControl`.
///
/// Applies the next time the overlay is summoned; it never resizes one that is
/// already up.
@MainActor public protocol PluginOverlaySizeControl {
    var current: PluginOverlaySize { get }
    func set(_ size: PluginOverlaySize)
    func reset()
}
