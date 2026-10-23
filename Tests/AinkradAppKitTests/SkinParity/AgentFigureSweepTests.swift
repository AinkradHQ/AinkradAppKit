import AppKit
import Foundation
import SwiftUI
import Testing

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// Agent figure tools, not checks — each runs only when its variable is set:
/// - AINKRAD_FIGURE_SWEEP_DIR (+ AINKRAD_THEMES_DIR): every state at
///   256/64/32/24/16, the 128 state grid, palettes and harness marks, under
///   Neon and Glass, shot in a real desktop-level window.
/// - AINKRAD_FIGURE_VIDEO: records the state cycle at 256 pt to that .mov path.
@Suite("AgentFigureSweepTests", .serialized)
@MainActor
struct AgentFigureSweepTests {
    static let sizes: [CGFloat] = [256, 64, 32, 24, 16]
    static let states = AinkradFigureState.allCases.filter { $0 != .error }

    @Test("shoot every state at every size under Neon and Glass")
    func sweep() throws {
        let env = ProcessInfo.processInfo.environment
        guard let out = env["AINKRAD_FIGURE_SWEEP_DIR"], let themes = env["AINKRAD_THEMES_DIR"] else {
            print("SKIPPED: set AINKRAD_FIGURE_SWEEP_DIR and AINKRAD_THEMES_DIR — no figure sweep")
            return
        }
        let glass = try NativeGlassSweepTests.glassSkin(themes: URL(fileURLWithPath: themes))
        try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
        var sheets: [(String, AnyView, CGSize)] = Self.states.map { state in
            let row = HStack(alignment: .bottom, spacing: 28) {
                ForEach(Self.sizes, id: \.self) { size in
                    VStack(spacing: 6) {
                        AinkradAgentFigure(name: "Mira", state: state, harness: .claude, size: size)
                        Text("\(Int(size))").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            return ("figure-\(state.rawValue)", AnyView(row), CGSize(width: 720, height: 360))
        }
        let grid = LazyVGrid(columns: Array(repeating: GridItem(.fixed(170)), count: 5), spacing: 18) {
            ForEach(AinkradFigureState.allCases, id: \.self) { state in
                VStack(spacing: 4) {
                    AinkradAgentFigure(name: state.rawValue, state: state, harness: .claude, size: 128)
                    Text(state.rawValue).font(.caption)
                }
            }
        }
        sheets.append(("figure-states128", AnyView(grid), CGSize(width: 920, height: 400)))
        let pals = LazyVGrid(columns: Array(repeating: GridItem(.fixed(78)), count: 9), spacing: 12) {
            ForEach(AinkradFigurePalette.all + [.muted], id: \.id) { palette in
                VStack(spacing: 4) {
                    AinkradAgentFigure(
                        name: palette.id, state: palette == .muted ? .rest : .idle, palette: palette, size: 56)
                    Text(palette.name).font(.caption2)
                }
            }
        }
        sheets.append(("figure-palettes", AnyView(pals), CGSize(width: 760, height: 220)))
        let marks = HStack(spacing: 20) {
            ForEach([AinkradFigureHarness.claude, .codex, .openCode, .agy], id: \.self) { harness in
                VStack(spacing: 4) {
                    AinkradAgentFigure(name: harness.name, state: .working, harness: harness, size: 64)
                    Text(harness.name).font(.caption2)
                }
            }
            VStack(spacing: 4) {
                AinkradAgentFigure(name: "Eyes off", state: .idle, harness: .claude, size: 64, showsEyes: false)
                Text("eyes off").font(.caption2)
            }
            VStack(spacing: 4) {
                AinkradAgentFigure(
                    name: "Upload", state: .working, harness: .codex, size: 64,
                    image: Image(nsImage: Self.uploadSample))
                Text("upload").font(.caption2)
            }
        }
        sheets.append(("figure-harness", AnyView(marks), CGSize(width: 640, height: 150)))
        for (name, view, size) in sheets {
            for (theme, skin) in [("neon", AinkradSkin.standard), ("glass", glass)] {
                try LiveGlassCapture.shoot(
                    view.frame(width: size.width, height: size.height)
                        .background(skin.color(skin.palette.background))
                        .ainkradSkin(skin).environment(\.colorScheme, .dark),
                    size: size, to: URL(fileURLWithPath: out).appendingPathComponent("\(name)-\(theme).png"))
            }
        }
    }

    /// A stand-in "uploaded" picture: a two-colour gradient with a glyph.
    static var uploadSample: NSImage {
        NSImage(size: NSSize(width: 96, height: 96), flipped: false) { rect in
            NSGradient(starting: .systemOrange, ending: .systemPurple)?.draw(in: rect, angle: 45)
            ("AK" as NSString).draw(
                at: NSPoint(x: 26, y: 30),
                withAttributes: [.font: NSFont.boldSystemFont(ofSize: 30), .foregroundColor: NSColor.white])
            return true
        }
    }

    @Test("record the state cycle at 256 pt")
    func video() throws {
        guard let path = ProcessInfo.processInfo.environment["AINKRAD_FIGURE_VIDEO"] else {
            print("SKIPPED: set AINKRAD_FIGURE_VIDEO — no figure video")
            return
        }
        let model = CycleModel()
        let panel = Self.desktopPanel(size: CGSize(width: 420, height: 420)) {
            CycleStage(model: model).background(Color(red: 0.02, green: 0.03, blue: 0.05))
        }
        defer { panel.orderOut(nil) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        let seconds = Double(Self.states.count) * 2.6
        let rec = Process()
        rec.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        rec.arguments = ["-x", "-v", "-V\(Int(seconds.rounded(.up)))", "-l\(panel.windowNumber)", path]
        try rec.run()
        RunLoop.main.run(until: Date().addingTimeInterval(1.0))
        for state in Self.states {
            model.state = state
            RunLoop.main.run(until: Date().addingTimeInterval(2.6))
        }
        rec.waitUntilExit()
        #expect(rec.terminationStatus == 0)
    }

    /// A borderless window at desktop level — behind every other window, no
    /// focus taken — animating under the full motion budget.
    static func desktopPanel(size: CGSize, @ViewBuilder _ content: () -> some View) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: CGPoint(x: 120, y: 120), size: size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.hasShadow = false
        panel.contentView = NSHostingView(
            rootView: content()
                .frame(width: size.width, height: size.height)
                .background(Color(red: 0.02, green: 0.03, blue: 0.05))
                .environment(\.ainkradMotionBudget, .full))
        panel.orderFrontRegardless()
        return panel
    }
}

@MainActor
private final class CycleModel: ObservableObject {
    @Published var state: AinkradFigureState = .rest
}

private struct CycleStage: View {
    @ObservedObject var model: CycleModel

    var body: some View {
        VStack(spacing: 4) {
            AinkradAgentFigure(name: "Mira", state: model.state, harness: .claude, size: 256, isActive: true)
            Text(model.state.rawValue).font(.headline).foregroundStyle(.white)
        }
        .frame(width: 420, height: 420)
    }
}
