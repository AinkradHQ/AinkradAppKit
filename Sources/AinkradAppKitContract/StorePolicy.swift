import Foundation

#if canImport(AppKit)
import AppKit
#endif

/// One failed store-review check. `code` is a stable machine-readable
/// identifier; `message` is the human-facing explanation.
public struct StoreIssue: Equatable {
    public let code: String
    public let message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

/// All facts `StorePolicy` needs to judge a store submission. Carries the
/// base bundle metadata `PluginValidation` already understands, plus the
/// store-only catalog facts (author, description, listing icon) and the
/// zip/sha integrity fact.
public struct StoreManifestInput {
    public let metadata: PluginBundleMetadata
    public let infoDictionary: [String: Any]
    public let author: String?
    public let description: String?
    public let iconSymbol: String?
    public let declaredSHA256: String
    public let computedSHA256: String

    public init(
        metadata: PluginBundleMetadata,
        infoDictionary: [String: Any],
        author: String?,
        description: String?,
        iconSymbol: String?,
        declaredSHA256: String,
        computedSHA256: String
    ) {
        self.metadata = metadata
        self.infoDictionary = infoDictionary
        self.author = author
        self.description = description
        self.iconSymbol = iconSymbol
        self.declaredSHA256 = declaredSHA256
        self.computedSHA256 = computedSHA256
    }
}

/// The single authority for "what review runs" on a store submission.
/// Composes `PluginValidation` for the base metadata layer and adds the
/// store-only checks (catalog completeness + zip/sha integrity) on top, so
/// the host installer and `ainkrad validate --store` share one definition.
public enum StorePolicy {
    /// Empty array = pass. Otherwise one `StoreIssue` per failed check.
    public static func check(manifest: StoreManifestInput, minSupported: Int, current: Int) -> [StoreIssue] {
        var issues: [StoreIssue] = []

        switch PluginValidation.validate(
            metadata: manifest.metadata,
            infoDictionary: manifest.infoDictionary,
            minSupported: minSupported,
            current: current)
        {
        case .success:
            break
        case .failure(let error):
            issues.append(StoreIssue(code: baseValidationCode(for: error.reason), message: error.reason))
        }

        if manifest.author?.isEmpty ?? true {
            issues.append(StoreIssue(code: "missing-author", message: "Submission is missing an author."))
        }

        if manifest.description?.isEmpty ?? true {
            issues.append(StoreIssue(code: "missing-description", message: "Submission is missing a description."))
        }

        if !resolvesSFSymbol(manifest.iconSymbol) {
            issues.append(
                StoreIssue(
                    code: "missing-icon",
                    message: "Submission's icon symbol is missing or not a resolvable SF Symbol."))
        }

        if manifest.declaredSHA256 != manifest.computedSHA256 {
            issues.append(
                StoreIssue(
                    code: "sha-mismatch",
                    message: "Computed sha256 does not match the declared sha256."))
        }

        return issues
    }

    /// Classifies a `PluginValidation` failure reason into a store issue
    /// code, reusing its exact wording (including the generation-range
    /// message) rather than re-deriving it.
    private static func baseValidationCode(for reason: String) -> String {
        if reason.hasPrefix("built against generation") {
            return "unsupported-generation"
        }
        if reason == "invalid app id" {
            return "invalid-app-id"
        }
        if reason == "missing CFBundleExecutable" {
            return "missing-executable"
        }
        return "invalid-metadata"
    }

    private static func resolvesSFSymbol(_ name: String?) -> Bool {
        guard let name, !name.isEmpty else { return false }
        #if canImport(AppKit)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #else
        return true
        #endif
    }
}
