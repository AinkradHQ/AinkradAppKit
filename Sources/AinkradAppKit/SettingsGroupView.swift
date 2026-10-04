import AinkradAppKitContract
import AinkradAppKitUI
import SwiftUI

/// A titled group of rows: composes `AinkradSectionFrame` (always-expanded),
/// `AinkradDisclosureGroup` (collapsible), or bare rows (pane-only, no
/// catalog heading), plus an optional footer note.
///
/// `body` is a `Section` rather than a bare `VStack`. SwiftUI resolves a
/// custom view's `body` structurally at compile time, so when a
/// `SettingsGroupView` is placed inside a `LazyVStack(pinnedViews:
/// [.sectionHeaders])` (see `SettingsPageView`), the `Section` it returns
/// counts exactly as if it were written inline. This `Section` has no
/// separate `header:` — `AinkradSectionFrame`/`AinkradDisclosureGroup` fuse
/// title and content into one chamfered block by design, so there is no
/// longer a distinct title bar to pin while rows scroll beneath it; each
/// group now scrolls as a single unit.
public struct SettingsGroupView: View {
    @Environment(\.ainkradTheme) private var tokens
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    private let group: SettingsGroup
    private let layout: SettingsRowLayout
    private let matchedPaths: Set<SettingsPath>?
    private let highlightedPath: SettingsPath?
    @State private var isExpanded: Bool

    public init(
        group: SettingsGroup,
        layout: SettingsRowLayout,
        matchedPaths: Set<SettingsPath>? = nil,
        highlightedPath: SettingsPath? = nil
    ) {
        self.group = group
        self.layout = layout
        self.matchedPaths = matchedPaths
        self.highlightedPath = highlightedPath
        _isExpanded = State(
            initialValue: group.disclosure == .always
                || Self.mustExpand(group: group, highlightedPath: highlightedPath, matchedPaths: matchedPaths))
    }

    /// A collapsed group must open by itself whenever the thing a user is
    /// looking for lives inside it — otherwise it is unreachable: a deep-link
    /// scroll target with no `.id()` in the hierarchy silently does nothing,
    /// and a search match behind an unopened disclosure is a result the UI
    /// is hiding from the very search that found it. `.always` groups never
    /// need this (their content is never removed from the hierarchy), but
    /// the check is harmless to run for them too.
    public static func mustExpand(
        group: SettingsGroup,
        highlightedPath: SettingsPath?,
        matchedPaths: Set<SettingsPath>?
    ) -> Bool {
        if let highlightedPath, group.fields.contains(where: { $0.path == highlightedPath }) {
            return true
        }
        if let matchedPaths, group.fields.contains(where: { matchedPaths.contains($0.path) }) {
            return true
        }
        return false
    }

    /// Non-matching rows dim; they are never removed. Half-hidden sections
    /// destroy the spatial memory that makes settings learnable.
    public static func opacity(for path: SettingsPath, matchedPaths: Set<SettingsPath>?) -> Double {
        guard let matchedPaths else { return 1.0 }
        return matchedPaths.contains(path) ? 1.0 : 0.35
    }

    /// True when every field in the group is a pane (`.custom`) rather than a
    /// control — i.e. the group contributes no rows of its own at all.
    public static func isPaneOnly(_ group: SettingsGroup) -> Bool {
        !group.fields.isEmpty
            && group.fields.allSatisfy {
                SettingsRow.presentation(for: $0) == .pane
            }
    }

    /// Whether to draw the catalog's group header.
    ///
    /// An always-expanded group made only of panes gets none: the pane
    /// already renders its own section heading, and stacking the catalog's
    /// title above it put two heading idioms on nearly every page. Suppressing
    /// the catalog side (rather than editing ten pane files) keeps the panes
    /// usable standalone and keeps the heading nearest the content it labels.
    ///
    /// A `.collapsedByDefault` group ALWAYS keeps its header even when it is
    /// pane-only — that header is the disclosure control, and without it the
    /// group could never be opened. That is also the escape hatch for a pane
    /// with no heading of its own (e.g. tool hooks): declaring the group
    /// collapsible keeps a title on screen.
    public static func showsHeader(for group: SettingsGroup) -> Bool {
        guard group.disclosure == .always else { return true }
        return !isPaneOnly(group)
    }

    public static func hitCount(group: SettingsGroup, matchedPaths: Set<SettingsPath>?) -> Int {
        guard let matchedPaths else { return 0 }
        return group.fields.filter { matchedPaths.contains($0.path) }.count
    }

    public var body: some View {
        Section {
            if group.disclosure == .collapsedByDefault {
                AinkradDisclosureGroup(
                    title: group.title,
                    isExpanded: $isExpanded,
                    hitCount: Self.hitCount(group: group, matchedPaths: matchedPaths)
                ) {
                    rows
                }
                .id(group.path)
                // A deep-link or a new filter can name a target inside this
                // group after it has already rendered collapsed — force it
                // open then. Never auto-collapses back: once opened for a
                // reason, closing is the user's call.
                .onChange(of: highlightedPath) { _, newValue in
                    if Self.mustExpand(group: group, highlightedPath: newValue, matchedPaths: matchedPaths) {
                        isExpanded = true
                    }
                }
                .onChange(of: matchedPaths) { _, newValue in
                    if Self.mustExpand(group: group, highlightedPath: highlightedPath, matchedPaths: newValue) {
                        isExpanded = true
                    }
                }
            } else if Self.showsHeader(for: group) {
                AinkradSectionFrame(title: group.title) {
                    rows
                }
                .id(group.path)
            } else {
                // Pane-only group: the pane draws its own heading, so a second
                // one here would stack two headings on the same content. Still
                // an anchor, so deep-links and the mini-map that address the
                // GROUP path keep resolving to the right place in the scroller.
                rows.id(group.path)
            }
        }
    }

    /// The group's fields plus its optional footer note. Extracted so all three
    /// presentations share one definition.
    @ViewBuilder
    private var rows: some View {
        VStack(alignment: .leading, spacing: AinkradSpacing.md) {
            ForEach(group.fields) { field in
                SettingsRow(field: field, layout: layout)
                    .opacity(Self.opacity(for: field.path, matchedPaths: matchedPaths))
                    .overlay(
                        ChamferShape(cut: AinkradRadius.md)
                            .strokeBorder(
                                highlightedPath == field.path
                                    ? tokens.accentSecondary.opacity(0.9) : .clear,
                                lineWidth: 1.5)
                    )
                    .id(field.path)
            }
            if let note = group.footerNote {
                Text(note)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(tokens.foreground.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
