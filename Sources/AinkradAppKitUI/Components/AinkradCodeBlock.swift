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
    @Environment(\.ainkradTheme) private var theme
    @State private var copied = false
    @State private var hovering = false
    /// Set by `AinkradMarkdownText.replyStyle()`.
    var usesReplyStyle = false

    public init(_ code: String, language: String? = nil) {
        self.code = code
        self.language = language
    }

    /// Mirrors the transient "just copied" indicator state — exposed for testing.
    public var didJustCopy: Bool { copied }

    public var body: some View {
        if usesReplyStyle { replyBody } else { kitBody }
    }

    /// Grimoire's reply code block (`.md .code`): one quiet fill, no rim, a
    /// small language label with a text "Copy" that shows on hover, and the
    /// code syntax-coloured in 11.5 pt mono. Square under Neon, 12 pt
    /// corners under Glass.
    private var replyBody: some View {
        let fill =
            skin.usesNativeGlass
            ? skin.color(skin.palette.white).opacity(skin.opacity.o06) : theme.surfaceElevated.opacity(skin.opacity.o60)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(skin.labelCased(language ?? ""))
                    .font(AinkradFontResolver.font(size: 10, typography: typo))
                    .tracking(skin.usesNativeGlass ? 0 : 0.8)
                    .foregroundStyle(theme.foreground.opacity(skin.opacity.o35))
                Spacer(minLength: AinkradSpacing.sm)
                Button(action: copyToPasteboard) {
                    Text(copied ? "Copied" : "Copy")
                        .font(AinkradFontResolver.font(size: 10, typography: typo))
                        .foregroundStyle(theme.foreground.opacity(skin.opacity.o55))
                }
                .buttonStyle(.plain)
                .opacity(hovering || copied ? 1 : 0)
                .accessibilityLabel("Copy code")
            }
            .padding(.horizontal, skin.size.s10)
            .padding(.vertical, skin.size.s5)
            ScrollView(.horizontal, showsIndicators: false) {
                Text(ainkradSyntaxAttributed(lines: code, palette: .reply))
                    .font(AinkradFontResolver.font(size: 11.5, mono: true, typography: typo))
                    .foregroundStyle(theme.foreground)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, skin.size.s12)
            .padding(.bottom, skin.size.s10)
        }
        .background(RoundedRectangle(cornerRadius: skin.usesNativeGlass ? skin.size.s12 : 0).fill(fill))
        .onHover { hovering = $0 }
        .animation(AinkradMotion.hover, value: hovering)
    }

    private var kitBody: some View {
        let block = skin.components.codeBlock
        return VStack(alignment: .leading, spacing: AinkradSpacing.sm) {
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
