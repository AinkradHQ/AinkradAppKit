import CoreGraphics
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

    /// The size in points.
    ///
    /// FIXED, not a fraction of the window. The fraction scheme that shipped
    /// first was wrong in practice: on a 1728 pt-wide display "large" resolved
    /// to 980 x 894, which is not large — the ceiling clamp ate the fraction
    /// before it did anything. A size you pick by name should BE that size.
    ///
    /// Clamped to what actually fits (see `resolved(in:)`), which is an overflow
    /// guard rather than a design choice: a 1200 pt panel on a 1280 pt window
    /// would otherwise sit edge to edge with no scrim left to click.
    public var points: CGSize {
        switch self {
        case .small:  return CGSize(width: 520, height: 400)
        case .medium: return CGSize(width: 780, height: 600)
        case .large:  return CGSize(width: 1280, height: 960)
        }
    }

    /// The size to actually draw inside `available`, never larger than 90% of
    /// it on either axis so the scrim stays reachable.
    public func resolved(in available: CGSize) -> CGSize {
        CGSize(width: min(points.width, available.width * 0.9),
               height: min(points.height, available.height * 0.9))
    }

    /// `medium` is the default. It is close to, but not identical to, the
    /// single hardcoded frame every overlay had before this existed — the old
    /// frame was 560–700 wide, and 780 is the size that actually suits the
    /// apps using it.
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
