import SwiftUI

/// A row's trailing count in an `AinkradNavList`: a faint mono number
/// ("31", "3/4"), or — with a `tone` — a filled badge that asks for attention
/// (amber "5" approvals, red "3" stuck), as the Citadel sidebar draws them.
public struct AinkradNavCount: Equatable, Sendable {
    public var text: String
    public var tone: AinkradChartTone?

    public init(_ text: String, tone: AinkradChartTone? = nil) {
        self.text = text
        self.tone = tone
    }
}
