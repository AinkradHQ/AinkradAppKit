import SwiftUI

/// The top-level buckets of the settings sidebar, in sidebar order.
public enum SettingsPageGroup: String, CaseIterable, Sendable {
    case workspace, intelligence, builtInApps, installedApps

    public var title: String {
        switch self {
        case .workspace: return "WORKSPACE"
        case .intelligence: return "INTELLIGENCE"
        case .builtInApps: return "BUILT-IN APPS"
        case .installedApps: return "INSTALLED"
        }
    }
}

public enum SettingsDisclosure: Sendable {
    case always
    case collapsedByDefault
}

public struct SettingsOption: Identifiable, Sendable {
    public let id: String
    public let title: String
    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

/// How a field renders. `.custom` is the deliberate escape hatch for panes
/// that will never be a toggle list (Assistant Connections, the sandbox
/// editor). A `.custom` field still declares label/help/keywords, so the
/// search *index* stays complete even where the host does not own the pixels.
@MainActor
public enum SettingsFieldKind {
    case toggle(Binding<Bool>)
    case select(options: [SettingsOption], selection: Binding<String>)
    case slider(range: ClosedRange<Double>, step: Double, value: Binding<Double>)
    case text(Binding<String>)
    case secure(Binding<String>)
    case shortcut(Binding<String>)
    case action(title: String, handler: @MainActor () -> Void)
    case custom(AnyView)
}

@MainActor
public struct SettingsField: Identifiable {
    public let path: SettingsPath
    public let label: String
    public let help: String?
    public let keywords: [String]
    public let kind: SettingsFieldKind
    public let isAdvanced: Bool
    public let requiresRestart: Bool
    /// Human-readable default, shown by the reset affordance ("Default: On").
    public let defaultDescription: String?
    /// True when the live value differs from the default — drives the revert control.
    public let isModified: () -> Bool
    /// Restores the default. `nil` means this field has no meaningful reset.
    public let reset: (() -> Void)?

    public nonisolated var id: SettingsPath { path }

    public init(
        path: SettingsPath,
        label: String,
        help: String? = nil,
        keywords: [String] = [],
        kind: SettingsFieldKind,
        isAdvanced: Bool = false,
        requiresRestart: Bool = false,
        defaultDescription: String? = nil,
        isModified: @escaping () -> Bool = { false },
        reset: (() -> Void)? = nil
    ) {
        self.path = path
        self.label = label
        self.help = help
        self.keywords = keywords
        self.kind = kind
        self.isAdvanced = isAdvanced
        self.requiresRestart = requiresRestart
        self.defaultDescription = defaultDescription
        self.isModified = isModified
        self.reset = reset
    }
}

@MainActor
public struct SettingsGroup: Identifiable {
    public let path: SettingsPath
    public let title: String
    public let disclosure: SettingsDisclosure
    /// The "why would I change this" paragraph that does not belong on a row.
    public let footerNote: String?
    public let fields: [SettingsField]

    public nonisolated var id: SettingsPath { path }

    public init(
        path: SettingsPath,
        title: String,
        disclosure: SettingsDisclosure = .always,
        footerNote: String? = nil,
        fields: [SettingsField]
    ) {
        self.path = path
        self.title = title
        self.disclosure = disclosure
        self.footerNote = footerNote
        self.fields = fields
    }
}

@MainActor
public struct SettingsPage: Identifiable {
    public let path: SettingsPath
    public let title: String
    /// SF Symbol, or the app id for pages that render a neon app tile.
    public let icon: String
    public let group: SettingsPageGroup
    public let order: Int
    public let groups: [SettingsGroup]
    /// Set for app pages so the sidebar renders the app's neon tile.
    public let appID: String?
    /// A count the sidebar row renders as a badge — pending skill proposals,
    /// say. A CLOSURE, not a stored count, deliberately: the number changes
    /// while the overlay is open, and a value snapshotted when the catalog was
    /// built would go stale. `nil` means this page never badges; a closure
    /// returning 0 means "nothing pending right now" and shows nothing.
    public let badge: (@MainActor () -> Int)?

    public nonisolated var id: SettingsPath { path }
    public var allFields: [SettingsField] { groups.flatMap(\.fields) }

    /// Fields that are both currently modified from their default AND have a
    /// reset closure — the exact set the page-level "Reset this page"
    /// affordance is allowed to touch.
    public var resettableFields: [SettingsField] {
        allFields.filter { $0.reset != nil && $0.isModified() }
    }

    /// Restores every resettable, modified field on this page. Fields without
    /// a `reset` closure, or that are already at their default, are untouched.
    public func resetAll() {
        for field in resettableFields {
            field.reset?()
        }
    }

    public init(
        path: SettingsPath,
        title: String,
        icon: String,
        group: SettingsPageGroup,
        order: Int,
        groups: [SettingsGroup],
        appID: String? = nil,
        badge: (@MainActor () -> Int)? = nil
    ) {
        self.path = path
        self.title = title
        self.icon = icon
        self.group = group
        self.order = order
        self.groups = groups
        self.appID = appID
        self.badge = badge
    }
}

/// The assembled registry. Built at launch and rebuilt when apps are
/// enabled or disabled.
@MainActor
public struct SettingsCatalog {
    public let pages: [SettingsPage]

    public init(pages: [SettingsPage]) {
        // Sidebar order follows the declaration order of SettingsPageGroup,
        // not alphabetical order of its raw values.
        func rank(_ group: SettingsPageGroup) -> Int {
            SettingsPageGroup.allCases.firstIndex(of: group) ?? 0
        }
        self.pages = pages.sorted {
            (rank($0.group), $0.order) < (rank($1.group), $1.order)
        }
    }

    public var allFields: [SettingsField] { pages.flatMap(\.allFields) }

    public func page(at path: SettingsPath) -> SettingsPage? {
        pages.first { $0.path == path }
    }

    public func field(at path: SettingsPath) -> SettingsField? {
        allFields.first { $0.path == path }
    }

    /// The page containing `path`, whether `path` names a page, group, or field.
    public func page(containing path: SettingsPath) -> SettingsPage? {
        pages.first { page in
            page.path == path
                || page.groups.contains {
                    $0.path == path || $0.fields.contains { $0.path == path }
                }
        }
    }

    public func pages(in group: SettingsPageGroup) -> [SettingsPage] {
        pages.filter { $0.group == group }.sorted { $0.order < $1.order }
    }
}
