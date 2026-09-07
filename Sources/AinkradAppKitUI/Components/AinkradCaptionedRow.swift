import SwiftUI
import AinkradAppKitContract

/// A control with a caption in a fixed leading column.
///
/// Two-axis sections — typeface/size, icon colour/appearance — rendered as two
/// identical rows of pills read as ONE flat list of six options. "Auto, Blue,
/// Purple, System, Light, Dark" is unparseable without knowing where one
/// control ends and the next begins.
///
/// The column is a fixed width so stacked controls align down the page, which
/// is what makes them read as a form rather than as loose buttons.
public struct AinkradCaptionedRow<Content: View>: View {
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradTypography) private var typo

    /// Internal rather than private so a test can assert the row still carries
    /// the string it uses as its accessibility label. The modifiers themselves
    /// are not inspectable from a unit test; this at least fails if the caption
    /// stops being stored.
    let caption: String
    private let content: Content

    public static var captionColumnWidth: CGFloat { 86 }

    public init(_ caption: String, @ViewBuilder content: () -> Content) {
        self.caption = caption
        self.content = content()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: AinkradSpacing.md) {
            Text(caption)
                .font(AinkradFontResolver.font(.caption, weight: .medium, typography: typo))
                .foregroundStyle(theme.foreground.opacity(0.45))
                .frame(width: Self.captionColumnWidth, alignment: .leading)
                // Hidden as its own element, but NOT discarded — it becomes the
                // label of the group below.
                .accessibilityHidden(true)
            content
            Spacer(minLength: 0)
        }
        // The caption names the row, so the row is a named group.
        //
        // It used to be hidden outright, on the reasoning that "the control
        // below carries the real label". None of the kit's form controls
        // actually do: `AinkradSegmentedPicker` renders bare buttons, and
        // `AinkradSelect` and `AinkradToggle` carry no label either. The result
        // was a settings pane of anonymous controls — five identical
        // "Alert / Quiet / Off" pickers in a row with nothing to say which
        // source each belonged to.
        //
        // `.contain` rather than `.combine`: the segments and toggles must stay
        // separately focusable and operable. This only gives the group a name.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(caption)
    }
}
