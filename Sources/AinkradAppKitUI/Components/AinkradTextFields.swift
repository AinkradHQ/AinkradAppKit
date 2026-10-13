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
        if #available(macOS 26, *), skin.usesNativeGlass {
            nativeBody
        } else {
            kitBody
        }
    }

    /// Glass on macOS 26+: Apple's rounded field, the reveal eye inside it.
    @available(macOS 26, *)
    private var nativeBody: some View {
        Group {
            if isRevealed {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }
        }
        .textFieldStyle(.roundedBorder)
        .controlSize(.large)
        .overlay(alignment: .trailing) {
            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
            }
            .buttonStyle(.borderless)
            .padding(.trailing, AinkradSpacing.sm)
            .help(isRevealed ? "Hide" : "Show")
        }
    }

    private var kitBody: some View {
        let field = skin.roles.field
        let secure = skin.components.secureField
        let shape = AinkradSkinShape(token: field.shape)
        return HStack(spacing: AinkradSpacing.sm) {
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

/// The part of a file name a rename should select: everything before the
/// last `.`, as a UTF-16 range for the field editor. A name with no extension,
/// or a dotfile (`.gitignore`), selects whole.
public func ainkradBaseNameRange(_ name: String) -> NSRange {
    let whole = NSRange(location: 0, length: (name as NSString).length)
    guard let dot = name.lastIndex(of: "."), dot != name.startIndex else { return whole }
    return NSRange(location: 0, length: name.utf16.distance(from: name.utf16.startIndex, to: dot))
}

/// Plain-text entry mirroring `AinkradSecureField`'s chamfer chrome, minus the
/// reveal toggle and mono font.
public struct AinkradTextField: View {
    @Binding private var text: String
    private let placeholder: String
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTypography) private var typo
    @FocusState private var isFocused: Bool
    /// Set by `selectsNameWithoutExtension()`.
    var selectsBaseName = false

    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
    }

    /// On focus, selects the name without its extension (`SidebarRow` of
    /// `SidebarRow.swift`) instead of the whole text, so typing replaces just
    /// the name — a Finder-style rename (Forge's file tree).
    public func selectsNameWithoutExtension() -> Self {
        var copy = self
        copy.selectsBaseName = true
        return copy
    }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple's rounded text field.
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .controlSize(.large)
                .apply { selectsBaseName ? AnyView($0.focused($isFocused)) : AnyView($0) }
                .modifier(BaseNameSelection(enabled: selectsBaseName, isFocused: isFocused, text: text))
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let field = skin.roles.field
        let tokens = skin.components.textField
        let shape = AinkradSkinShape(token: field.shape)
        return TextField(placeholder, text: $text)
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
            .modifier(BaseNameSelection(enabled: selectsBaseName, isFocused: isFocused, text: text))
    }

    private var state: AinkradControlState {
        isFocused ? [.focused] : []
    }
}

/// `selectsNameWithoutExtension()`: once the field gains focus — and the field
/// editor has selected everything, a turn later — narrows the selection to the
/// base name. The field editor is found through the key window, or any window
/// whose first responder is editing this text.
private struct BaseNameSelection: ViewModifier {
    let enabled: Bool
    let isFocused: Bool
    let text: String

    func body(content: Content) -> some View {
        if enabled {
            content.onChange(of: isFocused) { _, focused in
                guard focused else { return }
                let text = text
                DispatchQueue.main.async { Self.select(ainkradBaseNameRange(text), in: text) }
            }
        } else {
            content
        }
    }

    @MainActor static func select(_ range: NSRange, in text: String) {
        let windows = [NSApp.keyWindow].compactMap { $0 } + NSApp.windows
        for window in windows {
            if let editor = window.firstResponder as? NSTextView, editor.isFieldEditor, editor.string == text {
                editor.setSelectedRange(range)
                return
            }
        }
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
        if #available(macOS 26, *), skin.usesNativeGlass {
            nativeBody
        } else {
            kitBody
        }
    }

    /// Glass on macOS 26+: the system search look — a glass capsule with the
    /// magnifier and a clear button (SwiftUI has no standalone search field
    /// outside a toolbar's `.searchable`).
    @available(macOS 26, *)
    private var nativeBody: some View {
        HStack(spacing: AinkradSpacing.xs) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            nativeTextField
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Clear")
            }
        }
        .padding(.horizontal, AinkradSpacing.md)
        .padding(.vertical, AinkradSpacing.sm)
        .glassEffect(.regular, in: .capsule)
    }

    @ViewBuilder private var nativeTextField: some View {
        let base = TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .onSubmit { onSubmit?() }
        if let externalFocus {
            base.focused(externalFocus)
        } else {
            base.focused($internalFocus)
        }
    }

    private var kitBody: some View {
        let field = skin.roles.field
        let search = skin.components.searchField
        let shape = AinkradSkinShape(token: field.shape)
        return HStack(spacing: AinkradSpacing.sm) {
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
