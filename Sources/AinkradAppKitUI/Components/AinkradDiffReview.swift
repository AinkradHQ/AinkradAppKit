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

    private var splitBinding: Binding<Bool> { callerSideBySide ?? $sideBySide }

    public var body: some View {
        VStack(alignment: .leading, spacing: skin.spacing.sm) {
            if showsHeader { header }
            ForEach(fileDiff.hunks) { hunk in hunkBlock(hunk) }
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
                Text("@@ -\(hunk.oldStart),\(hunk.oldCount) +\(hunk.newStart),\(hunk.newCount)")
                    .font(AinkradFontResolver.font(size: 9, mono: true, typography: typography)).foregroundStyle(
                        theme.foreground.opacity(skin.opacity.o40))
                Spacer(minLength: 6)
                if keepUndo {
                    DiffKeepUndoTick(accepted: acceptedBinding(hunk.id))
                } else {
                    AinkradToggleButton(
                        isOn: acceptedBinding(hunk.id),
                        title: AinkradDiffReviewPresentation.hunkControlTitle(accepted: !rejected, keepUndo: false))
                }
            }
            if splitBinding.wrappedValue { splitRows(hunk) } else { unifiedRows(hunk) }
        }
        .opacity(rejected ? skin.opacity.o50 : 1)
        .padding(.horizontal, skin.spacing.sm).padding(.vertical, skin.size.s6)
        .background(skin.shape(cut: AinkradRadius.sm).fill(theme.background.opacity(skin.opacity.o40)))
    }

    @ViewBuilder private func unifiedRows(_ hunk: AinkradDiffHunk) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(hunk.lines.enumerated()), id: \.offset) { _, line in
                let sign = line.kind == .insertion ? "+" : (line.kind == .deletion ? "-" : " ")
                Text(sign + line.text).font(AinkradFontResolver.font(size: 11, mono: true, typography: typography))
                    .foregroundStyle(color(line)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private func splitRows(_ hunk: AinkradDiffHunk) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(AinkradDiffReviewPresentation.sideBySideRows(hunk).enumerated()), id: \.offset) { _, pair in
                HStack(alignment: .top, spacing: skin.spacing.sm) {
                    Text(pair.left?.text ?? "").font(
                        AinkradFontResolver.font(size: 11, mono: true, typography: typography)
                    )
                    .foregroundStyle(pair.left.map(color) ?? theme.foreground.opacity(skin.opacity.o20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(pair.right?.text ?? "").font(
                        AinkradFontResolver.font(size: 11, mono: true, typography: typography)
                    )
                    .foregroundStyle(pair.right.map(color) ?? theme.foreground.opacity(skin.opacity.o20))
                    .frame(maxWidth: .infinity, alignment: .leading)
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
