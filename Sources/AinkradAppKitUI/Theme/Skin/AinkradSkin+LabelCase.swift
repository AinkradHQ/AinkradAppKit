import SwiftUI

extension AinkradSkin {
    /// `text` cased for a kit label by `type.labelCase`: uppercased unless the
    /// theme says `none` (Glass), so Neon's caps are a token, not a constant.
    public func labelCased(_ text: String) -> String {
        type.labelCase == "none" ? text : text.uppercased()
    }

    /// `type.labelCase` as a `textCase` modifier value; nil leaves text as written.
    public var labelTextCase: Text.Case? { type.labelCase == "none" ? nil : .uppercase }
}
