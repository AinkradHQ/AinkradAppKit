// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — theme file validation & decoding logic
import Foundation

func ainkradDecodeThemeFile(_ data: Data, bases: [String: AinkradThemeFile] = [:]) throws -> AinkradThemeFile {
    if data.count > 256 * 1024 {
        throw AinkradThemeError.fileSizeExceedsLimit(path: "$", bytes: data.count, limitBytes: 256 * 1024)
    }

    let topLevelObj: Any
    do {
        topLevelObj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    } catch {
        throw AinkradThemeError.invalidJSON(path: "$", details: error.localizedDescription)
    }

    guard let topDict = topLevelObj as? [String: Any] else {
        throw AinkradThemeError.invalidJSON(path: "$", details: "Top-level JSON value must be an object")
    }

    // Step 3: schemaVersion check
    if let ver = topDict["schemaVersion"] {
        if let vInt = ver as? Int {
            if vInt != 1 {
                throw AinkradThemeError.unsupportedSchemaVersion(path: "$.schemaVersion", version: vInt)
            }
        } else if let vNum = ver as? NSNumber {
            let vInt = vNum.intValue
            if vInt != 1 {
                throw AinkradThemeError.unsupportedSchemaVersion(path: "$.schemaVersion", version: vInt)
            }
        } else {
            throw AinkradThemeError.typeMismatch(path: "$.schemaVersion", expected: "Int")
        }
    }

    // Step 4: Base lookup & deep merge
    var mergedDict: [String: Any] = [:]
    var hostData: Data? = nil

    if let baseVal = topDict["base"] {
        guard let baseId = baseVal as? String else {
            throw AinkradThemeError.typeMismatch(path: "$.base", expected: "String")
        }
        guard let baseTheme = bases[baseId] else {
            throw AinkradThemeError.unknownBase(path: "$.base", baseId: baseId)
        }

        // Base skin to dict
        let encoder = JSONEncoder()
        let baseData = try encoder.encode(baseTheme.skin)
        guard let baseDictObj = try JSONSerialization.jsonObject(with: baseData) as? [String: Any] else {
            throw AinkradThemeError.invalidJSON(path: "$", details: "Failed to convert base theme skin to JSON object")
        }
        mergedDict = baseDictObj
        hostData = baseTheme.host

        // Deep merge topDict onto baseDict
        try ainkradDeepMerge(override: topDict, onto: &mergedDict, path: "$")
    } else {
        mergedDict = topDict
    }

    // Host extraction from topDict if present
    if topDict.keys.contains("host") {
        if let hostObj = topDict["host"] {
            if NSNull() is NSNull, hostObj is NSNull {
                hostData = nil
            } else {
                hostData = try JSONSerialization.data(
                    withJSONObject: hostObj, options: [.fragmentsAllowed, .sortedKeys])
            }
        }
    }

    // Step 5: Diff against standard key tree
    let standardData = try JSONEncoder().encode(AinkradSkin.standard)
    guard let standardDictObj = try JSONSerialization.jsonObject(with: standardData) as? [String: Any] else {
        throw AinkradThemeError.invalidJSON(path: "$", details: "Failed to convert standard skin to JSON object")
    }

    try ainkradValidateKeys(merged: mergedDict, standard: standardDictObj, path: "$")

    // Step 6: Decode into AinkradSkin
    let finalMergedData = try JSONSerialization.data(withJSONObject: mergedDict, options: [])
    let skin: AinkradSkin
    do {
        let decoder = JSONDecoder()
        skin = try decoder.decode(AinkradSkin.self, from: finalMergedData)
    } catch let error as DecodingError {
        throw ainkradConvertDecodingError(error)
    } catch {
        throw AinkradThemeError.invalidJSON(path: "$", details: error.localizedDescription)
    }

    // Step 7 & 8: Semantic validation
    try ainkradValidateSemanticRules(skin)

    return AinkradThemeFile(skin: skin, host: hostData)
}

