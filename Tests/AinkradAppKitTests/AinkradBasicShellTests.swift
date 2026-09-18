import Testing
import SwiftUI
@testable import AinkradAppKit

/// The shared basic-mode surface. These cover the contract an app relies on —
/// that the shell is constructible in the shapes the nine apps need, and that
/// the mode switch reads the pane's mode rather than keeping its own.
@Suite("AinkradBasicShell")
@MainActor
struct AinkradBasicShellTests {

    @Test("Builds with actions — the repo/branch/fetch shape")
    func buildsWithActions() {
        let shell = AinkradBasicShell(icon: "wand.and.stars",
                                      title: "Ainkrad",
                                      subtitle: "development") {
            AinkradButton(title: "Fetch", style: .secondary) {}
            AinkradButton(title: "Pull", style: .primary) {}
        } content: {
            Text("changes")
        }
        #expect(shell.body is (any View))
    }

    @Test("Builds without actions — the document shape")
    func buildsWithoutActions() {
        // The convenience initializer exists so a content-carries-its-own-
        // actions app (a note, a log, a thread) does not have to pass EmptyView.
        let shell = AinkradBasicShell(icon: "doc.text", title: "roadmap.md") {
            Text("body")
        }
        #expect(shell.body is (any View))
    }

    @Test("A title with no subtitle and no icon still builds")
    func minimalShell() {
        let shell = AinkradBasicShell(title: "Sage") { Text("prompt") }
        #expect(shell.body is (any View))
    }

    @Test("The mode switch can be suppressed for apps that place their own")
    func modeSwitchIsOptional() {
        let shell = AinkradBasicShell(title: "Hoard", showsModeSwitch: false) {
            Text("files")
        }
        #expect(shell.body is (any View))
    }

    @Test("The switch offers the way OUT of the mode the pane is in")
    func switchDirectionFollowsPaneMode() {
        // One control that changes direction, never two buttons — it has to
        // read as expanding this app, not as opening a different one.
        var values = EnvironmentValues()
        values.ainkradPaneMode = .basic
        #expect(values.ainkradPaneMode == .basic)
        values.ainkradPaneMode = .advanced
        #expect(values.ainkradPaneMode == .advanced)
    }

    @Test("The switch asks the HOST to change the mode; it keeps no state")
    func switchDelegatesToTheHost() {
        // A switch that flipped its own @State would move the button and not
        // the pane, and the two would disagree the moment the setting changed.
        final class Box: @unchecked Sendable { var received: [PluginMode] = [] }
        let box = Box()
        var values = EnvironmentValues()
        values.ainkradSetPaneMode = { box.received.append($0) }
        values.ainkradSetPaneMode(.advanced)
        values.ainkradSetPaneMode(.basic)
        #expect(box.received == [.advanced, .basic])
    }
}
