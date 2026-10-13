import AinkradAppKitContract
import SwiftUI

/// Pure diff→row helpers (no SwiftUI) so the pairing logic is unit-tested.
enum AinkradDiffReviewPresentation {
    /// Pair deletions (left) with insertions (right) for side-by-side rendering.
    /// Context lines mirror on both sides; unmatched del/ins get an empty slot.
    static func sideBySideRows(_ hunk: AinkradDiffHunk) -> [(left: AinkradDiffLine?, right: AinkradDiffLine?)] {
        var rows: [(AinkradDiffLine?, AinkradDiffLine?)] = []
        var pendingDel: [AinkradDiffLine] = []
        var pendingIns: [AinkradDiffLine] = []
        func flush() {
            let n = max(pendingDel.count, pendingIns.count)
            for k in 0..<n {
                rows.append(
                    (
                        k < pendingDel.count ? pendingDel[k] : nil,
                        k < pendingIns.count ? pendingIns[k] : nil
                    ))
            }
            pendingDel.removeAll()
            pendingIns.removeAll()
        }
        for line in hunk.lines {
            switch line.kind {
            case .context:
                flush()
                rows.append((line, line))
            case .deletion: pendingDel.append(line)
            case .insertion: pendingIns.append(line)
            }
        }
        flush()
        return rows
    }

    /// The hunk control's text: the latch's "Accepted"/"Rejected", or the
    /// review mockups' "✓ Keep" / "↶ Undo" under `keepUndoHunkControls()`.
    static func hunkControlTitle(accepted: Bool, keepUndo: Bool) -> String {
        if keepUndo { return accepted ? "✓ Keep" : "↶ Undo" }
        return accepted ? "Accepted" : "Rejected"
    }

    /// The editor-style hunk header: the new file's lines ("@@ lines 18–20"),
    /// or the old file's for a pure removal ("@@ line 24 — removed").
    static func editorHunkTitle(_ hunk: AinkradDiffHunk) -> String {
        let removed = hunk.newCount == 0
        let start = max(removed ? hunk.oldStart : hunk.newStart, 1)
        let count = max(removed ? hunk.oldCount : hunk.newCount, 1)
        let lines = count == 1 ? "line \(start)" : "lines \(start)–\(start + count - 1)"
        return "@@ " + lines + (removed ? " — removed" : "")
    }

    /// Unchanged lines between hunk `index - 1` and hunk `index` (0 for the
    /// first hunk), counted in the original file.
    static func unchangedLinesBefore(_ hunks: [AinkradDiffHunk], at index: Int) -> Int {
        guard index > 0, hunks.indices.contains(index) else { return 0 }
        let previous = hunks[index - 1]
        return max(hunks[index].oldStart - (previous.oldStart + previous.oldCount), 0)
    }

    /// The gutter number for a line: its original number when removed, else
    /// its number in the new file.
    static func gutterNumber(_ line: AinkradDiffLine?) -> String {
        guard let line else { return "" }
        let number = line.kind == .deletion ? line.oldNumber : line.newNumber
        return number.map(String.init) ?? ""
    }
}

/// Rich approval-card diff: a kit latch toggling unified/side-by-side (NO
/// native Picker) and a per-hunk Accept/Reject latch. Rejection is owned by the caller
/// (session state) via a binding so the docked approve button reads the same set.
public struct AinkradDiffReview: View {
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typography
    private let fileDiff: AinkradFileDiff
    @Binding private var rejectedHunkIDs: Set<Int>
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @State private var sideBySide = false
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    // Opt-ins set by the modifier methods below (not init params: a defaulted
    // parameter is not ABI-compatible).
    var showsHeader = true
    var callerSideBySide: Binding<Bool>?
    var keepUndo = false
    var usesEditorLines = false
    var usesSyntaxColours = false
    var usesLineGutter = false
    var usesUnchangedFolds = false

