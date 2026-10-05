// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — theme file loader & validation
import Foundation

public struct AinkradThemeFile: Equatable, Sendable {
    public var skin: AinkradSkin
    public var host: Data?

    public init(skin: AinkradSkin, host: Data? = nil) {
        self.skin = skin
        self.host = host
    }

    public init(decoding data: Data, bases: [String: AinkradThemeFile] = [:]) throws {
        let file = try ainkradDecodeThemeFile(data, bases: bases)
        self.skin = file.skin
        self.host = file.host
    }
}

public struct AinkradThemeLoadResult: Equatable, Sendable {
    public var themes: [String: AinkradThemeFile]
    public var issues: [AinkradThemeIssue]

    public init(themes: [String: AinkradThemeFile], issues: [AinkradThemeIssue]) {
        self.themes = themes
        self.issues = issues
    }
}

public struct AinkradThemeIssue: Error, Equatable, Sendable, CustomStringConvertible {
    public var fileId: String?
    public var error: AinkradThemeError

    public init(fileId: String? = nil, error: AinkradThemeError) {
        self.fileId = fileId
        self.error = error
    }

    public var description: String {
        if let fileId {
            return "[\(fileId)] \(error.description)"
        } else {
            return error.description
        }
    }
}

public enum AinkradThemeError: Error, Equatable, Sendable, CustomStringConvertible {
    case fileSizeExceedsLimit(path: String, bytes: Int, limitBytes: Int)
    case invalidJSON(path: String, details: String)
    case unsupportedSchemaVersion(path: String, version: Int)
    case unknownBase(path: String, baseId: String)
    case baseCycle(path: String, cycle: [String])
    case unknownKey(path: String)
    case missingKey(path: String)
    case typeMismatch(path: String, expected: String)
    case nullInOverride(path: String)
    case invalidColorHex(path: String, hex: String)
    case unknownPaletteReference(path: String, reference: String)
    case alphaOutOfRange(path: String, value: Double)
    case negativeDimension(path: String, value: Double)
    case durationOutOfRange(path: String, value: Double)
    case scaleOutOfRange(path: String, value: Double)
    case invalidId(path: String, id: String)
    case invalidTerminalAnsiCount(path: String, count: Int)
    case syntaxHueOutOfRange(path: String, hue: Double)

    public var path: String {
        switch self {
        case .fileSizeExceedsLimit(let path, _, _): return path
        case .invalidJSON(let path, _): return path
        case .unsupportedSchemaVersion(let path, _): return path
        case .unknownBase(let path, _): return path
        case .baseCycle(let path, _): return path
        case .unknownKey(let path): return path
        case .missingKey(let path): return path
        case .typeMismatch(let path, _): return path
        case .nullInOverride(let path): return path
        case .invalidColorHex(let path, _): return path
        case .unknownPaletteReference(let path, _): return path
        case .alphaOutOfRange(let path, _): return path
        case .negativeDimension(let path, _): return path
        case .durationOutOfRange(let path, _): return path
        case .scaleOutOfRange(let path, _): return path
        case .invalidId(let path, _): return path
        case .invalidTerminalAnsiCount(let path, _): return path
        case .syntaxHueOutOfRange(let path, _): return path
        }
    }

    public var description: String {
        switch self {
        case .fileSizeExceedsLimit(let path, let bytes, let limitBytes):
            return "File size exceeds limit at \(path): \(bytes) bytes (max \(limitBytes) bytes)"
        case .invalidJSON(let path, let details):
            return "Invalid JSON at \(path): \(details)"
        case .unsupportedSchemaVersion(let path, let version):
            return "Unsupported schema version at \(path): \(version)"
        case .unknownBase(let path, let baseId):
            return "Unknown base theme '\(baseId)' referenced at \(path)"
        case .baseCycle(let path, let cycle):
            return "Base theme cycle detected at \(path): \(cycle.joined(separator: " -> "))"
        case .unknownKey(let path):
            return "Unknown key at \(path)"
        case .missingKey(let path):
            return "Missing key at \(path)"
        case .typeMismatch(let path, let expected):
            return "Type mismatch at \(path): expected \(expected)"
        case .nullInOverride(let path):
            return "Null in override at \(path)"
        case .invalidColorHex(let path, let hex):
            return "Invalid color hex at \(path): '\(hex)'"
        case .unknownPaletteReference(let path, let reference):
            return "Unknown palette reference at \(path): '\(reference)'"
        case .alphaOutOfRange(let path, let value):
            return "Alpha out of range [0, 1] at \(path): \(value)"
        case .negativeDimension(let path, let value):
            return "Negative dimension at \(path): \(value)"
        case .durationOutOfRange(let path, let value):
            return "Duration out of range [0, 10] s at \(path): \(value)"
        case .scaleOutOfRange(let path, let value):
            return "Scale out of range [0.5, 2] at \(path): \(value)"
        case .invalidId(let path, let id):
            return "Invalid theme ID at \(path): '\(id)'"
        case .invalidTerminalAnsiCount(let path, let count):
            return "Terminal ANSI colors count must be 16 at \(path), got \(count)"
        case .syntaxHueOutOfRange(let path, let hue):
            return "Syntax hue out of range [0, 360] at \(path): \(hue)"
        }
    }
}

