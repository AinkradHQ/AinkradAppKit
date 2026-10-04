// design-lint: allow-file hex-color,raw-color,radius-literal,font-size,padding-literal,spacing-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — the values the tokens resolve to
import CoreGraphics
import Foundation

// MARK: - Core Tokens

public enum AinkradColorToken: Codable, Equatable, Sendable {
    case hex(Double, Double, Double, Double)
    case palette(String, Double)
    case tint(Double)
    case clear

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        if str == "clear" {
            self = .clear
            return
        }
        if str == "tint" {
            self = .tint(1.0)
            return
        }
        if str.hasPrefix("tint@") {
            let parts = str.dropFirst(5)
            if let alpha = Double(parts) {
                self = .tint(alpha)
                return
            }
        }
        if str.hasPrefix("#") {
            let hexStr = String(str.dropFirst())
            if hexStr.count == 6 {
                if let val = UInt32(hexStr, radix: 16) {
                    let r = Double((val >> 16) & 0xFF) / 255.0
                    let g = Double((val >> 8) & 0xFF) / 255.0
                    let b = Double(val & 0xFF) / 255.0
                    self = .hex(r, g, b, 1.0)
                    return
                }
            } else if hexStr.count == 8 {
                if let val = UInt64(hexStr, radix: 16) {
                    let r = Double((val >> 24) & 0xFF) / 255.0
                    let g = Double((val >> 16) & 0xFF) / 255.0
                    let b = Double((val >> 8) & 0xFF) / 255.0
                    let a = Double(val & 0xFF) / 255.0
                    self = .hex(r, g, b, a)
                    return
                }
            }
        }
        if str.contains("@") {
            let parts = str.split(separator: "@")
            if parts.count == 2, let alpha = Double(parts[1]) {
                self = .palette(String(parts[0]), alpha)
                return
            }
        }
        self = .palette(str, 1.0)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .clear:
            try container.encode("clear")
        case .tint(let a):
            if a == 1.0 {
                try container.encode("tint")
            } else {
                let formatted = String(format: a == a.rounded() ? "%.0f" : "%g", a)
                try container.encode("tint@\(formatted)")
            }
        case .palette(let key, let a):
            if a == 1.0 {
                try container.encode(key)
            } else {
                let formatted = String(format: a == a.rounded() ? "%.0f" : "%g", a)
                try container.encode("\(key)@\(formatted)")
            }
        case .hex(let r, let g, let b, let a):
            let ri = Int((r * 255.0).rounded())
            let gi = Int((g * 255.0).rounded())
            let bi = Int((b * 255.0).rounded())
            if a == 1.0 {
                try container.encode(String(format: "#%02X%02X%02X", ri, gi, bi))
            } else {
                let ai = Int((a * 255.0).rounded())
                try container.encode(String(format: "#%02X%02X%02X%02X", ri, gi, bi, ai))
            }
        }
    }
}

public struct AinkradControlState: OptionSet, Codable, Equatable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let hover = AinkradControlState(rawValue: 1 << 0)
    public static let pressed = AinkradControlState(rawValue: 1 << 1)
    public static let selected = AinkradControlState(rawValue: 1 << 2)
    public static let focused = AinkradControlState(rawValue: 1 << 3)
    public static let disabled = AinkradControlState(rawValue: 1 << 4)
}

public struct AinkradStateColor: Codable, Equatable, Sendable {
    public var rest: AinkradColorToken
    public var hover: AinkradColorToken?
    public var pressed: AinkradColorToken?
    public var selected: AinkradColorToken?
    public var focused: AinkradColorToken?
    public var disabled: AinkradColorToken?

