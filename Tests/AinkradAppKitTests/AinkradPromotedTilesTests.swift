import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("Promoted Citadel tiles, trails and pickers")
@MainActor
struct AinkradPromotedTilesTests {
    @Test("info tiles and a filter tile bar draw")
    func tilesDraw() {
        let view = VStack(alignment: .leading, spacing: 10) {
            AinkradInfoTileGrid(tiles: [
                AinkradInfoTile(systemImage: "cpu", tint: .blue, label: "Model", value: "opus"),
                AinkradInfoTile(systemImage: "clock", tint: .orange, label: "Age", value: "4m"),
            ])
            AinkradFilterTileBar(
                tiles: [
                    AinkradFilterTile(id: "", label: "All", icon: "square.stack", count: 9, tint: .blue),
                    AinkradFilterTile(id: "doc", label: "Docs", icon: "doc", count: 0, tint: .pink),
                ], selection: ""
            ) { _ in }
        }
        #expect(PromotedRender.draws(view.frame(width: 360), width: 400, height: 200))
    }

    @Test("a step trail draws every state and its details")
    func trailDraws() {
        let trail = AinkradStepTrail(steps: [
            AinkradTrailStep(label: "run #4"), AinkradTrailStep(label: "silent", state: .warn, detail: "4m"),
            AinkradTrailStep(label: "watchdog stops it", state: .bad),
        ])
        #expect(PromotedRender.draws(trail, width: 420, height: 80))
        #expect(AinkradTrailStep(label: "x") == AinkradTrailStep(label: "x", state: .ok, detail: nil))
    }

    @Test("a sheet frame and a step bar draw")
    func sheetDraws() {
        let view = VStack(alignment: .leading) {
            AinkradStepBar(steps: ["Role", "Details", "Budget"], current: .constant(1))
            AinkradSheetFrame(tile: "CIT", title: "New company", line: "Name it") {
                Text("Body")
            } foot: {
                Text("Save")
            }
        }
        #expect(PromotedRender.draws(view.frame(width: 420), width: 460, height: 300))
    }

    @Test("a rich picker draws closed and open, with a menu and its rows")
    func pickerDraws() {
        for open in [false, true] {
            let picker = AinkradRichPicker(
                caption: "Published by", value: "Everyone", isOn: open, isOpen: .constant(open),
                icon: { Image(systemName: "person.2") },
                menu: {
                    AinkradRichMenu(header: "Published by") {
                        AinkradRichMenuRow(
                            title: "Everyone", subtitle: "all agents", count: 4, isChecked: true, action: {}
                        ) {
                            Circle().fill(.pink).frame(width: 24, height: 24)
                        }
                        AinkradRichMenuSeparator()
                    }
                })
            #expect(PromotedRender.draws(picker, width: 420, height: 260))
        }
    }
}
