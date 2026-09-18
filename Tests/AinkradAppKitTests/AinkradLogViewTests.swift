import Foundation
import Testing
import AppKit
import SwiftUI
@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

private func sameColor(_ lhs: NSColor?, _ rhs: NSColor) -> Bool {
    guard let a = lhs?.usingColorSpace(.sRGB), let b = rhs.usingColorSpace(.sRGB) else { return false }
    return abs(a.redComponent - b.redComponent) < 0.01 && abs(a.greenComponent - b.greenComponent) < 0.01
        && abs(a.blueComponent - b.blueComponent) < 0.01 && abs(a.alphaComponent - b.alphaComponent) < 0.01
}

private func firstSubview<T: NSView>(of type: T.Type, in view: NSView) -> T? {
    if let match = view as? T { return match }
    for child in view.subviews { if let match = firstSubview(of: type, in: child) { return match } }
    return nil
}

@Suite("AinkradLogView")
@MainActor
struct AinkradLogViewTests {
    private let theme = EnvironmentValues().ainkradTheme
    private var palette: AinkradANSIPalette { AinkradANSIPalette(theme: theme, statusColors: .default) }

    private func lines(_ fill: (inout AinkradLogBuffer) -> Void) -> [AinkradLogLine] {
        var buffer = AinkradLogBuffer()
        fill(&buffer)
        return buffer.all
    }

    private func render(_ lines: [AinkradLogLine], prefixed: Bool = false) -> NSAttributedString {
        AinkradLogView.attributedLog(lines: lines, palette: palette, foreground: theme.foreground, showsSourcePrefix: prefixed)
    }

    // Ported from Thrall's "Log service column" tests.

    /// The first version always cut to 14 and silently turned
    /// `runtime-head-hunter` into `runtime-head-h`, a name that exists nowhere.
    @Test("a long source name is truncated visibly, not silently")
    func longNameIsMarked() {
        let rendered = AinkradLogView.sourcePrefix("runtime-head-hunter")
        #expect(rendered.count == 16)
        #expect(rendered.hasSuffix("\u{2026}"))
        #expect(!rendered.hasSuffix("h"), "the old behaviour looked like a real, shorter name")
    }

    @Test("a short name is padded to the column width, keeping alignment")
    func shortNamePadded() {
        #expect(AinkradLogView.sourcePrefix("api") == "api             ")
    }

    @Test("a name exactly at the width is untouched")
    func exactWidth() {
        let name = String(repeating: "x", count: 16)
        #expect(AinkradLogView.sourcePrefix(name) == name)
    }

    // New.

    @Test("each line becomes one line of text, prefixed with its source when asked")
    func text() {
        let log = lines { $0.append("hello\n", source: "api"); $0.append("world\n", source: "db") }
        #expect(render(log).string == "hello\nworld\n")
        #expect(render(log, prefixed: true).string
                == AinkradLogView.sourcePrefix("api") + " hello\n" + AinkradLogView.sourcePrefix("db") + " world\n")
    }

    /// A process that does not colour its output still separates its streams,
    /// and the reader should see which lines came from stderr.
    @Test("stderr without a colour code is drawn in the danger colour")
    func stderrIsDanger() {
        let drawn = render(lines { $0.append("oops\n", stream: .stderr) }).attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        #expect(sameColor(drawn, NSColor(palette.color(slot: 1, default: theme.foreground))))
    }

    @Test("bold runs use the semibold monospaced face")
    func bold() {
        let log = render(lines { $0.append("\u{1B}[1mloud\u{1B}[0m quiet\n") })
        #expect(log.attribute(.font, at: 0, effectiveRange: nil) as? NSFont == NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold))
        #expect(log.attribute(.font, at: 5, effectiveRange: nil) as? NSFont == NSFont.monospacedSystemFont(ofSize: 11, weight: .regular))
    }

    @Test("a hosted view shows every line of the buffer")
    func hostedShowsBuffer() throws {
        _ = NSApplication.shared
        let log = lines { for index in 0..<30 { $0.append("line \(index)\n") } }
        let host = NSHostingView(rootView: AinkradLogView(lines: log, palette: palette, foreground: theme.foreground)
            .frame(width: 400, height: 120))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 120), styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        let textView = try #require(firstSubview(of: NSTextView.self, in: host))
        #expect(textView.string == (0..<30).map { "line \($0)\n" }.joined())
        #expect(!textView.isEditable)
        #expect(textView.isSelectable)
    }
}
