import Foundation

/// Public shared plugin metadata validation. Used by the host, the CLI, and
/// the Dev Host so all three share one definition and cannot drift.
public struct PluginValidationError: Error {
    public let reason: String

    public init(reason: String) {
        self.reason = reason
    }
}

public enum PluginValidation {
    /// Conservative charset for `AinkradAppID`: it is interpolated into a
    /// filesystem path segment, so it must not contain separators or traversal.
    private static let appIDAllowed = CharacterSet(
        charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-")

    public static func isValidAppID(_ id: String) -> Bool {
        guard !id.isEmpty, id != ".", id != ".." else { return false }
        return id.unicodeScalars.allSatisfy { appIDAllowed.contains($0) }
    }

    /// Validates app-id safety, executable presence, and API-version
    /// compatibility (NOT signature — separate policy — and NOT `Bundle.load()`).
    public static func validate(
        metadata: PluginBundleMetadata,
        infoDictionary: [String: Any],
        minSupported: Int,
        current: Int
    ) -> Result<Void, PluginValidationError> {
        guard isValidAppID(metadata.appID) else {
            return .failure(PluginValidationError(reason: "invalid app id"))
        }
        // The host renames an installed bundle to `<appID>.bundle`; without an
        // explicit CFBundleExecutable, CFBundle's filename-based fallback then
        // can't find the executable and `Bundle.load()` fails cryptically.
        guard let exe = infoDictionary["CFBundleExecutable"] as? String, !exe.isEmpty else {
            return .failure(PluginValidationError(reason: "missing CFBundleExecutable"))
        }
        guard
            AinkradAppKit.isCompatible(
                bundleAPIVersion: metadata.apiVersion,
                minSupported: minSupported,
                current: current)
        else {
            return .failure(
                PluginValidationError(
                    reason:
                        "built against generation \(metadata.apiVersion); this host supports "
                        + "\(minSupported)\u{2013}\(current) — update the app"))
        }
        return .success(())
    }
}