    public init(fileDiff: AinkradFileDiff, rejectedHunkIDs: Binding<Set<Int>>) {
        self.fileDiff = fileDiff
        self._rejectedHunkIDs = rejectedHunkIDs
    }

    /// Drops the file-path + Split header so the caller can show the file in
    /// its own row. Pair with `sideBySide(_:)` to keep Split reachable there,
    /// e.g. `AinkradToggleButton(isOn: $split, title: "Split")`.
    public func hidesHeader() -> Self {
        var copy = self
        copy.showsHeader = false
        return copy
    }

    /// Lets the caller own the unified/side-by-side state (the header's Split
    /// latch, when shown, drives the same binding).
    public func sideBySide(_ isOn: Binding<Bool>) -> Self {
        var copy = self
        copy.callerSideBySide = isOn
        return copy
    }

    /// Per-hunk control as the review mockups' text tick — "✓ Keep" in the
    /// success colour, "↶ Undo" faint — instead of the Accepted/Rejected latch.
    public func keepUndoHunkControls() -> Self {
        var copy = self
        copy.keepUndo = true
        return copy
    }

    /// Draws lines as the review mockups do: each added or removed line gets
    /// a full-width wash (success / danger at 12 %) with the text in the
    /// foreground colour, context lines muted, 11.5 pt mono, and the hunk
    /// header names the lines ("@@ lines 18–20", "@@ line 24 — removed").
    public func editorLines() -> Self {
        var copy = self
        copy.usesEditorLines = true
        return copy
    }

    /// Colours each line's code with the Forge editor's syntax palette
    /// (Neon or Glass), on either line style.
    public func syntaxColoured() -> Self {
        var copy = self
        copy.usesSyntaxColours = true
        return copy
    }

    /// The editor gutter of Forge's replace preview (mockup 08, FP61), on
    /// `editorLines()` rows: a 46 pt right-aligned faint line number (the
    /// original number for a removed line), the 14 pt fold column, then a
    /// 3 pt change bar in the success or danger colour. Replaces the +/- sign.
    public func lineNumberGutter() -> Self {
        var copy = self
        copy.usesLineGutter = true
        return copy
    }

    /// A faint "⋯ N unchanged lines" row between hunks, N counted in the
    /// original file (mockup 08).
    public func unchangedLineFolds() -> Self {
        var copy = self
        copy.usesUnchangedFolds = true
        return copy
    }

    private var splitBinding: Binding<Bool> { callerSideBySide ?? $sideBySide }

