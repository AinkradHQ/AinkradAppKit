import AinkradAppKitContract
import SwiftUI

/// Semantic status colors, injected separately from HostThemeTokens (which is
/// ABI-frozen for plugins — do NOT add stored fields to it).
public struct AinkradStatusColors: Equatable, Sendable {
    public var success: Color
    public var warning: Color
    public var danger: Color
    public init(success: Color = .green, warning: Color = .yellow, danger: Color = .red) {
        self.success = success
        self.warning = warning
        self.danger = danger
    }
    public static let `default` = AinkradStatusColors()
}

extension EnvironmentValues {
    @Entry public var ainkradStatusColors: AinkradStatusColors = .default
}
