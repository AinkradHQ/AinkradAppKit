import SwiftUI
import AppKit
import AinkradAppKitContract

/// A log pane backed by `NSTextView`, rendering `AinkradLogBuffer` lines
/// through an `AinkradANSIPalette`.
///
/// **Not a `LazyVStack`, and this is a measured constraint rather than a
/// preference.** 24 services at follow produce hundreds of lines a second;
/// SwiftUI's diffing cannot keep up with a list whose identity set churns that
/// fast, and it drops frames long before the memory becomes a problem.
/// `NSTextView` also brings text selection, `⌘F` and copy for free — three
/// things a log pane is useless without and each of which is real work to
/// rebuild in SwiftUI.
///
/// Rendering is **whole-buffer replace on change**, not incremental append.
/// The buffer is already bounded at a few thousand lines, so building one
/// attributed string is cheap and it removes an entire class of bug: an
/// incremental appender has to reason about the ring buffer dropping lines
/// from the front at the same time, and getting that wrong scrambles the log
/// silently.
///
/// Moved here from Thrall's `ThrallLogTextView`, unchanged in behaviour.
public struct AinkradLogView: NSViewRepresentable {
    let lines: [AinkradLogLine]
    let palette: AinkradANSIPalette
    let foreground: Color
    let showsSourcePrefix: Bool
    /// Follow mode. When on, the view scrolls to the bottom on every update;
    /// when off, the user's scroll position is left alone — scrolling away
    /// from the bottom is how someone reads what already happened.
    let isFollowing: Bool

    public init(lines: [AinkradLogLine], palette: AinkradANSIPalette, foreground: Color,
                showsSourcePrefix: Bool = false, isFollowing: Bool = true) {
        self.lines = lines
        self.palette = palette
        self.foreground = foreground
        self.showsSourcePrefix = showsSourcePrefix
        self.isFollowing = isFollowing
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        // A log is columnar output; wrapping it destroys the alignment that
        // makes it readable, so it scrolls horizontally instead.
        textView.isHorizontallyResizable = true
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                                       height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        return scrollView
    }

    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        let selected = textView.selectedRanges
        textView.textStorage?.setAttributedString(
            Self.attributedLog(lines: lines, palette: palette, foreground: foreground, showsSourcePrefix: showsSourcePrefix))
        // Preserving the selection matters: without it a follow tick wipes
        // whatever the user was in the middle of copying.
        if !isFollowing {
            textView.selectedRanges = selected
        }
        if isFollowing {
            textView.scrollToEndOfDocument(nil)
        }
    }

    /// A fixed-width source column, because alignment is what makes a
    /// multi-source tail readable.
    ///
    /// Truncation is **marked**. Thrall's first version padded to `min(14, ...)`,
    /// which always cut to 14 and silently turned `runtime-head-hunter` into
    /// `runtime-head-h` — a name that does not exist. A name the reader cannot
    /// match against its origin is worse than a wider column.
    static func sourcePrefix(_ source: String, width: Int = 16) -> String {
        guard source.count > width else {
            return source.padding(toLength: width, withPad: " ", startingAt: 0)
        }
        return String(source.prefix(width - 1)) + "\u{2026}"
    }

    static func attributedLog(lines: [AinkradLogLine], palette: AinkradANSIPalette, foreground: Color,
                              showsSourcePrefix: Bool) -> NSAttributedString {
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let boldFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
        let defaultColor = NSColor(foreground)
        let output = NSMutableAttributedString()

        for line in lines {
            if showsSourcePrefix, let source = line.source {
                output.append(NSAttributedString(
                    string: sourcePrefix(source) + " ",
                    attributes: [.font: font, .foregroundColor: defaultColor.withAlphaComponent(0.45)]))
            }
            for run in line.runs {
                var color = NSColor(palette.color(slot: run.colorSlot, default: foreground))
                // stderr is drawn toward danger even without a colour code,
                // because a process that does not colour its output still
                // distinguishes its streams and the reader should see that.
                if run.colorSlot == nil, line.stream == .stderr {
                    color = NSColor(palette.color(slot: 1, default: foreground))
                }
                if run.isDim { color = color.withAlphaComponent(0.6) }
                output.append(NSAttributedString(
                    string: run.text,
                    attributes: [.font: run.isBold ? boldFont : font, .foregroundColor: color]))
            }
            output.append(NSAttributedString(string: "\n", attributes: [.font: font]))
        }
        return output
    }
}
