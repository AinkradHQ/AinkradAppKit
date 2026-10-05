import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("AinkradChip")
struct AinkradChipTests {
    @Test("isRemovable reflects presence of onRemove")
    func removable() {
        #expect(AinkradChip(label: "swift", onRemove: {}).isRemovable == true)
        #expect(AinkradChip(label: "swift", onRemove: nil).isRemovable == false)
    }
}

@Suite("AinkradSwatchChip")
struct AinkradSwatchChipTests {
    @Test("isToggle reflects presence of onTap")
    func toggle() {
        #expect(AinkradSwatchChip(label: "bug", swatch: .red, onTap: {}).isToggle == true)
        #expect(AinkradSwatchChip(label: "bug", swatch: .red).isToggle == false)
    }

    @Test("static tag and lit toggle variants both construct (compile smoke)")
    func constructs() {
        _ = AinkradSwatchChip(label: "docs", swatch: .blue)
        _ = AinkradSwatchChip(label: "docs", swatch: .blue, isOn: true, onTap: {})
    }
}

@Suite("AinkradBadge")
struct AinkradBadgeTests {
    @Test("status and tint variants both construct (compile smoke)")
    func constructs() {
        _ = AinkradBadge(text: "neutral")
        _ = AinkradBadge(text: "ok", status: .success)
        _ = AinkradBadge(text: "open", tint: .green)
        _ = AinkradBadge(text: "merged", tint: .purple)
    }
}

@Suite("AinkradStatus")
struct AinkradStatusTests {
    @Test("four cases")
    func caseCount() {
        #expect(AinkradStatus.allCases.count == 4)
    }

    @Test("color(in:statusColors:) picks the matching field — neutral from theme, others from AinkradStatusColors")
    func colorMapping() {
        let theme = HostThemeTokens(
            themeID: "test", background: .black, surface: .gray, surfaceElevated: .gray,
            accentPrimary: .blue, accentSecondary: .purple, accentTertiary: .pink,
            foreground: .white
        )
        let statusColors = AinkradStatusColors(success: .green, warning: .yellow, danger: .red)
        #expect(AinkradStatus.success.color(in: theme, statusColors: statusColors) == statusColors.success)
        #expect(AinkradStatus.warning.color(in: theme, statusColors: statusColors) == statusColors.warning)
        #expect(AinkradStatus.danger.color(in: theme, statusColors: statusColors) == statusColors.danger)
        #expect(AinkradStatus.neutral.color(in: theme, statusColors: statusColors) == theme.foreground)
    }
}
