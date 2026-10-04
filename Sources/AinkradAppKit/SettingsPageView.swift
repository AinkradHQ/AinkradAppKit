import AinkradAppKitContract
import AinkradAppKitUI
import SwiftUI

/// A settings page: one scrolling column of groups with sticky headers, an
/// optional "on this page" mini-map at width, and the deep-link scroll +
/// highlight target. Pages with two or more groups get a top tab bar instead,
/// one tab per group, so every multi-group page reads the same way and a tall
/// page never becomes a long scroll — see `usesTabs(page:)`. This is deliberately narrow: it separates groups
/// within one topic, not different topics, which stay flat top-level pages.
public struct SettingsPageView: View {
    @Environment(\.ainkradTheme) private var tokens
    @Environment(\.ainkradTypography) private var typo
    @Environment(\.ainkradReduceMotion) private var reduceMotion

    private let page: SettingsPage
    private let matchedPaths: Set<SettingsPath>?
    private let highlightedPath: SettingsPath?

    @State private var selectedTab: Int = 0

    public init(
        page: SettingsPage,
        matchedPaths: Set<SettingsPath>? = nil,
        highlightedPath: SettingsPath? = nil
    ) {
        self.page = page
        self.matchedPaths = matchedPaths
        self.highlightedPath = highlightedPath
        // Seed the active tab on the FIRST render, not one frame later via
        // `.onChange` — otherwise a deep-link or a pre-filled search arriving
        // with the initial view already selects the wrong tab and the first
        // `scrollTo` targets a row that isn't in the hierarchy yet.
        var initialTab = 0
        if let highlightedPath, let index = Self.tabIndex(containing: highlightedPath, page: page) {
            initialTab = index
        } else if let matchedPaths, !matchedPaths.isEmpty, !page.groups.isEmpty,
            Self.tabHitCount(group: page.groups[0], matchedPaths: matchedPaths) == 0,
            let firstHit = page.groups.firstIndex(where: {
                Self.tabHitCount(group: $0, matchedPaths: matchedPaths) > 0
            })
        {
            initialTab = firstHit
        }
        self._selectedTab = State(initialValue: initialTab)
    }

    public static func showsMiniMap(page: SettingsPage, width: CGFloat) -> Bool {
        page.groups.count >= 4 && width >= SettingsMetrics.miniMapBreakpoint
    }

    /// The mini-map's own occupied width: its fixed content width plus the
    /// trailing padding `miniMap` applies around itself. Kept as the single
    /// source of truth so `rowAreaWidth` and the `miniMap` view can't drift
    /// apart into two different numbers for the same column.
    public static let miniMapOccupiedWidth: CGFloat = 150 + 18

    /// The width actually available to rows: the page's total width minus
    /// whatever the mini-map is occupying, if it's showing at all. Pure and
    /// static so layout-breakpoint decisions near `wideBreakpoint` stay
    /// testable without rendering — the mini-map silently stealing ~168pt
    /// from the row column was previously ignored when picking
    /// `.sideBySide` vs. `.stacked`.
    public static func rowAreaWidth(page: SettingsPage, totalWidth: CGFloat) -> CGFloat {
        showsMiniMap(page: page, width: totalWidth) ? totalWidth - miniMapOccupiedWidth : totalWidth
    }

    /// Any page with more than one group is tabbed. It was three, which left a
    /// two-group app page (Appearance + one tab of its own) as a stacked
    /// scroll while its neighbours had tabs — the same kind of page in two
    /// different shapes. One group has nothing to switch between.
    public static func usesTabs(page: SettingsPage) -> Bool {
        page.groups.count >= tabThreshold
    }
    static let tabThreshold = 2

    /// Matches inside one group, for the badge on its tab. A filter must never
    /// be able to hide a match behind an unselected tab.
    public static func tabHitCount(group: SettingsGroup, matchedPaths: Set<SettingsPath>?) -> Int {
        guard let matchedPaths else { return 0 }
        return group.fields.filter { matchedPaths.contains($0.path) }.count
    }

    /// The `.id` carried by the single `SettingsGroupView` the tabbed branch
    /// renders. It is a function, not a literal at the call site, so
    /// `deepLinkTarget` below reasons about the SAME value the view applies:
    /// if this ever stops varying per group, both the view and the test that
    /// pins it change together.
    public static func groupViewIdentity(page: SettingsPage, index: Int) -> SettingsPath {
        page.groups[index].path
    }

