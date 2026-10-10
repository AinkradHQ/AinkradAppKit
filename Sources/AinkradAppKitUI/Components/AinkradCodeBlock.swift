import AinkradAppKitContract
import AppKit
import SwiftUI

/// Mono chamfer panel for a block of code — optional language caption,
/// horizontal scroll for long lines, and a copy-to-pasteboard button
/// (`AinkradIconButton`, never a native control).
public struct AinkradCodeBlock: View {
    private let code: String
    private let language: String?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var copied = false

    public init(_ code: String, language: String? = nil) {
        self.code = code
        self.language = language
    }

    /// Mirrors the transient "just copied" indicator state — exposed for testing.
    public var didJustCopy: Bool { copied }

    public var body: some View {
        let block = skin.components.codeBlock
        VStack(alignment: .leading, spacing: AinkradSpacing.sm) {
            HStack {
                if let language {
                    Text(skin.labelCased(language))
                        .font(AinkradFontResolver.font(.caption, weight: .semibold, typography: typo))
                        .tracking(block.headerFont.tracking ?? 0)
                        .foregroundStyle(skin.color(block.headerColor))
                }
                Spacer(minLength: AinkradSpacing.sm)
                AinkradIconButton(systemName: copied ? "checkmark" : "doc.on.doc", action: copyToPasteboard)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(AinkradFontResolver.font(.mono, typography: typo))
                    .foregroundStyle(skin.color(block.codeColor))
                    .textSelection(.enabled)
            }
        }
        .padding(AinkradSpacing.md)
        .background(AinkradSkinShape(token: block.shape).fill(skin.color(block.fill)))
        .overlay(
            AinkradSkinShape(token: block.shape)
                .strokeBorder(skin.color(block.stroke.color), lineWidth: block.stroke.width.resolve([])))
    }

    private func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
    }
}