func ainkradDeepMerge(override: [String: Any], onto base: inout [String: Any], path: String) throws {
    for (key, overrideVal) in override {
        let currentPath = "\(path).\(key)"
        if overrideVal is NSNull {
            throw AinkradThemeError.nullInOverride(path: currentPath)
        }

        if let overrideDict = overrideVal as? [String: Any] {
            if let baseSubDict = base[key] as? [String: Any] {
                var mutableSubDict = baseSubDict
                try ainkradDeepMerge(override: overrideDict, onto: &mutableSubDict, path: currentPath)
                base[key] = mutableSubDict
            } else {
                base[key] = overrideDict
            }
        } else {
            base[key] = overrideVal
        }
    }
}

func ainkradValidateKeys(merged: [String: Any], standard: [String: Any], path: String) throws {
    let allowedTopLevelSpecial: Set<String> = ["schemaVersion", "base", "host"]

    for (key, value) in merged {
        let currentPath = "\(path).\(key)"

        if path == "$" && allowedTopLevelSpecial.contains(key) {
            continue
        }

        guard let standardVal = standard[key] else {
            throw AinkradThemeError.unknownKey(path: currentPath)
        }

        if let mergedSubDict = value as? [String: Any], let standardSubDict = standardVal as? [String: Any] {
            try ainkradValidateKeys(merged: mergedSubDict, standard: standardSubDict, path: currentPath)
        }
    }
}

func ainkradConvertDecodingError(_ error: DecodingError) -> AinkradThemeError {
    switch error {
    case .keyNotFound(let key, let context):
        let path = ainkradPathFromContext(context, appending: key.stringValue)
        return .missingKey(path: path)
    case .typeMismatch(let type, let context):
        let path = ainkradPathFromContext(context)
        return .typeMismatch(path: path, expected: "\(type)")
    case .valueNotFound(let type, let context):
        let path = ainkradPathFromContext(context)
        return .missingKey(path: path)
    case .dataCorrupted(let context):
        let path = ainkradPathFromContext(context)
        return .invalidJSON(path: path, details: context.debugDescription)
    @unknown default:
        return .invalidJSON(path: "$", details: error.localizedDescription)
    }
}

func ainkradPathFromContext(_ context: DecodingError.Context, appending key: String? = nil) -> String {
    var parts = ["$"]
    for codingKey in context.codingPath {
        if let intValue = codingKey.intValue {
            parts.append("[\(intValue)]")
        } else {
            parts.append(".\(codingKey.stringValue)")
        }
    }
    if let key {
        parts.append(".\(key)")
    }
    return parts.joined()
}

func ainkradValidateSemanticRules(_ skin: AinkradSkin) throws {
    // ID check: non-empty [A-Za-z0-9.-]
    let idRegex = try! NSRegularExpression(pattern: "^[A-Za-z0-9.-]+$")  // design-lint: allow try-bang constant regex
    let idRange = NSRange(location: 0, length: skin.id.utf16.count)
    if skin.id.isEmpty || idRegex.firstMatch(in: skin.id, options: [], range: idRange) == nil {
        throw AinkradThemeError.invalidId(path: "$.id", id: skin.id)
    }

    // Palette valid keys
    let paletteKeys: Set<String> = [
        "background", "surface", "surfaceElevated", "surfaceHover", "surfacePressed", "surfaceSelected",
        "accentPrimary", "accentSecondary", "accentTertiary", "border", "borderSubtle", "borderFocus",
        "foreground", "foregroundMuted", "foregroundFaint", "success", "warning", "danger", "black", "white",
    ]

    // Validate colors in palette
    let mirror = Mirror(reflecting: skin.palette)
    for child in mirror.children {
        if let key = child.label, let token = child.value as? AinkradColorToken {
            try ainkradValidateColorToken(token, paletteKeys: paletteKeys, path: "$.palette.\(key)")
        }
    }

    // Recursively validate skin color tokens & ranges
    try ainkradValidateValue(skin, paletteKeys: paletteKeys, path: "$")
}

