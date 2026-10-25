import SwiftUI

/// A plain, accessible button around a bespoke label — for surfaces the kit's styled buttons don't cover (a
/// company card, a figure in an orbit, a stat tile). It adds no chrome; the label draws its own states.
public struct AinkradTapArea<Label: View>: View {
    private let help: String?
    private let action: () -> Void
    private let label: Label

    public init(help: String? = nil, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.help = help
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) { label }
            .buttonStyle(.plain)
            .help(help ?? "")
    }
}