public func ainkradLoadThemes(_ files: [Data]) -> AinkradThemeLoadResult {
    var rawFiles: [RawThemeFileData] = []
    var issues: [AinkradThemeIssue] = []

    for (index, data) in files.enumerated() {
        let pathPrefix = "files[\(index)]"
        if data.count > 256 * 1024 {
            issues.append(
                AinkradThemeIssue(
                    error: .fileSizeExceedsLimit(path: pathPrefix, bytes: data.count, limitBytes: 256 * 1024)))
            continue
        }

        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        } catch {
            issues.append(AinkradThemeIssue(error: .invalidJSON(path: pathPrefix, details: error.localizedDescription)))
            continue
        }

        guard let dict = jsonObject as? [String: Any] else {
            issues.append(
                AinkradThemeIssue(
                    error: .invalidJSON(path: pathPrefix, details: "Top-level JSON value must be an object")))
            continue
        }

        let fileId: String
        if let idVal = dict["id"] as? String {
            fileId = idVal
        } else {
            fileId = pathPrefix
        }

        rawFiles.append(RawThemeFileData(data: data, dict: dict, fileId: fileId, originalIndex: index))
    }

    var loadedThemes: [String: AinkradThemeFile] = [:]
    var pendingFiles = rawFiles

    while !pendingFiles.isEmpty {
        var progressMade = false
        var remainingFiles: [RawThemeFileData] = []

        for rawFile in pendingFiles {
            let baseId = rawFile.dict["base"] as? String

            if let baseId {
                if loadedThemes[baseId] != nil {
                    // Base is ready
                } else if rawFiles.contains(where: { $0.fileId == baseId }) {
                    // Base exists in batch but not loaded yet
                    remainingFiles.append(rawFile)
                    continue
                } else {
                    // Unknown base
                    let err = AinkradThemeError.unknownBase(path: "$.base", baseId: baseId)
                    issues.append(AinkradThemeIssue(fileId: rawFile.fileId, error: err))
                    progressMade = true
                    continue
                }
            }

            // Attempt to decode
            do {
                let themeFile = try ainkradDecodeThemeFile(rawFile.data, bases: loadedThemes)
                loadedThemes[themeFile.skin.id] = themeFile
                progressMade = true
            } catch let issue as AinkradThemeIssue {
                var issueWithId = issue
                if issueWithId.fileId == nil {
                    issueWithId.fileId = rawFile.fileId
                }
                issues.append(issueWithId)
                progressMade = true
            } catch let err as AinkradThemeError {
                issues.append(AinkradThemeIssue(fileId: rawFile.fileId, error: err))
                progressMade = true
            } catch {
                issues.append(
                    AinkradThemeIssue(
                        fileId: rawFile.fileId, error: .invalidJSON(path: "$", details: error.localizedDescription)))
                progressMade = true
            }
        }

        if !progressMade {
            // Cycle detected among remaining files
            for rawFile in remainingFiles {
                let baseId = rawFile.dict["base"] as? String ?? ""
                let cyclePath = [rawFile.fileId, baseId]
                let err = AinkradThemeError.baseCycle(path: "$.base", cycle: cyclePath)
                issues.append(AinkradThemeIssue(fileId: rawFile.fileId, error: err))
            }
            break
        }

        pendingFiles = remainingFiles
    }

    return AinkradThemeLoadResult(themes: loadedThemes, issues: issues)
}

struct RawThemeFileData {
    let data: Data
    let dict: [String: Any]
    let fileId: String
    let originalIndex: Int
}