func ainkradValidateColorToken(_ token: AinkradColorToken, paletteKeys: Set<String>, path: String) throws {
    switch token {
    case .hex(let r, let g, let b, let a):
        if r < 0 || r > 1 || g < 0 || g > 1 || b < 0 || b > 1 {
            // Unreachable with hex parsing unless bad values
        }
        if a < 0 || a > 1 {
            throw AinkradThemeError.alphaOutOfRange(path: path, value: a)
        }
    case .palette(let key, let alpha):
        if !paletteKeys.contains(key) {
            throw AinkradThemeError.unknownPaletteReference(path: path, reference: key)
        }
        if alpha < 0 || alpha > 1 {
            throw AinkradThemeError.alphaOutOfRange(path: path, value: alpha)
        }
    case .tint(let alpha):
        if alpha < 0 || alpha > 1 {
            throw AinkradThemeError.alphaOutOfRange(path: path, value: alpha)
        }
    case .clear:
        break
    }
}

func ainkradValidateValue(_ value: Any, paletteKeys: Set<String>, path: String) throws {
    let mirror = Mirror(reflecting: value)

    if mirror.displayStyle == .optional {
        if let child = mirror.children.first {
            try ainkradValidateValue(child.value, paletteKeys: paletteKeys, path: path)
        }
        return
    }

    if let token = value as? AinkradColorToken {
        try ainkradValidateColorToken(token, paletteKeys: paletteKeys, path: path)
        return
    }

    if let doubleVal = value as? Double {
        try ainkradCheckDoubleRange(doubleVal, path: path)
        return
    }

    if let floatVal = value as? CGFloat {
        try ainkradCheckDoubleRange(Double(floatVal), path: path)
        return
    }

    if let animToken = value as? AinkradAnimationToken {
        if let dur = animToken.duration {
            if dur < 0 || dur > 10 {
                throw AinkradThemeError.durationOutOfRange(path: "\(path).duration", value: dur)
            }
        }
    }

    if let terminalTokens = value as? AinkradTerminalTokens {
        if terminalTokens.ansi.count != 16 {
            throw AinkradThemeError.invalidTerminalAnsiCount(path: "\(path).ansi", count: terminalTokens.ansi.count)
        }
    }

    if let syntaxTokens = value as? AinkradSyntaxTokens {
        let hues: [(String, Double)] = [
            ("keywordHue", syntaxTokens.keywordHue),
            ("stringHue", syntaxTokens.stringHue),
            ("typeHue", syntaxTokens.typeHue),
            ("numberHue", syntaxTokens.numberHue),
        ]
        for (name, h) in hues {
            if h < 0 || h > 360 {
                throw AinkradThemeError.syntaxHueOutOfRange(path: "\(path).\(name)", hue: h)
            }
        }
    }

    for child in mirror.children {
        guard let label = child.label else { continue }
        let childPath: String
        if label.starts(with: "[") {
            childPath = "\(path)\(label)"
        } else {
            childPath = "\(path).\(label)"
        }
        try ainkradValidateValue(child.value, paletteKeys: paletteKeys, path: childPath)
    }
}

func ainkradCheckDoubleRange(_ val: Double, path: String) throws {
    let lowerPath = path.lowercased()

    if lowerPath.contains("alpha") {
        if val < 0 || val > 1 {
            throw AinkradThemeError.alphaOutOfRange(path: path, value: val)
        }
    } else if lowerPath.contains("width") || lowerPath.contains("height") || lowerPath.contains("size")
        || lowerPath.contains("radius") || lowerPath.contains("cut") || lowerPath.contains("spacing")
        || lowerPath.contains("padding") || lowerPath.contains("elevation")
    {
        if val < 0 {
            throw AinkradThemeError.negativeDimension(path: path, value: val)
        }
    } else if lowerPath.contains("duration") {
        if val < 0 || val > 10 {
            throw AinkradThemeError.durationOutOfRange(path: path, value: val)
        }
    } else if lowerPath.contains("scale") || lowerPath.contains("fraction") {
        // Only enforce scale range if path actually ends with scale or is scale-like
        if lowerPath.hasSuffix(".scale") || lowerPath.contains("scale") {
            if val < 0.5 || val > 2.0 {
                throw AinkradThemeError.scaleOutOfRange(path: path, value: val)
            }
        }
    }
}