    public init(
        rest: AinkradColorToken,
        hover: AinkradColorToken? = nil,
        pressed: AinkradColorToken? = nil,
        selected: AinkradColorToken? = nil,
        focused: AinkradColorToken? = nil,
        disabled: AinkradColorToken? = nil
    ) {
        self.rest = rest
        self.hover = hover
        self.pressed = pressed
        self.selected = selected
        self.focused = focused
        self.disabled = disabled
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.rest = try container.decode(AinkradColorToken.self, forKey: .rest)
            self.hover = try container.decodeIfPresent(AinkradColorToken.self, forKey: .hover)
            self.pressed = try container.decodeIfPresent(AinkradColorToken.self, forKey: .pressed)
            self.selected = try container.decodeIfPresent(AinkradColorToken.self, forKey: .selected)
            self.focused = try container.decodeIfPresent(AinkradColorToken.self, forKey: .focused)
            self.disabled = try container.decodeIfPresent(AinkradColorToken.self, forKey: .disabled)
        } else {
            let container = try decoder.singleValueContainer()
            self.rest = try container.decode(AinkradColorToken.self)
            self.hover = nil
            self.pressed = nil
            self.selected = nil
            self.focused = nil
            self.disabled = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        if hover == nil && pressed == nil && selected == nil && focused == nil && disabled == nil {
            var container = encoder.singleValueContainer()
            try container.encode(rest)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(rest, forKey: .rest)
            try container.encodeIfPresent(hover, forKey: .hover)
            try container.encodeIfPresent(pressed, forKey: .pressed)
            try container.encodeIfPresent(selected, forKey: .selected)
            try container.encodeIfPresent(focused, forKey: .focused)
            try container.encodeIfPresent(disabled, forKey: .disabled)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case rest, hover, pressed, selected, focused, disabled
    }

    public func resolve(_ state: AinkradControlState) -> AinkradColorToken {
        if state.contains(.disabled), let disabled { return disabled }
        if state.contains(.pressed), let pressed { return pressed }
        if state.contains(.selected), let selected { return selected }
        if state.contains(.focused), let focused { return focused }
        if state.contains(.hover), let hover { return hover }
        return rest
    }
}

public struct AinkradStateDouble: Codable, Equatable, Sendable {
    public var rest: Double
    public var hover: Double?
    public var pressed: Double?
    public var selected: Double?
    public var focused: Double?
    public var disabled: Double?

    public init(
        rest: Double,
        hover: Double? = nil,
        pressed: Double? = nil,
        selected: Double? = nil,
        focused: Double? = nil,
        disabled: Double? = nil
    ) {
        self.rest = rest
        self.hover = hover
        self.pressed = pressed
        self.selected = selected
        self.focused = focused
        self.disabled = disabled
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.rest = try container.decode(Double.self, forKey: .rest)
            self.hover = try container.decodeIfPresent(Double.self, forKey: .hover)
            self.pressed = try container.decodeIfPresent(Double.self, forKey: .pressed)
            self.selected = try container.decodeIfPresent(Double.self, forKey: .selected)
            self.focused = try container.decodeIfPresent(Double.self, forKey: .focused)
            self.disabled = try container.decodeIfPresent(Double.self, forKey: .disabled)
        } else {
            let container = try decoder.singleValueContainer()
            self.rest = try container.decode(Double.self)
            self.hover = nil
            self.pressed = nil
            self.selected = nil
            self.focused = nil
            self.disabled = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        if hover == nil && pressed == nil && selected == nil && focused == nil && disabled == nil {
            var container = encoder.singleValueContainer()
            try container.encode(rest)
        } else {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(rest, forKey: .rest)
            try container.encodeIfPresent(hover, forKey: .hover)
            try container.encodeIfPresent(pressed, forKey: .pressed)
            try container.encodeIfPresent(selected, forKey: .selected)
            try container.encodeIfPresent(focused, forKey: .focused)
            try container.encodeIfPresent(disabled, forKey: .disabled)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case rest, hover, pressed, selected, focused, disabled
    }

    public func resolve(_ state: AinkradControlState) -> Double {
        if state.contains(.disabled), let disabled { return disabled }
        if state.contains(.pressed), let pressed { return pressed }
        if state.contains(.selected), let selected { return selected }
        if state.contains(.focused), let focused { return focused }
        if state.contains(.hover), let hover { return hover }
        return rest
    }
}

public struct AinkradShapeToken: Codable, Equatable, Sendable {
    public var style: String
    public var cut: Double?
    public var cutRatio: Double?
    public var minCut: Double?
    public var corners: String?

    public init(
        style: String = "chamfer",
        cut: Double? = nil,
        cutRatio: Double? = nil,
        minCut: Double? = nil,
        corners: String? = nil
    ) {
        self.style = style
        self.cut = cut
        self.cutRatio = cutRatio
        self.minCut = minCut
        self.corners = corners
    }
}

public struct AinkradStrokeToken: Codable, Equatable, Sendable {
    public var color: AinkradStateColor
    public var width: AinkradStateDouble

