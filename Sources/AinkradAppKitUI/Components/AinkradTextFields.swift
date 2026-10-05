import AinkradAppKitContract
import AppKit
import SwiftUI

/// Masked entry with a reveal (eye) toggle — chamfer field + luminous focus
/// ring, no separator lines. Ported from the host's `NeonSecureField`; never
/// logs or otherwise surfaces the value beyond this field.
public struct AinkradSecureField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
    }
    public var body: some View {
        let field = skin.roles.field
        let secure = skin.components.secureField
        let shape = AinkradSkinShape(token: field.shape)
        HStack(spacing: AinkradSpacing.sm) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(skin.font(secure.font, typography: typo))
            .foregroundStyle(skin.color(skin.text.primary))
            .tint(skin.color(skin.palette.accentSecondary))

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(skin.font(secure.leadingGlyphFont, typography: typo))
                    .foregroundStyle(skin.color(secure.leadingGlyphColor))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(shape.fill(skin.color(field.fill)))
        .overlay(
            shape.strokeBorder(
                skin.color(field.stroke.color, state: state), lineWidth: field.stroke.width.resolve(state))
        )
        .shadow(color: skin.color(field.glow.color, state: state), radius: field.glow.radius.resolve(state))
        .animation(AinkradMotion.hover, value: isFocused)
    }

    private var state: AinkradControlState {
        isFocused ? [.focused] : []
    }
}

/// Plain-text entry mirroring `AinkradSecureField`'s chamfer chrome, minus the
/// reveal toggle and mono font.
public struct AinkradTextField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
    }
    public var body: some View {
        let field = skin.roles.field
        let tokens = skin.components.textField
        let shape = AinkradSkinShape(token: field.shape)
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(skin.font(tokens.font, typography: typo))
            .foregroundStyle(skin.color(skin.text.primary))
            .tint(skin.color(skin.palette.accentSecondary))
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(shape.fill(skin.color(field.fill)))
            .overlay(
                shape.strokeBorder(
                    skin.color(field.stroke.color, state: state), lineWidth: field.stroke.width.resolve(state))
            )
            .shadow(color: skin.color(field.glow.color, state: state), radius: field.glow.radius.resolve(state))
            .animation(AinkradMotion.hover, value: isFocused)
    }

    private var state: AinkradControlState {
        isFocused ? [.focused] : []
    }
}

/// Chamfer field with a leading magnifier glyph and a custom clear (✕)
/// affordance — never a native search field.
public struct AinkradSearchField: View {
    @Binding private var text: String
    private let placeholder: String
    private let onSubmit: (() -> Void)?
    /// Lets a caller drive focus from outside (e.g. a ⌘F shortcut owned by a
    /// parent view). `nil` (the default) keeps the field's own internal
    /// `@FocusState` — every existing call site is unaffected.
    private let externalFocus: FocusState<Bool>.Binding?

    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var internalFocus: Bool

    public init(
        text: Binding<String>, placeholder: String, onSubmit: (() -> Void)? = nil,
        focus: FocusState<Bool>.Binding? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSubmit = onSubmit
        self.externalFocus = focus
    }

    private var isFocused: Bool { externalFocus?.wrappedValue ?? internalFocus }

    public var body: some View {
        let field = skin.roles.field
        let search = skin.components.searchField
        let shape = AinkradSkinShape(token: field.shape)
        HStack(spacing: AinkradSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(skin.font(search.searchGlyphFont, typography: typo))
                .foregroundStyle(skin.color(search.searchGlyphColor, state: state))

            textField

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(skin.font(search.clearGlyphFont, typography: typo))
                        .foregroundStyle(skin.color(search.clearGlyphColor))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(shape.fill(skin.color(field.fill)))
        .overlay(
            shape.strokeBorder(
                skin.color(field.stroke.color, state: state), lineWidth: field.stroke.width.resolve(state))
        )
        .shadow(color: skin.color(field.glow.color, state: state), radius: field.glow.radius.resolve(state))
        .animation(AinkradMotion.hover, value: isFocused)
    }

    private var state: AinkradControlState {
        isFocused ? [.focused] : []
    }

    @ViewBuilder
    private var textField: some View {
        let base = TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(skin.font(skin.components.searchField.font, typography: typo))
            .foregroundStyle(skin.color(skin.text.primary))
            .tint(skin.color(skin.palette.accentSecondary))
            .onSubmit { onSubmit?() }

        if let externalFocus {
            base.focused(externalFocus)
        } else {
            base.focused($internalFocus)
        }
    }
}
