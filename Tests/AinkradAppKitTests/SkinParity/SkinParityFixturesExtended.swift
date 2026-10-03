import SwiftUI
import AppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI
import AinkradSignal

/// Extended fixtures for controls, pickers, surfaces, navigation, overlays, status, log, and signal components.
@MainActor
enum SkinParityFixturesExtended {
    static var fixtures: [SkinParityFixture] {
        var list: [SkinParityFixture] = []

        // --- Pickers & Panels ---
        list.append(SkinParityFixture(name: "colorPicker-default", view: AnyView(
            AinkradColorPicker(selection: .constant(.blue))
        )))

        list.append(SkinParityFixture(name: "confirmDialog-card-rest", view: AnyView(
            AinkradConfirmDialogCard(
                title: "Delete Item",
                message: "Are you sure you want to delete this item?",
                confirmTitle: "Delete",
                isDestructive: true,
                onCancel: {},
                onConfirm: {}
            )
        )))

        list.append(SkinParityFixture(name: "confirmDialog-card-neutral", view: AnyView(
            AinkradConfirmDialogCard(
                title: "Save Changes",
                message: "Do you want to save changes before closing?",
                confirmTitle: "Save",
                isDestructive: false,
                onCancel: {},
                onConfirm: {}
            )
        )))

        let menuItems = [
            AinkradMenuItem(title: "Edit", systemName: "pencil", shortcut: "⌘E", action: {}),
            AinkradMenuItem(title: "Delete", systemName: "trash", isDestructive: true, action: {})
        ]

        list.append(SkinParityFixture(name: "menuButton-default", view: AnyView(
            AinkradMenuButton(items: menuItems) {
                Text("Options")
            }
        )))

        // --- Data Table ---
        struct SampleRow: Identifiable {
            let id: String
            let name: String
            let role: String
        }
        let sampleRows = [
            SampleRow(id: "1", name: "Alice", role: "Admin"),
            SampleRow(id: "2", name: "Bob", role: "User")
        ]
        let tableColumns = [
            AinkradTableColumn<SampleRow>(id: "name", title: "Name", cell: { $0.name }),
            AinkradTableColumn<SampleRow>(id: "role", title: "Role", cell: { $0.role })
        ]

        list.append(SkinParityFixture(name: "dataTable-default", view: AnyView(
            AinkradDataTable(rows: sampleRows, columns: tableColumns)
        )))
        list.append(SkinParityFixture(name: "dataTable-sorted", view: AnyView(
            AinkradDataTable(rows: sampleRows, columns: tableColumns, sort: .constant(AinkradTableSort(columnID: "name", ascending: true)))
        )))
        list.append(SkinParityFixture(name: "dataTable-selected", view: AnyView(
            AinkradDataTable(rows: sampleRows, columns: tableColumns, selection: .constant(["1"]))
        )))

        // --- Disclosure Group ---
        list.append(SkinParityFixture(name: "disclosureGroup-collapsed", view: AnyView(
            AinkradDisclosureGroup(title: "Advanced", isExpanded: .constant(false)) {
                Text("Inner Content")
            }
        )))
        list.append(SkinParityFixture(name: "disclosureGroup-expanded", view: AnyView(
            AinkradDisclosureGroup(title: "Advanced", isExpanded: .constant(true), hitCount: 3) {
                Text("Inner Content")
            }
        )))

        // --- Labels ---
        list.append(SkinParityFixture(name: "label-plain", view: AnyView(
            AinkradLabel("Plain Label")
        )))
        list.append(SkinParityFixture(name: "label-withIcon", view: AnyView(
            AinkradLabel("Icon Label", systemName: "star.fill")
        )))
        list.append(SkinParityFixture(name: "caption-default", view: AnyView(
            AinkradCaption("Caption Text")
        )))

        // --- Overlays & Modals ---
        list.append(SkinParityFixture(name: "drawer-content", view: AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Drawer Header")
                Text("Drawer Body Content")
            }
            .padding()
            .frame(width: 240)
            .ainkradPanel(showsBrackets: true)
        )))

        list.append(SkinParityFixture(name: "floatingPanel-content", view: AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text("Floating Panel Title")
                Text("Detail description goes here.")
            }
            .padding()
            .background(ChamferShape(cut: 8).fill(Color.black.opacity(0.8)))
        )))

        list.append(SkinParityFixture(name: "modal-content", view: AnyView(
            VStack(spacing: 16) {
                Text("Modal Title")
                Text("Modal Body Description")
            }
            .padding()
            .frame(width: 320)
            .ainkradPanel(showsBrackets: true)
        )))

        list.append(SkinParityFixture(name: "tooltipPopover-bubble", view: AnyView(
            Text("Tooltip/Popover Content")
                .font(.caption)
                .padding(8)
                .background(ChamferShape(cut: 6).fill(Color.black.opacity(0.8)))
        )))

        // --- Grouped Select ---
        let groupedSections = [
            AinkradGroupedSection(header: "Section 1", rows: [
                AinkradGroupedRow(value: "opt1", title: "Option 1", detail: "Detail 1", icon: "folder"),
                AinkradGroupedRow(value: "opt2", title: "Option 2", detail: "Detail 2", isEnabled: false)
            ])
        ]
        list.append(SkinParityFixture(name: "groupedSelect-trigger", view: AnyView(
            AinkradGroupedSelect(sections: groupedSections, selection: .constant("opt1"), triggerLabel: "Select option...")
        )))

        // --- Pickers ---
        let pickerItems = ["Option A", "Option B", "Option C"]
        list.append(SkinParityFixture(name: "select-trigger", view: AnyView(
            AinkradSelect(items: pickerItems, selection: .constant("Option A"), label: { $0 })
        )))
        list.append(SkinParityFixture(name: "multiSelect-trigger", view: AnyView(
            AinkradMultiSelect(items: pickerItems, selection: .constant(["Option A"]), label: { $0 })
        )))
        list.append(SkinParityFixture(name: "combobox-trigger", view: AnyView(
            AinkradCombobox(items: pickerItems, selection: .constant("Option A"), text: .constant("Option A"), label: { $0 })
        )))
        list.append(SkinParityFixture(name: "searchableSelect-trigger", view: AnyView(
            AinkradSearchableSelect(items: pickerItems, selection: .constant("Option A"), label: { $0 })
        )))

        // --- Navigation ---
        let navItems = ["Home", "Settings", "Profile"]
        list.append(SkinParityFixture(name: "commandMenu-default", view: AnyView(
            AinkradCommandMenu(items: navItems, selection: .constant("Home"), icon: { _ in "star" }, label: { $0 })
        )))
        list.append(SkinParityFixture(name: "navList-default", view: AnyView(
            AinkradNavList(items: navItems, selection: .constant("Home"), icon: { _ in "folder" }, label: { $0 })
        )))

        // --- Status & Logs ---
        let statusRuns = [
            AinkradStatusRun(count: 10, status: .success),
            AinkradStatusRun(count: 3, status: .warning),
            AinkradStatusRun(count: 1, status: .danger)
        ]
        list.append(SkinParityFixture(name: "stackedStatusBar-default", view: AnyView(
            AinkradStackedStatusBar(runs: statusRuns)
                .frame(width: 200)
        )))

        var logBuffer = AinkradLogBuffer(capacity: 10)
        logBuffer.append(Data("\u{001B}[32mINFO:\u{001B}[0m System initialized successfully\n".utf8))
        logBuffer.append(Data("\u{001B}[33mWARN:\u{001B}[0m Memory usage above 80%\n".utf8))
        logBuffer.append(Data("\u{001B}[31mERROR:\u{001B}[0m Connection timeout\n".utf8))
        let logLines = logBuffer.all

        let ansiPalette = AinkradANSIPalette(theme: .fallbackDark, statusColors: .default)
        list.append(SkinParityFixture(name: "logView-ansi", view: AnyView(
            AinkradLogView(lines: logLines, palette: ansiPalette, foreground: .white)
                .frame(width: 380, height: 120)
        )))

        // --- Signal Family ---
        let sampleEvent1 = SignalEvent(
            timestamp: Date(timeIntervalSince1970: 1700000000),
            source: .app(appID: "com.ainkrad.app"),
            kind: "build",
            severity: .success,
            title: "Build Succeeded",
            body: "Project compiled in 1.2s"
        )
        let sampleEvent2 = SignalEvent(
            timestamp: Date(timeIntervalSince1970: 1700000060),
            source: .host,
            kind: "task",
            severity: .failure,
            title: "Task Failed",
            body: "Process exited with code 1"
        )

        list.append(SkinParityFixture(name: "signalFeedRow-unread", view: AnyView(
            SignalFeedRow(event: sampleEvent1, repeatCount: 1, isUnread: true)
        )))
        list.append(SkinParityFixture(name: "signalFeedRow-read", view: AnyView(
            SignalFeedRow(event: sampleEvent2, repeatCount: 1, isUnread: false)
        )))

        list.append(SkinParityFixture(name: "signalFeedList-default", view: AnyView(
            SignalFeedList(events: [sampleEvent1, sampleEvent2])
        )))

        let railItems = SignalSourceRailItem.build(
            events: [sampleEvent1, sampleEvent2],
            readIDs: [],
            name: { "\($0)".capitalized }
        )
        list.append(SkinParityFixture(name: "signalSourceRail-default", view: AnyView(
            SignalSourceRail(items: railItems, selection: .constant(nil))
        )))

        let toastModel = SignalToastModel()
        toastModel.present(sampleEvent1)
        list.append(SkinParityFixture(name: "signalToastStack-default", view: AnyView(
            SignalToastStack(model: toastModel)
        )))

        let dummyEvents = [sampleEvent1, sampleEvent2]
        final class DummyEmitter: PluginSignalEmitter {
            let events: [SignalEvent]
            init(events: [SignalEvent]) { self.events = events }
            func emit(kind: String, severity: SignalSeverity, title: String, body: String?, importance: SignalImportance, deepLink: SignalDeepLink?, actions: [SignalAction], dedupeKey: String?) {}
            func own(limit: Int) -> [SignalEvent] { events }
            func handleAction(_ actionID: String, _ handler: @escaping @MainActor () async -> Void) -> AgentActionToken { AgentActionToken() }
            func removeActionHandler(_ token: AgentActionToken) {}
        }
        list.append(SkinParityFixture(name: "signalFeedView-default", view: AnyView(
            SignalFeedView(scope: .own, emitter: DummyEmitter(events: dummyEvents))
        )))

        return list
    }
}


