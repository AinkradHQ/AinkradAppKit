import AppKit
import Observation
import SwiftUI
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract

@MainActor @Observable private final class OpacityStore { var value = 0.7 }

@Suite("SettingsRow slider")
@MainActor
struct SettingsRowSliderTests {
    /// The field is built ONCE, as the host's catalog builds it; the thumb
    /// must still follow the store. It froze when the row wrapped the
    /// field's binding in `Binding(get:set:)`.
    @Test("the thumb follows the store when the field outlives the change")
    func thumbFollowsStore() async throws {
        let store = OpacityStore()
        let field = SettingsField(
            path: SettingsPath(["p", "opacity"]), label: "Opacity",
            kind: .slider(
                range: 0.3...1.0, step: 0.05,
                value: Binding(get: { store.value }, set: { store.value = $0 })))
        let host = NSHostingView(rootView: SettingsRow(field: field, layout: .sideBySide).frame(width: 900))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 120), styleMask: [.borderless], backing: .buffered,
            defer: false)
        window.contentView = host
        window.orderFrontRegardless()
        defer { window.orderOut(nil) }
        func snapshot() async throws -> Data? {
            try await Task.sleep(for: .milliseconds(300))
            let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: rep)
            return rep.representation(using: .png, properties: [:])
        }
        let before = try await snapshot()
        store.value = 0.35
        let after = try await snapshot()
        #expect(before != after)
    }

    @Test("writes through the row's binding snap to the step")
    func writesQuantize() {
        var value = 0.7
        let binding = Binding(get: { value }, set: { value = $0 })
        let stepped = binding[quantizedBy: SettingsSliderStep(step: 0.05, range: 0.3...1.0)]
        stepped.wrappedValue = 0.52
        #expect(abs(value - 0.5) < 1e-9)
        stepped.wrappedValue = 2
        #expect(value == 1.0)
    }
}
