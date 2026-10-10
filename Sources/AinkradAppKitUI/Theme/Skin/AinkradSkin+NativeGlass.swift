import Foundation

/// Whether kit components draw Apple's own controls: the skin's material is
/// `glass` and the OS has Liquid Glass (macOS 26). Below that, Glass keeps the
/// kit's own rendering. File scope, not a static: see the AppKitUI trap note.
public func ainkradUsesNativeGlass(materialKind: String) -> Bool {
    guard materialKind == "glass" else { return false }
    if #available(macOS 26, *) { return true }
    return false
}

extension AinkradSkin {
    /// `material.kind == "glass"` on macOS 26+: kit components render native
    /// SwiftUI/AppKit controls instead of the kit's own (Glass Native E0.1).
    public var usesNativeGlass: Bool { ainkradUsesNativeGlass(materialKind: material.kind) }
}
