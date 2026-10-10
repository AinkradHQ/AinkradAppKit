import Foundation

/// What the composer's draft is in the middle of typing: a leading `/command`
/// or a trailing `@mention`. Derived from the draft text alone — the text area
/// exposes no cursor position — so the mention token is assumed to be at the
/// end of the draft, which is where chat typing happens.
public enum AinkradComposerTrigger: Equatable, Sendable {
    case command(query: String)
    case mention(query: String)

    /// The trigger for `text`, if any. A command wins over a mention (they
    /// cannot overlap in practice: a command is a leading token with no space).
    public static func detect(in text: String) -> AinkradComposerTrigger? {
        if let query = commandQuery(in: text) { return .command(query: query) }
        if let query = mentionQuery(in: text) { return .mention(query: query) }
        return nil
    }

    /// The query while `text` is a LEADING `/` command still being typed — no
    /// space or newline yet. `nil` once a space follows (the user is typing args).
    static func commandQuery(in text: String) -> String? {
        guard text.hasPrefix("/"), !text.contains(" "), !text.contains("\n") else { return nil }
        return String(text.dropFirst())
    }

    /// The query while the TRAILING whitespace-delimited token starts with `@`.
    static func mentionQuery(in text: String) -> String? {
        let token = trailingToken(of: text)
        guard token.hasPrefix("@") else { return nil }
        return String(token.dropFirst())
    }

    static func trailingToken(of text: String) -> String {
        guard let index = text.lastIndex(where: { $0.isWhitespace }) else { return text }
        return String(text[text.index(after: index)...])
    }

    /// `text` after picking `suggestion`: a command replaces the whole draft, a
    /// mention replaces only the trailing `@query` token. Both end in a space so
    /// the user keeps typing.
    public func applying(_ suggestion: AinkradComposerSuggestion, to text: String) -> String {
        switch self {
        case .command:
            return suggestion.insertText + " "
        case .mention:
            guard let index = text.lastIndex(where: { $0.isWhitespace }) else { return suggestion.insertText + " " }
            return String(text[...index]) + suggestion.insertText + " "
        }
    }
}

/// One row in the composer's `/` or `@` overlay. `insertText` is what picking
/// it writes into the draft (`/name`, `@path`); `section` groups consecutive
/// rows under a header, in the order given.
public struct AinkradComposerSuggestion: Identifiable, Equatable, Sendable {
    public let id: String
    public let icon: String
    public let title: String
    public let subtitle: String?
    public let section: String?
    public let insertText: String

    public init(
        id: String, icon: String, title: String, subtitle: String? = nil, section: String? = nil,
        insertText: String
    ) {
        self.id = id
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.section = section
        self.insertText = insertText
    }
}

/// Keys the open overlay swallows: Up (126), Down (125), Return (36) and
/// keypad Enter (76). Esc belongs to the floating panel's own monitor.
enum AinkradComposerOverlayKey: Equatable {
    case up, down, confirm

    static func key(for keyCode: UInt16) -> AinkradComposerOverlayKey? {
        switch keyCode {
        case 126: return .up
        case 125: return .down
        case 36, 76: return .confirm
        default: return nil
        }
    }

    /// The highlighted row after an arrow press, wrapping at both ends.
    static func moved(_ index: Int, by delta: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return ((index + delta) % count + count) % count
    }
}
