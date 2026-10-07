// design-lint: allow-file hex-color,raw-color theme layer — the values the tokens resolve to
import Foundation

public struct AinkradTextTokens: Codable, Equatable, Sendable {
    public var primary: AinkradColorToken
    public var muted: AinkradColorToken
    public var faint: AinkradColorToken

    public init(
        primary: AinkradColorToken = .palette("foreground", 1.0),
        muted: AinkradColorToken = .palette("foreground", 0.55),
        faint: AinkradColorToken = .palette("foreground", 0.45)
    ) {
        self.primary = primary
        self.muted = muted
        self.faint = faint
    }
}

public struct AinkradSyntaxTokens: Codable, Equatable, Sendable {
    public var comment: AinkradColorToken
    public var stringHue: Double
    public var numberHue: Double
    public var keywordHue: Double
    public var typeHue: Double
    public var onDark: AinkradSyntaxTone
    public var onLight: AinkradSyntaxTone
    /// Epic 6.0 token gap (Lore callouts). Not an `init` parameter (ABI).
    public var callout = AinkradSyntaxCalloutTokens()

    public init(
        comment: AinkradColorToken = .palette("foreground", 0.45),
        stringHue: Double = 140,
        numberHue: Double = 30,
        keywordHue: Double = 285,
        typeHue: Double = 200,
        onDark: AinkradSyntaxTone = AinkradSyntaxTone(saturation: 0.50, brightness: 0.95),
        onLight: AinkradSyntaxTone = AinkradSyntaxTone(saturation: 0.72, brightness: 0.66)
    ) {
        self.comment = comment
        self.stringHue = stringHue
        self.numberHue = numberHue
        self.keywordHue = keywordHue
        self.typeHue = typeHue
        self.onDark = onDark
        self.onLight = onLight
    }

    public enum Kind {
        case comment, string, number, keyword, type
    }

    public func color(_ kind: Kind, onDark: Bool) -> AinkradColorToken {
        switch kind {
        case .comment:
            return comment
        case .string:
            return tokenForHue(stringHue, onDark: onDark)
        case .number:
            return tokenForHue(numberHue, onDark: onDark)
        case .keyword:
            return tokenForHue(keywordHue, onDark: onDark)
        case .type:
            return tokenForHue(typeHue, onDark: onDark)
        }
    }

    private func tokenForHue(_ hue: Double, onDark: Bool) -> AinkradColorToken {
        let tone = onDark ? self.onDark : self.onLight
        let (r, g, b) = hsbToRGB(h: hue / 360.0, s: tone.saturation, b: tone.brightness)
        return .hex(r, g, b, 1.0)
    }
}

public struct AinkradSyntaxTone: Codable, Equatable, Sendable {
    public var saturation: Double
    public var brightness: Double

    public init(saturation: Double, brightness: Double) {
        self.saturation = saturation
        self.brightness = brightness
    }
}

public struct AinkradTerminalTokens: Codable, Equatable, Sendable {
    public var background: AinkradColorToken
    public var foreground: AinkradColorToken
    public var cursor: AinkradColorToken
    public var selection: AinkradColorToken
    public var ansi: [AinkradColorToken]

    public init(
        background: AinkradColorToken,
        foreground: AinkradColorToken,
        cursor: AinkradColorToken,
        selection: AinkradColorToken,
        ansi: [AinkradColorToken]
    ) {
        precondition(ansi.count == 16, "ansi palette must have exactly 16 entries")
        self.background = background
        self.foreground = foreground
        self.cursor = cursor
        self.selection = selection
        self.ansi = ansi
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.background = try container.decode(AinkradColorToken.self, forKey: .background)
        self.foreground = try container.decode(AinkradColorToken.self, forKey: .foreground)
        self.cursor = try container.decode(AinkradColorToken.self, forKey: .cursor)
        self.selection = try container.decode(AinkradColorToken.self, forKey: .selection)
        self.ansi = try container.decode([AinkradColorToken].self, forKey: .ansi)
        if ansi.count != 16 {
            throw DecodingError.dataCorruptedError(
                forKey: .ansi, in: container, debugDescription: "ansi must have 16 tokens")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case background, foreground, cursor, selection, ansi
    }
}

private func hsbToRGB(h: Double, s: Double, b: Double) -> (Double, Double, Double) {
    if s == 0 { return (b, b, b) }
    let angle = (h.truncatingRemainder(dividingBy: 1.0) + 1.0).truncatingRemainder(dividingBy: 1.0) * 6.0
    let i = Int(floor(angle))
    let f = angle - Double(i)
    let p = b * (1.0 - s)
    let q = b * (1.0 - s * f)
    let t = b * (1.0 - s * (1.0 - f))
    switch i {
    case 0: return (b, t, p)
    case 1: return (q, b, p)
    case 2: return (p, b, t)
    case 3: return (p, q, b)
    case 4: return (t, p, b)
    default: return (b, p, q)
    }
}
