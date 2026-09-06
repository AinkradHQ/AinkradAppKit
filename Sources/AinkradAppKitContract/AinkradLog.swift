import os

/// The one `os.Logger` factory shared by the host and every plugin, so a user's
/// whole Ainkrad install filters as a single subsystem in Console.app.
///
/// WHY this lives in the contract target: it is the only module every plugin
/// already imports. Adding it here is ADDITIVE — no existing public symbol
/// changes — so the API generation does not move and every installed bundle
/// keeps loading. `make abi-check` guards that.
public enum AinkradLog {
    /// Matches the host's bundle identifier so Console.app groups app logs and
    /// plugin logs under one filterable subsystem.
    public static let subsystem = "com.ainkrad.app"

    /// Builds a category string. Lowercased so a Console filter typed once keeps
    /// matching regardless of how a call site capitalises its app name.
    public static func category(app: String, area: String) -> String {
        "\(app.lowercased()).\(area.lowercased())"
    }

    /// A logger for an already-composed category (e.g. `"raven.imap"`).
    public static func logger(_ category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    /// Convenience: compose and build in one call.
    public static func logger(app: String, area: String) -> Logger {
        logger(category(app: app, area: area))
    }
}
