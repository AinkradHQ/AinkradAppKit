import AinkradAppKitContract
import AppKit
import SwiftUI

/// Masked entry with a reveal (eye) toggle — chamfer field + luminous focus
/// ring, no separator lines. Ported from the host's `NeonSecureField`; never
/// logs or otherwise surfaces the value beyond this field.
public struct AinkradSecureField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
    }
    public var body: some View {
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
            .font(AinkradFontResolver.font(.mono, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.foreground.opacity(0.55))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(
            ChamferShape(cut: 6).strokeBorder(
                theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25)
        )
        .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
        .animation(AinkradMotion.hover, value: isFocused)
    }
}

/// Plain-text entry mirroring `AinkradSecureField`'s chamfer chrome, minus the
/// reveal toggle and mono font.
public struct AinkradTextField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
    }
    public var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .padding(.horizontal, AinkradSpacing.md)
            .padding(.vertical, AinkradSpacing.sm)
            .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
            .overlay(
                ChamferShape(cut: 6).strokeBorder(
                    theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25)
            )
            .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
            .animation(AinkradMotion.hover, value: isFocused)
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

    @Environment(\.ainkradTheme) private var theme
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
        HStack(spacing: AinkradSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(theme.accentSecondary.opacity(isFocused ? 0.95 : 0.55))

            textField

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.foreground.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .background(ChamferShape(cut: 6).fill(theme.surfaceElevated.opacity(0.5)))
        .overlay(
            ChamferShape(cut: 6).strokeBorder(
                theme.accentPrimary.opacity(isFocused ? 0.9 : 0.25), lineWidth: isFocused ? 1.5 : 1.25)
        )
        .shadow(color: theme.accentSecondary.opacity(isFocused ? 0.45 : 0), radius: isFocused ? 6 : 0)
        .animation(AinkradMotion.hover, value: isFocused)
    }

    @ViewBuilder
    private var textField: some View {
        let base = TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(AinkradFontResolver.font(.body, typography: typo))
            .foregroundStyle(theme.foreground)
            .tint(theme.accentSecondary)
            .onSubmit { onSubmit?() }

        if let externalFocus {
            base.focused(externalFocus)
        } else {
            base.focused($internalFocus)
        }
    }
}
