import SwiftUI
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Fixtures for components from catalogue §6 in every state their PUBLIC init can set.
struct SkinParityFixture {
    let name: String
    let view: AnyView
}

@MainActor
enum SkinParityFixtures {
    static var allFixtures: [SkinParityFixture] {
        var list: [SkinParityFixture] = []

        // --- Surfaces ---
        list.append(SkinParityFixture(name: "panel-default", view: AnyView(AinkradPanel { Text("Panel") })))
        list.append(SkinParityFixture(name: "panel-brackets", view: AnyView(AinkradPanel(showsBrackets: true) { Text("Brackets") })))
        list.append(SkinParityFixture(name: "card-rest", view: AnyView(AinkradCard { Text("Card Rest") })))
        list.append(SkinParityFixture(name: "card-selected", view: AnyView(AinkradCard(isSelected: true) { Text("Card Selected") })))
        list.append(SkinParityFixture(name: "sectionFrame-default", view: AnyView(AinkradSectionFrame(title: "Section") { Text("Content") })))
        list.append(SkinParityFixture(name: "settingsPanel-default", view: AnyView(AinkradSettingsPanel(title: "Settings", hint: "Hint") { Text("Body") })))
        list.append(SkinParityFixture(name: "captionedRow-default", view: AnyView(AinkradCaptionedRow("Label") { Text("Value") })))
        list.append(SkinParityFixture(name: "codeBlock-default", view: AnyView(AinkradCodeBlock("let x = 42", language: "swift"))))

        // --- Buttons, chips, tiles ---
        for style in AinkradButtonStyle.allCases {
            list.append(SkinParityFixture(name: "button-\(style)-rest", view: AnyView(AinkradButton(title: "Action", style: style) {})))
            list.append(SkinParityFixture(name: "button-\(style)-loading", view: AnyView(AinkradButton(title: "Action", style: style, isLoading: true) {})))
            list.append(SkinParityFixture(name: "button-\(style)-disabled", view: AnyView(AinkradButton(title: "Action", style: style) {}.disabled(true))))
        }
        list.append(SkinParityFixture(name: "iconButton-rest", view: AnyView(AinkradIconButton(systemName: "gear") {})))
        list.append(SkinParityFixture(name: "iconButton-disabled", view: AnyView(AinkradIconButton(systemName: "gear") {}.disabled(true))))
        list.append(SkinParityFixture(name: "appTile-rest", view: AnyView(AinkradAppTile(symbol: "square.grid.2x2", title: "App"))))
        list.append(SkinParityFixture(name: "appTile-selected", view: AnyView(AinkradAppTile(symbol: "square.grid.2x2", title: "App", isSelected: true))))
        list.append(SkinParityFixture(name: "chip-rest", view: AnyView(AinkradChip(label: "Tag"))))
        list.append(SkinParityFixture(name: "swatchChip-off", view: AnyView(AinkradSwatchChip(label: "Color", swatch: .blue, isOn: false))))
        list.append(SkinParityFixture(name: "swatchChip-on", view: AnyView(AinkradSwatchChip(label: "Color", swatch: .blue, isOn: true))))
        list.append(SkinParityFixture(name: "badge-default", view: AnyView(AinkradBadge(text: "Beta"))))
        list.append(SkinParityFixture(name: "kbd-default", view: AnyView(AinkradKbd("⌘K"))))
        list.append(SkinParityFixture(name: "basicShell-default", view: AnyView(AinkradBasicShell(title: "Shell", subtitle: "Sub") { Text("Main Content") })))

        // --- Form controls ---
        list.append(SkinParityFixture(name: "toggle-off", view: AnyView(AinkradToggle(isOn: .constant(false)))))
        list.append(SkinParityFixture(name: "toggle-on", view: AnyView(AinkradToggle(isOn: .constant(true)))))
        list.append(SkinParityFixture(name: "toggle-disabled", view: AnyView(AinkradToggle(isOn: .constant(false)).disabled(true))))
        list.append(SkinParityFixture(name: "textField-empty", view: AnyView(AinkradTextField(text: .constant(""), placeholder: "Enter text"))))
        list.append(SkinParityFixture(name: "textField-filled", view: AnyView(AinkradTextField(text: .constant("Hello"), placeholder: "Enter text"))))
        list.append(SkinParityFixture(name: "secureField-filled", view: AnyView(AinkradSecureField(text: .constant("Secret"), placeholder: "Password"))))
        list.append(SkinParityFixture(name: "searchField-empty", view: AnyView(AinkradSearchField(text: .constant(""), placeholder: "Search"))))
        list.append(SkinParityFixture(name: "textArea-empty", view: AnyView(AinkradTextArea(text: .constant(""), placeholder: "Notes"))))
        list.append(SkinParityFixture(name: "slider-default", view: AnyView(AinkradSlider(value: .constant(0.5), in: 0...1))))
        list.append(SkinParityFixture(name: "formRow-default", view: AnyView(AinkradFormRow(title: "Setting", help: "Explanation") { Text("Control") })))
        list.append(SkinParityFixture(name: "stepper-default", view: AnyView(AinkradStepper(value: .constant(5), in: 0...10))))
        list.append(SkinParityFixture(name: "checkbox-off", view: AnyView(AinkradCheckbox(isOn: .constant(false), label: "Agree"))))
        list.append(SkinParityFixture(name: "checkbox-on", view: AnyView(AinkradCheckbox(isOn: .constant(true), label: "Agree"))))

        // --- Pickers, menus, navigation ---
        list.append(SkinParityFixture(name: "segmentedPicker-default", view: AnyView(AinkradSegmentedPicker(items: ["A", "B", "C"], selection: .constant("A"), label: { $0 }))))
        list.append(SkinParityFixture(name: "tabs-default", view: AnyView(AinkradTabs(tabs: ["Tab 1", "Tab 2"], selection: .constant("Tab 1"), label: { $0 }))))
        list.append(SkinParityFixture(name: "breadcrumb-default", view: AnyView(AinkradBreadcrumb(items: ["Home", "Settings", "General"]))))
        list.append(SkinParityFixture(name: "pagination-default", view: AnyView(AinkradPagination(page: .constant(1), pageCount: 5))))

        // --- Rows, tables, state, status ---
        list.append(SkinParityFixture(name: "listRow-rest", view: AnyView(AinkradListRow(leading: { EmptyView() }, title: "Item 1", subtitle: "Detail", trailing: { EmptyView() }))))
        list.append(SkinParityFixture(name: "listRow-selected", view: AnyView(AinkradListRow(isSelected: true, leading: { EmptyView() }, title: "Item 1", subtitle: "Detail", trailing: { EmptyView() }))))
        list.append(SkinParityFixture(name: "statRow-default", view: AnyView(AinkradStatRow(label: "CPU", value: "12%"))))
        list.append(SkinParityFixture(name: "iconGlyph-default", view: AnyView(AinkradIconGlyph(systemName: "star"))))
        list.append(SkinParityFixture(name: "emptyState-default", view: AnyView(AinkradEmptyState(icon: "tray", title: "No Data", message: "Try refreshing"))))
        list.append(SkinParityFixture(name: "loadingState-default", view: AnyView(AinkradLoadingState(label: "Loading..."))))
        list.append(SkinParityFixture(name: "errorState-default", view: AnyView(AinkradErrorState(message: "Failed to load"))))
        list.append(SkinParityFixture(name: "sectionHeader-default", view: AnyView(AinkradSectionHeader(title: "HEADER", subtitle: "Sub"))))
        list.append(SkinParityFixture(name: "statusBar-default", view: AnyView(AinkradStatusBar(value: 0.65))))
        list.append(SkinParityFixture(name: "spinner-default", view: AnyView(AinkradSpinner())))
        list.append(SkinParityFixture(name: "meter-default", view: AnyView(AinkradMeter(value: 75, label: "Memory"))))
        for status in [AinkradStatus.neutral, AinkradStatus.success, AinkradStatus.warning, AinkradStatus.danger] {
            list.append(SkinParityFixture(name: "banner-\(status)", view: AnyView(AinkradBanner(message: "Notice message", status: status))))
        }

        list.append(contentsOf: SkinParityFixturesExtended.fixtures)
        list.append(contentsOf: SkinParityFixturesMissing.fixtures)
        return list
    }
}