    public init(color: AinkradStateColor, width: AinkradStateDouble = AinkradStateDouble(rest: 1.0)) {
        self.color = color
        self.width = width
    }
}

public struct AinkradGlowToken: Codable, Equatable, Sendable {
    public var color: AinkradStateColor
    public var radius: AinkradStateDouble

    public init(color: AinkradStateColor, radius: AinkradStateDouble) {
        self.color = color
        self.radius = radius
    }
}

public struct AinkradShadowToken: Codable, Equatable, Sendable {
    public var color: AinkradColorToken
    public var radius: Double
    public var x: Double
    public var y: Double

    public init(color: AinkradColorToken, radius: Double, x: Double = 0, y: Double = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

public struct AinkradFontToken: Codable, Equatable, Sendable {
    public var role: String?
    public var size: Double?
    public var sizeKey: String?
    public var weight: String?
    public var mono: String?  // "none", "family", "system"
    public var monospacedDigits: Bool?
    public var scaled: Bool?
    public var tracking: Double?
    public var kerning: Double?

    public init(
        role: String? = nil,
        size: Double? = nil,
        sizeKey: String? = nil,
        weight: String? = nil,
        mono: String? = nil,
        monospacedDigits: Bool? = nil,
        scaled: Bool? = nil,
        tracking: Double? = nil,
        kerning: Double? = nil
    ) {
        self.role = role
        self.size = size
        self.sizeKey = sizeKey
        self.weight = weight
        self.mono = mono
        self.monospacedDigits = monospacedDigits
        self.scaled = scaled
        self.tracking = tracking
        self.kerning = kerning
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decodeIfPresent(String.self, forKey: .role)
        self.weight = try container.decodeIfPresent(String.self, forKey: .weight)
        self.mono = try container.decodeIfPresent(String.self, forKey: .mono)
        self.monospacedDigits = try container.decodeIfPresent(Bool.self, forKey: .monospacedDigits)
        self.scaled = try container.decodeIfPresent(Bool.self, forKey: .scaled)
        self.tracking = try container.decodeIfPresent(Double.self, forKey: .tracking)
        self.kerning = try container.decodeIfPresent(Double.self, forKey: .kerning)

        if let num = try? container.decode(Double.self, forKey: .size) {
            self.size = num
            self.sizeKey = nil
        } else if let key = try? container.decode(String.self, forKey: .size) {
            self.size = nil
            self.sizeKey = key
        } else {
            self.size = nil
            self.sizeKey = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(mono, forKey: .mono)
        try container.encodeIfPresent(monospacedDigits, forKey: .monospacedDigits)
        try container.encodeIfPresent(scaled, forKey: .scaled)
        try container.encodeIfPresent(tracking, forKey: .tracking)
        try container.encodeIfPresent(kerning, forKey: .kerning)

        if let size {
            try container.encode(size, forKey: .size)
        } else if let sizeKey {
            try container.encode(sizeKey, forKey: .size)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case role, size, weight, mono, monospacedDigits, scaled, tracking, kerning
    }
}

public struct AinkradAnimationToken: Codable, Equatable, Sendable {
    public var curve: String  // "easeIn", "easeOut", "easeInOut", "linear", "spring", "snappy"
    public var duration: Double?
    public var durationKey: String?
    public var response: Double?
    public var damping: Double?

    public init(
        curve: String,
        duration: Double? = nil,
        durationKey: String? = nil,
        response: Double? = nil,
        damping: Double? = nil
    ) {
        self.curve = curve
        self.duration = duration
        self.durationKey = durationKey
        self.response = response
        self.damping = damping
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.curve = try container.decode(String.self, forKey: .curve)
        self.response = try container.decodeIfPresent(Double.self, forKey: .response)
        self.damping = try container.decodeIfPresent(Double.self, forKey: .damping)

        if let num = try? container.decode(Double.self, forKey: .duration) {
            self.duration = num
            self.durationKey = nil
        } else if let key = try? container.decode(String.self, forKey: .duration) {
            self.duration = nil
            self.durationKey = key
        } else {
            self.duration = nil
            self.durationKey = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(curve, forKey: .curve)
        try container.encodeIfPresent(response, forKey: .response)
        try container.encodeIfPresent(damping, forKey: .damping)

        if let duration {
            try container.encode(duration, forKey: .duration)
        } else if let durationKey {
            try container.encode(durationKey, forKey: .duration)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case curve, duration, response, damping
    }
}
