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
    @FocusState private var internalFocus: Bool
    /// Set by `init(text:placeholder:focus:)`; `nil` keeps `internalFocus`.
    var externalFocus: FocusState<Bool>.Binding?
    /// Set by `selectsNameWithoutExtension()`.
    var selectsBaseName = false
    /// Set by `leadingLabel(_:)`.
    var label: String?
    /// Set by `compact()`.
    var isCompact = false
    /// Set by `fieldHeight(_:)`.
    var fieldHeight: CGFloat?
    /// Set by `chamfered()`.
    var isChamfered = false
    /// Set by `monospaced()`.
    var isMonospaced = false
    /// Set by `onReturn(_:)`.
    var returnAction: ((EventModifiers) -> Void)?
    @Environment(\.ainkradTheme) private var theme

    public init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
    }

    /// Focus driven by the caller — e.g. set `focus` to `true` when a sheet
    /// or popover opens so the field takes typing at once (Forge's rename,
    /// new-file and go-to-line fields), as `AinkradSearchField(focus:)` does.
    /// A separate overload: the two-argument init is unchanged.
    public init(text: Binding<String>, placeholder: String, focus: FocusState<Bool>.Binding) {
        self.init(text: text, placeholder: placeholder)
        self.externalFocus = focus
    }

    private var isFocused: Bool { externalFocus?.wrappedValue ?? internalFocus }

    /// Binds the inner `TextField` to the caller's focus, or the field's own.
    @ViewBuilder private func focusBound(_ field: some View) -> some View {
        if let externalFocus { field.focused(externalFocus) } else { field.focused($internalFocus) }
    }

    /// On focus, selects the name without its extension (`SidebarRow` of
    /// `SidebarRow.swift`) instead of the whole text, so typing replaces just
    /// the name — a Finder-style rename (Forge's file tree).
    public func selectsNameWithoutExtension() -> Self {
        var copy = self
        copy.selectsBaseName = true
        return copy
    }

    /// A small faint label inside the field, before the text (`include`,
    /// `exclude`), that stays while the field has text — unlike a placeholder.
    /// Forge's search globs. Under Glass the field becomes a glass capsule
    /// holding the label, as Apple's rounded field has no room for one.
    public func leadingLabel(_ label: String) -> Self {
        var copy = self
        copy.label = label
        return copy
    }

    /// The mockup's small field (`.sfield.small`, Forge's include / exclude
    /// globs, FP56): tighter padding and 12 pt mono text. Under Glass a slim
    /// glass capsule.
    public func compact() -> Self {
        var copy = self
        copy.isCompact = true
        return copy
    }

    /// Draws the field exactly `height` points tall, its text centred,
    /// instead of padding it — Forge's rename and go-to-line fields at the
    /// mockups' 28 (`.sfield`, mockups 07 and 11; the default is 33). Under
    /// Glass the field becomes a glass capsule of that height.
    public func fieldHeight(_ height: CGFloat) -> Self {
        var copy = self
        copy.fieldHeight = height
        return copy
    }

    /// The mockups' `.sfield.cut` under Neon: an 8 pt chamfer on the top-left
    /// and bottom-right corners, a 1 pt cyan rim (secondary accent, 45 %) and
    /// the strong elevated fill, with the usual focus ring once focused.
    /// Glass keeps its rounded field.
    public func chamfered() -> Self {
        var copy = self
        copy.isChamfered = true
        return copy
    }

    /// The text in 12 pt mono, as the mockups' `.sfield .q` — Forge's rename
    /// field (mockup 11). Neon and Glass; the field keeps its size and padding
    /// (`compact()` already implies it).
    public func monospaced() -> Self {
        var copy = self
        copy.isMonospaced = true
        return copy
    }

    /// Calls `action` with the held modifiers when Return is pressed in the
    /// field, and takes the key — so a caller can tell ↵ from ⇧↵ (Forge's
    /// rename: ↵ previews, ⇧↵ renames now). Without it Return still ends
    /// editing and fires the caller's `onSubmit`. Neon and Glass.
    public func onReturn(_ action: @escaping (EventModifiers) -> Void) -> Self {
        var copy = self
        copy.returnAction = action
        return copy
    }

    /// Whether the text is in `compactFont`: `compact()` or `monospaced()`.
    private var usesMonoFont: Bool { isCompact || isMonospaced }

    /// The text font under `compact()` or `monospaced()`: 12 pt mono.
    private var compactFont: Font { AinkradFontResolver.font(size: 12, mono: true, typography: typo) }

    @ViewBuilder private var labelView: some View {
        if let label {
            Text(label)
                .font(AinkradFontResolver.font(size: 10, typography: typo))
                .foregroundStyle(theme.foreground.opacity(skin.opacity.o35))
                .lineLimit(1)
                .frame(width: skin.size.s46, alignment: .leading)
        }
    }

    public var body: some View {
        if #available(macOS 26, *), skin.usesNativeGlass, label != nil || isCompact || fieldHeight != nil {
            HStack(spacing: AinkradSpacing.xs) {
                labelView
                focusBound(
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .apply { field in
                            if usesMonoFont { field.font(compactFont) } else { field }
                        }
                        .modifier(ReturnKey(action: returnAction)))
            }
            .padding(.horizontal, isCompact ? skin.size.s10 : AinkradSpacing.md)
            .modifier(FieldHeight(height: fieldHeight, padding: isCompact ? skin.size.s4 : AinkradSpacing.sm))
            .glassEffect(.regular, in: .capsule)
            .modifier(BaseNameSelection(enabled: selectsBaseName, isFocused: isFocused, text: text))
        } else if #available(macOS 26, *), skin.usesNativeGlass {
            // Glass on macOS 26+: Apple's rounded text field.
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .controlSize(.large)
                .apply { field in
                    if isMonospaced { field.font(compactFont) } else { field }
                }
                .modifier(ReturnKey(action: returnAction))
                .apply {
                    selectsBaseName || externalFocus != nil ? AnyView(focusBound($0)) : AnyView($0)
                }
                .modifier(BaseNameSelection(enabled: selectsBaseName, isFocused: isFocused, text: text))
        } else {
            kitBody
        }
    }

    private var kitBody: some View {
        let tokens = skin.components.textField
        let chrome = FieldChrome(skin: skin, chamfered: isChamfered, state: state)
        return HStack(spacing: AinkradSpacing.xs) {
            labelView
            focusBound(TextField(placeholder, text: $text).modifier(ReturnKey(action: returnAction)))
                .textFieldStyle(.plain)
                .font(usesMonoFont ? compactFont : skin.font(tokens.font, typography: typo))
                .foregroundStyle(skin.color(skin.text.primary))
                .tint(skin.color(skin.palette.accentSecondary))
        }
        .padding(.horizontal, isCompact ? skin.size.s8 : AinkradSpacing.md)
        .modifier(FieldHeight(height: fieldHeight, padding: isCompact ? skin.size.s4 : AinkradSpacing.sm))
        .modifier(chrome)
        .animation(AinkradMotion.hover, value: isFocused)
        .modifier(BaseNameSelection(enabled: selectsBaseName, isFocused: isFocused, text: text))
    }

    private var state: AinkradControlState {
        isFocused ? [.focused] : []
    }
}