    /// Where a deep-link actually LANDS, as one value: which tab must be
    /// active, which group owns the field, and whether that group will really
    /// be expanded once rendered.
    ///
    /// This exists because "the group's `mustExpand` returns true" is not the
    /// same claim as "the field is on screen". On a tabbed page the seeding
    /// that consumes `mustExpand` only runs when the rendered group view has
    /// its own identity; with identity collapsed across tabs the seeding is
    /// skipped and the group shows whatever the previously-visible tab left
    /// behind. Pure, so the composition is testable without rendering.
    public static func deepLinkTarget(
        page: SettingsPage,
        highlightedPath: SettingsPath
    ) -> DeepLinkTarget? {
        guard let index = tabIndex(containing: highlightedPath, page: page) else { return nil }
        let group = page.groups[index]
        let tabbed = usesTabs(page: page)
        // Untabbed pages render every group in a `ForEach` keyed by the
        // group's own id, so seeding always runs. Tabbed pages only honour it
        // when the one rendered slot is identified per group.
        let identities = page.groups.indices.map { groupViewIdentity(page: page, index: $0) }
        let seedingRuns = !tabbed || Set(identities).count == identities.count
        let expanded =
            group.disclosure == .always
            || (seedingRuns
                && SettingsGroupView.mustExpand(
                    group: group, highlightedPath: highlightedPath, matchedPaths: nil))
        return DeepLinkTarget(
            tabIndex: tabbed ? index : nil, groupPath: group.path, groupIsExpanded: expanded)
    }

    public struct DeepLinkTarget: Equatable, Sendable {
        /// The tab that must be selected, or `nil` on an untabbed page.
        public let tabIndex: Int?
        public let groupPath: SettingsPath
        /// Whether the owning group is actually open when it renders.
        public let groupIsExpanded: Bool

        public init(tabIndex: Int?, groupPath: SettingsPath, groupIsExpanded: Bool) {
            self.tabIndex = tabIndex
            self.groupPath = groupPath
            self.groupIsExpanded = groupIsExpanded
        }
    }

