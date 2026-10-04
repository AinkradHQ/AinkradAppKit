import AinkradAppKitContract
import SwiftUI

/// Publishes a `HostTheme` into the SDK's environment keys.
///
/// ## Why this exists
///
/// The SDK carried the host's theme along two disjoint paths: `HostServices.theme`
/// (an observable object handed to the plugin) and the `@Entry` environment keys
/// (`ainkradTheme`, `ainkradStatusColors`) that every `AinkradAppKit` component
/// actually reads. A plugin could use either. They were injected from different
/// places — the environment from the host's root view, `HostServices.theme` from
/// per-plugin scoped services — and nothing made them agree.
///
/// Generation 8 collapses that: **the environment is the single path**, and
/// `HostServices.theme` is the thing that feeds it. The host applies this
/// modifier when it builds a plugin's root and settings views, so the plugin's
/// own scoped theme is authoritative for its subtree.
///
/// Status colors are derived here rather than stored on `HostThemeTokens` —
/// that type is ABI-frozen for plugins, and `ContractFreezeTests` asserts it
/// gains no stored fields.
extension View {
    /// Injects `theme` into `ainkradTheme` (and status colors derived from it).
    public func ainkradHostTheme(_ theme: HostTheme) -> some View {
        modifier(AinkradHostThemeBridge(theme: theme))
    }
}

public struct AinkradHostThemeBridge: ViewModifier {
    private let theme: HostTheme

    public init(theme: HostTheme) { self.theme = theme }

    public func body(content: Content) -> some View {
        // `theme.tokens` is read here, inside `body`, so the `@Observable`
        // dependency is registered and a theme change re-renders the subtree.
        let tokens = theme.tokens
        return
            content
            .environment(\.ainkradTheme, tokens)
            .environment(\.ainkradStatusColors, AinkradStatusColors(theme.statusColors))
    }
}

extension AinkradStatusColors {
    /// Adapts the contract's `HostStatusColors` into the UI kit's environment
    /// value. Two types rather than one because the contract module must not
    /// depend on the UI module — the dependency runs one way only.
    public init(_ host: HostStatusColors) {
        self.init(success: host.success, warning: host.warning, danger: host.danger)
    }
}
