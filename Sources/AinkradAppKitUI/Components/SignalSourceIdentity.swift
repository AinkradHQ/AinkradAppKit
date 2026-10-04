import AinkradSignal
import SwiftUI

/// Who sent a notification, as the user knows it: the app's display name and
/// its launcher symbol. Toasts and feed rows show it, so a notification says
/// which app it came from with the same icon the launcher uses.
public struct SignalSourceIdentity: Equatable, Sendable {
    public let name: String
    /// SF Symbol name, the app's `AinkradApp.icon`.
    public let symbol: String

    public init(name: String, symbol: String) {
        self.name = name
        self.symbol = symbol
    }
}

/// Looks up a source's identity. The kit cannot see the host's app registry,
/// so the host supplies a snapshot of it through the environment
/// (`ainkradSignalIdentity`). Without one, surfaces fall back to the label
/// derived from the source id and the severity glyph.
public struct SignalIdentityResolver: Sendable {
    private let apps: [String: SignalSourceIdentity]
    private let host: SignalSourceIdentity?

    public init(apps: [String: SignalSourceIdentity], host: SignalSourceIdentity? = nil) {
        self.apps = apps
        self.host = host
    }

    public static let none = SignalIdentityResolver(apps: [:])

    public func identity(for source: SignalSource) -> SignalSourceIdentity? {
        switch source {
        case .app(let appID): return apps[appID]
        case .host: return host
        default: return nil
        }
    }
}

extension EnvironmentValues {
    @Entry public var ainkradSignalIdentity: SignalIdentityResolver = .none
}