    /// The tab holding `path`, so a deep-link can switch tabs before scrolling.
    public static func tabIndex(containing path: SettingsPath, page: SettingsPage) -> Int? {
        page.groups.firstIndex { group in
            group.path == path || group.fields.contains { $0.path == path }
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let layout = SettingsRowLayout(detailWidth: Self.rowAreaWidth(page: page, totalWidth: geo.size.width))
            let tabbed = Self.usesTabs(page: page)
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    if tabbed {
                        tabBar
                    }
                    ScrollViewReader { proxy in
                        ScrollView {
                            // Each `SettingsGroupView`'s body is itself a
                            // `Section` (header + content). Nesting those inside
                            // this `LazyVStack(pinnedViews: [.sectionHeaders])`
                            // is what actually pins the group headers while
                            // scrolling — `pinnedViews` only pins the headers of
                            // real `Section`s in the hierarchy, and SwiftUI
                            // resolves a custom view's declared `body` inline, so
                            // the `Section` returned by `SettingsGroupView.body`
                            // counts exactly as if it were written here directly.
                            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                                if !page.resettableFields.isEmpty {
                                    pageHeader
                                }
                                if tabbed {
                                    let index = min(selectedTab, page.groups.count - 1)
                                    SettingsGroupView(
                                        group: page.groups[index], layout: layout,
                                        matchedPaths: matchedPaths,
                                        highlightedPath: highlightedPath
                                    )
                                    // MUST stay: the tabbed branch renders
                                    // exactly one group at a fixed
                                    // structural slot, so without a
                                    // per-group identity SwiftUI treats
                                    // every tab's group as the SAME view.
                                    // `SettingsGroupView`'s `@State
                                    // isExpanded` would then persist across
                                    // tab switches and its `State(initial
                                    // Value: … mustExpand(…))` seeding
                                    // would never re-run — a collapsed
                                    // group inherited from the previous tab
                                    // renders as a bare header, and a
                                    // deep-link into it scrolls to an id
                                    // that isn't in the hierarchy.
                                    // `groupViewIdentity` is the value
                                    // `deepLinkTarget` reasons about, so
                                    // the test and the view cannot drift.
                                    .id(Self.groupViewIdentity(page: page, index: index))
                                    // The tab bar switches inside its own
                                    // 0.55s materialize animation, so the
                                    // new identity inherited it and SwiftUI
                                    // cross-faded the old tab out and the
                                    // new one in over half a second, both
                                    // on screen with their text overlapping.
                                    // The old tab now leaves at once and the
                                    // new one fades in fast.
                                    .transition(
                                        .asymmetric(
                                            insertion: .opacity.animation(
                                                reduceMotion ? nil : .easeOut(duration: 0.12)),
                                            removal: .identity))
                                } else {
                                    ForEach(page.groups) { group in
                                        SettingsGroupView(
                                            group: group, layout: layout,
                                            matchedPaths: matchedPaths,
                                            highlightedPath: highlightedPath)
                                    }
                                }
                            }
                            .padding(18)
                        }
                        .scrollContentBackground(.hidden)
                        .onChange(of: highlightedPath) { _, path in
                            // A deep-link may name a field on an inactive tab;
                            // switch to it before the scroll, or the user is
                            // sent to an invisible row.
                            guard let path, tabbed,
                                let index = Self.tabIndex(containing: path, page: page)
                            else { return }
                            selectedTab = index
                        }
                        .onChange(of: matchedPaths) { _, matched in
                            // If the active tab has no matches but another
                            // does, move there. Otherwise a filter silently
                            // appears to match nothing.
                            guard tabbed, let matched, !matched.isEmpty else { return }
                            if Self.tabHitCount(group: page.groups[selectedTab], matchedPaths: matched) == 0,
                                let firstHit = page.groups.firstIndex(where: {
                                    Self.tabHitCount(group: $0, matchedPaths: matched) > 0
                                })
                            {
                                if reduceMotion {
                                    selectedTab = firstHit
                                } else {
                                    withAnimation(.easeOut(duration: AinkradMotion.durationBase)) {
                                        selectedTab = firstHit
                                    }
                                }
                            }
                        }
                        .onChange(of: highlightedPath) { _, path in
                            guard let path else { return }
                            if reduceMotion {
                                proxy.scrollTo(path, anchor: .center)
                            } else {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(path, anchor: .center)
                                }
                            }
                        }
                    }
                }

                if !tabbed, Self.showsMiniMap(page: page, width: geo.size.width) {
                    miniMap
                }
            }
        }
    }

    /// Tab strip for tall pages, one tab per group, badged with its hit count
    /// while filtering so a search can never hide a match behind an
    /// unselected tab.
    private var tabBar: some View {
        AinkradTabs(tabs: Array(page.groups.indices), selection: $selectedTab) { index in
            let group = page.groups[index]
            let hits = Self.tabHitCount(group: group, matchedPaths: matchedPaths)
            return hits > 0 ? "\(group.title) (\(hits))" : group.title
        }
        .padding(.horizontal, AinkradSpacing.lg)
        .padding(.top, AinkradSpacing.lg)
    }

    /// Page-level reset control. Shown only when `resettableFields` is
    /// non-empty — i.e. at least one field on this page is both resettable
    /// and currently modified from its default.
    private var pageHeader: some View {
        HStack {
            Spacer(minLength: 0)
            Button(action: { page.resetAll() }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 10))
                    Text("Reset this page")
                        .font(AinkradFontResolver.font(.caption, weight: .medium, typography: typo))
                }
                .foregroundStyle(tokens.accentSecondary.opacity(0.9))
            }
            .buttonStyle(.plain)
            .help("Restore all modified fields on this page to their defaults")
        }
    }

    private var miniMap: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ON THIS PAGE")
                .font(AinkradFontResolver.font(.mono, weight: .medium, typography: typo))
                .kerning(2.5)
                .foregroundStyle(tokens.foreground.opacity(0.4))
            ForEach(page.groups) { group in
                Text(group.title)
                    .font(AinkradFontResolver.font(.caption, typography: typo))
                    .foregroundStyle(tokens.foreground.opacity(0.6))
            }
            Spacer(minLength: 0)
        }
        .frame(width: Self.miniMapOccupiedWidth - 18, alignment: .topLeading)
        .padding(.top, 18)
        .padding(.trailing, 18)
    }
}
