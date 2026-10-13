// design-lint: allow-file hex-color,raw-color,opacity-literal the mockups' fixed syntax palettes (Designs/forge/forge.css, Designs/grimoire/10-markdown.html)
import SwiftUI

/// What a stretch of source text is, for colouring.
enum AinkradSyntaxKind: Equatable, Sendable {
    case plain, keyword, type, string, number, comment, function, attribute
}

/// Splits one line of source into coloured runs. A deliberately small,
/// language-agnostic scanner: keywords from the common languages Forge and
/// Grimoire show (Swift, JS/TS, Python, Ruby, Go, Rust, PHP), capitalised
/// identifiers as types, an identifier before `(` as a call, `@x`/`#x` as
/// attributes and directives, quotes, numbers and `//`, `#`, `/* */` comments.
/// ponytail: no grammar, so a keyword-named identifier or a `#` inside a C
/// macro can colour wrongly; Forge's editor uses tree-sitter — reach for it if
/// a diff ever needs exact highlighting.
func ainkradSyntaxRuns(_ line: String) -> [(text: String, kind: AinkradSyntaxKind)] {
    let chars = Array(line.unicodeScalars)
    var runs: [(text: String, kind: AinkradSyntaxKind)] = []
    func push(_ range: Range<Int>, _ kind: AinkradSyntaxKind) {
        var text = ""
        text.unicodeScalars.append(contentsOf: chars[range])
        if let last = runs.last, last.kind == kind {
            runs[runs.count - 1].text += text
        } else {
            runs.append((text, kind))
        }
    }
    func isIdentStart(_ c: Unicode.Scalar) -> Bool { c == "_" || c.properties.isAlphabetic }
    func isIdent(_ c: Unicode.Scalar) -> Bool { isIdentStart(c) || c.properties.numericType != nil }
    func identEnd(from start: Int) -> Int {
        var end = start
        while end < chars.count, isIdent(chars[end]) { end += 1 }
        return end
    }

    var i = 0
    while i < chars.count {
        let c = chars[i]
        let next: Unicode.Scalar? = i + 1 < chars.count ? chars[i + 1] : nil
        if c == "/" && next == "/" {
            push(i..<chars.count, .comment)
            break
        }
        if c == "/" && next == "*" {
            var end = i + 2
            while end + 1 < chars.count, !(chars[end] == "*" && chars[end + 1] == "/") { end += 1 }
            end = min(end + 2, chars.count)
            push(i..<end, .comment)
            i = end
            continue
        }
        if c == "#" || c == "@", let next, isIdentStart(next) {
            let end = identEnd(from: i + 1)
            push(i..<end, .attribute)
            i = end
            continue
        }
        if c == "#" {
            push(i..<chars.count, .comment)
            break
        }
        if c == "\"" || c == "'" || c == "`" {
            var end = i + 1
            while end < chars.count, chars[end] != c {
                end += chars[end] == "\\" ? 2 : 1
            }
            end = min(end + 1, chars.count)
            push(i..<end, .string)
            i = end
            continue
        }
        if c.properties.numericType != nil {
            var end = i + 1
            while end < chars.count, isIdent(chars[end]) || chars[end] == "." { end += 1 }
            push(i..<end, .number)
            i = end
            continue
        }
        if isIdentStart(c) {
            let end = identEnd(from: i)
            var word = ""
            word.unicodeScalars.append(contentsOf: chars[i..<end])
            let kind: AinkradSyntaxKind
            if ainkradSyntaxKeywords.contains(word) {
                kind = .keyword
            } else if c.properties.isUppercase {
                kind = .type
            } else if chars[end...].first(where: { $0 != " " }) == "(" {
                kind = .function
            } else {
                kind = .plain
            }
            push(i..<end, kind)
            i = end
            continue
        }
        push(i..<(i + 1), .plain)
        i += 1
    }
    return runs
}

private let ainkradSyntaxKeywords: Set<String> = [
    "let", "var", "func", "if", "else", "guard", "return", "for", "in", "while", "switch", "case", "default",
    "break", "continue", "struct", "class", "enum", "protocol", "extension", "import", "private", "public",
    "internal", "fileprivate", "static", "final", "override", "init", "deinit", "self", "Self", "super", "true",
    "false", "nil", "null", "None", "True", "False", "try", "catch", "throw", "throws", "async", "await", "some",
    "any", "where", "as", "is", "do", "repeat", "defer", "typealias", "inout", "mutating", "weak", "lazy", "const",
    "function", "export", "from", "new", "typeof", "instanceof", "yield", "def", "elif", "lambda", "pass", "with",
    "not", "and", "or", "end", "module", "require", "then", "unless", "package", "fn", "impl", "trait", "pub", "use",
    "mod", "match", "interface", "go", "chan", "echo", "namespace", "this",
]

/// Colours for each `AinkradSyntaxKind`; `nil` keeps the line's base colour.
struct AinkradSyntaxPalette {
    var keyword: Color?
    var type: Color?
    var string: Color?
    var number: Color?
    var comment: Color?
    var function: Color?
    var attribute: Color?

    func color(_ kind: AinkradSyntaxKind) -> Color? {
        switch kind {
        case .plain: nil
        case .keyword: keyword
        case .type: type
        case .string: string
        case .number: number
        case .comment: comment
        case .function: function
        case .attribute: attribute
        }
    }

    /// Forge's editor colours (`forge.css`): Neon is the kit terminal
    /// palette, Glass a softer Xcode dark.
    static func forge(glass: Bool) -> AinkradSyntaxPalette {
        glass
            ? AinkradSyntaxPalette(
                keyword: rgb(0xFF7AB2), type: rgb(0xDABAFF), string: rgb(0xFF8170), number: rgb(0xD9C97C),
                comment: Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255).opacity(0.42),
                function: rgb(0x6BDFFF), attribute: rgb(0xB281EB))
            : AinkradSyntaxPalette(
                keyword: rgb(0xC084FC), type: rgb(0x22D3EE), string: rgb(0xFBBF24), number: rgb(0xF472B6),
                comment: Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255).opacity(0.38),
                function: rgb(0x60A5FA), attribute: rgb(0x34D399))
    }

    /// Grimoire's reply code blocks (`10-markdown.html`), the same in both
    /// themes: keywords violet, strings green, numbers and directives cyan.
    static let reply = AinkradSyntaxPalette(
        keyword: rgb(0xC084FC), type: nil, string: rgb(0x86EFAC), number: rgb(0x67E8F9),
        comment: Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255).opacity(0.38),
        function: nil, attribute: rgb(0x67E8F9))

    private static func rgb(_ hex: Int) -> Color {
        Color(
            red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}

/// `line` with each run coloured by `palette`; uncoloured runs keep the
/// Text's own foreground. Comments are italic, as the mockups draw them.
func ainkradSyntaxAttributed(_ line: String, palette: AinkradSyntaxPalette) -> AttributedString {
    var out = AttributedString()
    for run in ainkradSyntaxRuns(line) {
        var piece = AttributedString(run.text)
        if let color = palette.color(run.kind) { piece.foregroundColor = color }
        if run.kind == .comment { piece.inlinePresentationIntent = .emphasized }
        out += piece
    }
    return out
}