    public var body: some View {
        VStack(alignment: .leading, spacing: skin.spacing.sm) {
            if showsHeader { header }
            ForEach(Array(fileDiff.hunks.enumerated()), id: \.element.id) { index, hunk in
                let unchanged = AinkradDiffReviewPresentation.unchangedLinesBefore(fileDiff.hunks, at: index)
                if usesUnchangedFolds, unchanged > 0 { foldRow(unchanged) }
                hunkBlock(hunk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(spacing: skin.spacing.sm) {
            Text(fileDiff.path).font(AinkradFontResolver.font(size: 10, mono: true, typography: typography))
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o55))
                .lineLimit(1).truncationMode(.middle)
            Spacer(minLength: 8)
            AinkradToggleButton(
                isOn: splitBinding.animation(reduceMotion ? nil : AinkradMotion.present), title: "Split")
        }
    }

    @ViewBuilder
    private func hunkBlock(_ hunk: AinkradDiffHunk) -> some View {
        let rejected = rejectedHunkIDs.contains(hunk.id)
        VStack(alignment: .leading, spacing: skin.size.s3) {
            HStack(spacing: skin.size.s6) {
                hunkTitle(hunk)
                Spacer(minLength: 6)
                if keepUndo {
                    DiffKeepUndoTick(accepted: acceptedBinding(hunk.id))
                } else {
                    AinkradToggleButton(
                        isOn: acceptedBinding(hunk.id),
                        title: AinkradDiffReviewPresentation.hunkControlTitle(accepted: !rejected, keepUndo: false))
                }
            }
            .padding(.horizontal, usesEditorLines ? skin.size.s10 : 0)
            if splitBinding.wrappedValue { splitRows(hunk) } else { unifiedRows(hunk) }
        }
        .opacity(rejected ? (usesEditorLines ? skin.opacity.o55 : skin.opacity.o50) : 1)
        .padding(.horizontal, usesEditorLines ? 0 : skin.spacing.sm).padding(.vertical, skin.size.s6)
        .background { hunkBackground }
    }

    @ViewBuilder private var hunkBackground: some View {
        if usesEditorLines {
            RoundedRectangle(cornerRadius: skin.size.s8).fill(skin.color(skin.palette.black).opacity(skin.opacity.o18))
        } else {
            skin.shape(cut: AinkradRadius.sm).fill(theme.background.opacity(skin.opacity.o40))
        }
    }

    @ViewBuilder private func hunkTitle(_ hunk: AinkradDiffHunk) -> some View {
        if usesEditorLines {
            Text(AinkradDiffReviewPresentation.editorHunkTitle(hunk))
                .font(AinkradFontResolver.font(size: 10.5, mono: true, typography: typography))
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o35))
        } else {
            Text("@@ -\(hunk.oldStart),\(hunk.oldCount) +\(hunk.newStart),\(hunk.newCount)")
                .font(AinkradFontResolver.font(size: 9, mono: true, typography: typography)).foregroundStyle(
                    theme.foreground.opacity(skin.opacity.o40))
        }
    }

    /// One line's text: the code, syntax-coloured when asked.
    private func lineText(_ text: String) -> Text {
        usesSyntaxColours
            ? Text(ainkradSyntaxAttributed(text, palette: .forge(glass: skin.usesNativeGlass))) : Text(text)
    }

    /// A line under `editorLines()`: full-width wash, foreground text, and
    /// under `lineNumberGutter()` the number, fold column and change bar.
    private func editorLine(_ line: AinkradDiffLine?, sign: Bool) -> some View {
        let showsSign = sign && !usesLineGutter
        let prefix = showsSign ? (line?.kind == .insertion ? "+" : (line?.kind == .deletion ? "-" : " ")) : ""
        return HStack(spacing: 0) {
            if usesLineGutter { gutter(AinkradDiffReviewPresentation.gutterNumber(line)) }
            lineText(prefix + (line?.text ?? ""))
                .foregroundStyle(
                    line?.kind == .context || line == nil
                        ? theme.foreground.opacity(skin.opacity.o55) : theme.foreground
                )
                .textSelection(.enabled)
        }
        .font(AinkradFontResolver.font(size: 11.5, mono: true, typography: typography))
        .padding(.horizontal, usesLineGutter ? 0 : skin.size.s10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .leading) {
            if usesLineGutter, let bar = changeBar(line) {
                Rectangle().fill(bar).frame(width: skin.size.s3).padding(.leading, gutterNumberWidth)
            }
        }
        .background(wash(line))
    }

    /// Number column (46) + its 10 pt gap + the 14 pt fold column.
    private var gutterNumberWidth: CGFloat { skin.size.s46 + skin.size.s10 + skin.size.s14 }

    /// Number, fold column, then room for the 3 pt bar and its 10 pt gap.
    private func gutter(_ number: String) -> some View {
        Text(number)
            .foregroundStyle(theme.foreground.opacity(skin.opacity.o35))
            .frame(width: skin.size.s46, alignment: .trailing)
            .padding(.trailing, skin.size.s10 + skin.size.s14 + skin.size.s3 + skin.size.s10)
    }

    private func changeBar(_ line: AinkradDiffLine?) -> Color? {
        switch line?.kind {
        case .insertion: statusColors.success
        case .deletion: statusColors.danger
        default: nil
        }
    }

    /// "⋯ N unchanged lines", faint, with "…" in the gutter when it shows.
    private func foldRow(_ count: Int) -> some View {
        HStack(spacing: 0) {
            if usesLineGutter { gutter("…") }
            Text("⋯ \(count) unchanged line\(count == 1 ? "" : "s")")
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o35))
        }
        .font(AinkradFontResolver.font(size: usesEditorLines ? 11.5 : 11, mono: true, typography: typography))
        .padding(.horizontal, usesLineGutter ? 0 : skin.size.s10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func wash(_ line: AinkradDiffLine?) -> Color {
        switch line?.kind {
        case .insertion: statusColors.success.opacity(skin.opacity.o12)
        case .deletion: statusColors.danger.opacity(skin.opacity.o12)
        default: .clear
        }
    }

    @ViewBuilder private func unifiedRows(_ hunk: AinkradDiffHunk) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(hunk.lines.enumerated()), id: \.offset) { _, line in
                if usesEditorLines {
                    editorLine(line, sign: true)
                } else {
                    let sign = line.kind == .insertion ? "+" : (line.kind == .deletion ? "-" : " ")
                    lineText(sign + line.text)
                        .font(AinkradFontResolver.font(size: 11, mono: true, typography: typography))
                        .foregroundStyle(color(line)).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    @ViewBuilder private func splitRows(_ hunk: AinkradDiffHunk) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(AinkradDiffReviewPresentation.sideBySideRows(hunk).enumerated()), id: \.offset) { _, pair in
                if usesEditorLines {
                    HStack(alignment: .top, spacing: 0) {
                        editorLine(pair.left, sign: false)
                        editorLine(pair.right, sign: false)
                    }
                } else {
                    HStack(alignment: .top, spacing: skin.spacing.sm) {
                        lineText(pair.left?.text ?? "").font(
                            AinkradFontResolver.font(size: 11, mono: true, typography: typography)
                        )
                        .foregroundStyle(pair.left.map(color) ?? theme.foreground.opacity(skin.opacity.o20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        lineText(pair.right?.text ?? "").font(
                            AinkradFontResolver.font(size: 11, mono: true, typography: typography)
                        )
                        .foregroundStyle(pair.right.map(color) ?? theme.foreground.opacity(skin.opacity.o20))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    /// A hunk is accepted unless the caller's set rejects it; the latch is lit
    /// while accepted.
    private func acceptedBinding(_ id: Int) -> Binding<Bool> {
        Binding(
            get: { !rejectedHunkIDs.contains(id) },
            set: { accepted in
                if accepted { rejectedHunkIDs.remove(id) } else { rejectedHunkIDs.insert(id) }
            })
    }

    private func color(_ line: AinkradDiffLine) -> Color {
        switch line.kind {
        case .insertion: return statusColors.success
        case .deletion: return statusColors.danger
        case .context: return theme.foreground.opacity(skin.opacity.o60)
        }
    }
}

/// The mockups' hunk tick: plain text, no capsule. Success-coloured while kept,
/// faint (brightening on hover) once the change is marked for undo.
private struct DiffKeepUndoTick: View {
    @Binding var accepted: Bool
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typography
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var statusColors
    @Environment(\.ainkradReduceMotion) private var reduceMotion
    @State private var hovering = false

    var body: some View {
        Button {
            accepted.toggle()
        } label: {
            Text(AinkradDiffReviewPresentation.hunkControlTitle(accepted: accepted, keepUndo: true))
                .font(AinkradFontResolver.font(size: 11, mono: false, typography: typography))
                .foregroundStyle(
                    accepted
                        ? statusColors.success.opacity(hovering ? skin.opacity.o80 : 1)
                        : theme.foreground.opacity(hovering ? skin.opacity.o70 : skin.opacity.o40)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(reduceMotion ? nil : AinkradMotion.hover, value: hovering)
        .accessibilityLabel(accepted ? "Keep change" : "Undo change")
        .accessibilityAddTraits(accepted ? .isSelected : [])
    }
}
