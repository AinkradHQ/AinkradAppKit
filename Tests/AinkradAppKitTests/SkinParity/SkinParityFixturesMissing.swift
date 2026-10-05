import AppKit
import SwiftUI

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

private struct DummyPresentationControl: PluginPresentationControl {
    var current: PluginPresentation = .pane
    func set(_ presentation: PluginPresentation) {}
    func reset() {}
}

private struct DummyModeControl: PluginModeControl {
    var current: PluginMode = .advanced
    func set(_ mode: PluginMode) {}
    func reset() {}
}

private struct DummyOverlaySizeControl: PluginOverlaySizeControl {
    var current: PluginOverlaySize = .default
    func set(_ size: PluginOverlaySize) {}
    func reset() {}
}

@MainActor
enum SkinParityFixturesMissing {
    static var fixtures: [SkinParityFixture] {
        var list: [SkinParityFixture] = []

        // 1. AccentRule
        list.append(
            SkinParityFixture(
                name: "accentRule-unlabeled",
                view: AnyView(
                    AccentRule()
                )))
        list.append(
            SkinParityFixture(
                name: "accentRule-labeled",
                view: AnyView(
                    AccentRule(label: "Section Accent")
                )))

        // 2. AinkradModeSwitch (both modes)
        list.append(
            SkinParityFixture(
                name: "modeSwitch-advanced",
                view: AnyView(
                    AinkradModeSwitch()
                        .environment(\.ainkradPaneMode, .advanced)
                )))
        list.append(
            SkinParityFixture(
                name: "modeSwitch-basic",
                view: AnyView(
                    AinkradModeSwitch()
                        .environment(\.ainkradPaneMode, .basic)
                )))

        // 3. AinkradPopover (render content)
        list.append(
            SkinParityFixture(
                name: "popover-content",
                view: AnyView(
                    Text("Popover Content View")
                        .ainkradPopover(isPresented: .constant(true)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Popover Header").bold()
                                Text("Popover detail body content goes here.")
                            }
                        }
                        .frame(width: 300, height: 200)
                )))

        // 4. AinkradRadioGroup (a selection)
        let radioOptions = ["Option 1", "Option 2", "Option 3"]
        list.append(
            SkinParityFixture(
                name: "radioGroup-selected",
                view: AnyView(
                    AinkradRadioGroup(options: radioOptions, selection: .constant("Option 2"), label: { $0 })
                )))

        // 5. AinkradRangeSlider
        list.append(
            SkinParityFixture(
                name: "rangeSlider-default",
                view: AnyView(
                    AinkradRangeSlider(range: .constant(0.2...0.8), bounds: 0.0...1.0)
                        .frame(width: 200)
                )))

        // 6. AinkradSurfaceSettings
        list.append(
            SkinParityFixture(
                name: "surfaceSettings-default",
                view: AnyView(
                    AinkradSurfaceSettings(
                        appName: "TestApp",
                        presentation: DummyPresentationControl(),
                        mode: DummyModeControl(),
                        overlaySize: DummyOverlaySizeControl()
                    )
                    .frame(width: 320)
                )))

        // 7. AinkradToggleButton (off + on)
        list.append(
            SkinParityFixture(
                name: "toggleButton-off",
                view: AnyView(
                    AinkradToggleButton(isOn: .constant(false), systemName: "star", title: "Favorite")
                )))
        list.append(
            SkinParityFixture(
                name: "toggleButton-on",
                view: AnyView(
                    AinkradToggleButton(isOn: .constant(true), systemName: "star", title: "Favorite")
                )))

        // 8. AinkradRailItem (rest, selected, unread, capped unread, muted)
        let rail: [(String, AinkradRailItem)] = [
            ("rest", AinkradRailItem(systemName: "message", help: "Chat", isSelected: false, action: nil)),
            ("selected", AinkradRailItem(systemName: "message", help: "Chat", isSelected: true, action: nil)),
            ("unread", AinkradRailItem(systemName: "message", help: "Chat", isSelected: false, unread: 3, action: nil)),
            (
                "unread-capped",
                AinkradRailItem(systemName: "message", help: "Chat", isSelected: false, unread: 120, action: nil)
            ),
            (
                "muted",
                AinkradRailItem(
                    systemName: "message", help: "Chat", isSelected: false, isDimmed: true,
                    cornerSymbol: "bell.slash.fill", action: nil)
            ),
        ]
        for (name, item) in rail {
            list.append(
                SkinParityFixture(name: "railItem-\(name)", view: AnyView(item.frame(width: 60))))
        }

        list.append(
            SkinParityFixture(
                name: "brandChevron-16x14",
                view: AnyView(AinkradBrandChevron().fill(BrandChevronAccent()).frame(width: 16, height: 14))))

        // 9. .ainkradRowBackground on a plain row (rest, hovered, selected)
        for (name, selected, hovered) in [("rest", false, false), ("hovered", false, true), ("selected", true, false)] {
            list.append(
                SkinParityFixture(
                    name: "rowBackground-\(name)",
                    view: AnyView(
                        Text("Plain row")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(width: 200, alignment: .leading)
                            .ainkradRowBackground(isSelected: selected, isHovered: hovered))))
        }

        return list
    }
}

private struct BrandChevronAccent: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        environment.ainkradSkin.color(environment.ainkradSkin.palette.accentPrimary).resolve(in: environment)
    }
}