/// `onReturn(_:)`: Return, with its modifiers, goes to `action`; without
/// one the field is left as it was.
private struct ReturnKey: ViewModifier {
    let action: ((EventModifiers) -> Void)?

    func body(content: Content) -> some View {
        if let action {
            content.onKeyPress(.return, phases: .down) { press in
                action(press.modifiers)
                return .handled
            }
        } else {
            content
        }
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
    /// Set by `keyHint(_:)`.
    var keyHint: String?
    /// Set by `trailingAccessory(_:)`.
    var accessory: AnyView?
    /// Set by `codeQuery()`.
    var isCodeQuery = false
    /// Set by `fieldHeight(_:)`.
    var fieldHeight: CGFloat?
    /// Set by `chamfered()`.
    var isChamfered = false

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

    /// An outlined keycap at the field's trailing edge naming the shortcut that
    /// focuses it (`"⌘K"`), shown while the field is empty — the clear button
    /// takes its place once there is text. Grimoire's thread search.
    public func keyHint(_ keys: String) -> Self {
        var copy = self
        copy.keyHint = keys
        return copy
    }

    /// Controls inside the field at its trailing edge — Forge's `Aa` / `⌶` /
    /// `✱` search toggles, or `AB` and Replace All on the replace field
    /// (FP54, FP62).
    public func trailingAccessory<Accessory: View>(@ViewBuilder _ accessory: () -> Accessory) -> Self {
        var copy = self
        copy.accessory = AnyView(accessory())
        return copy
    }

    /// A code query, as Forge's sidebar search field (`.sfield`): mono text,
    /// no magnifier and no clear button.
    public func codeQuery() -> Self {
        var copy = self
        copy.isCodeQuery = true
        return copy
    }

    /// Draws the field exactly `height` points tall, its content centred,
    /// instead of padding it — Forge's sidebar search and replace fields at
    /// the mockups' 28 (`.sfield`, mockup 07; the default is 33). Neon and
    /// Glass.
    public func fieldHeight(_ height: CGFloat) -> Self {
        var copy = self
        copy.fieldHeight = height
        return copy
    }

    /// The mockups' `.sfield.cut` under Neon: an 8 pt chamfer on the top-left
    /// and bottom-right corners, a 1 pt cyan rim (secondary accent, 45 %) and
    /// the strong elevated fill, with the usual focus ring once focused.
    /// Glass keeps its capsule.
    public func chamfered() -> Self {
        var copy = self
        copy.isChamfered = true
        return copy
    }

    /// The query font under `codeQuery()`: 12 pt mono.
    private var codeFont: Font { AinkradFontResolver.font(size: 12, mono: true, typography: typo) }

    @ViewBuilder private var keyHintCap: some View {
        if let keyHint, text.isEmpty {
            AinkradKbd(keyHint).outlined()
        }
    }

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
            if !isCodeQuery { Image(systemName: "magnifyingglass").foregroundStyle(.secondary) }
            nativeTextField
            keyHintCap
            if !text.isEmpty, !isCodeQuery {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Clear")
            }
            accessory
        }
        .padding(.horizontal, AinkradSpacing.md)
        .modifier(FieldHeight(height: fieldHeight, padding: AinkradSpacing.sm))
        .glassEffect(.regular, in: .capsule)
    }

    @ViewBuilder private var nativeTextField: some View {
        let base = TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .apply { field in
                if isCodeQuery { field.font(codeFont) } else { field }
            }
            .onSubmit { onSubmit?() }
        if let externalFocus {
            base.focused(externalFocus)
        } else {
            base.focused($internalFocus)
        }
    }

    private var kitBody: some View {
        let search = skin.components.searchField
        return HStack(spacing: AinkradSpacing.sm) {
            if !isCodeQuery {
                Image(systemName: "magnifyingglass")
                    .font(skin.font(search.searchGlyphFont, typography: typo))
                    .foregroundStyle(skin.color(search.searchGlyphColor, state: state))
            }

            textField

            keyHintCap

            if !text.isEmpty, !isCodeQuery {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(skin.font(search.clearGlyphFont, typography: typo))
                        .foregroundStyle(skin.color(search.clearGlyphColor))
                }
                .buttonStyle(.plain)
            }

            accessory
        }
        .padding(.horizontal, AinkradSpacing.md)
        .modifier(FieldHeight(height: fieldHeight, padding: AinkradSpacing.sm))
        .modifier(FieldChrome(skin: skin, chamfered: isChamfered, state: state))
        .animation(AinkradMotion.hover, value: isFocused)
    }

    private var state: AinkradControlState {
        isFocused ? [.focused] : []
    }

    @ViewBuilder
    private var textField: some View {
        let base = TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .font(isCodeQuery ? codeFont : skin.font(skin.components.searchField.font, typography: typo))
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
