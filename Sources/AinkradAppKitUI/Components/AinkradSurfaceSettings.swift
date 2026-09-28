import SwiftUI
import AinkradAppKitContract

/// The two rows every app shows for how the host surfaces it: **Open as**
/// (pane or overlay) and **Open in** (basic or advanced).
///
/// One component rather than nine copies, so the wording, order and position
/// are the same in every app's settings — and so a change to how either control
/// behaves lands everywhere at once.
///
/// Both are backed by the host's controls (`PluginPresentationControl`,
/// `PluginModeControl`), so the host persists the override and the app keeps no
/// copy of it. The local `@State` mirrors exist only to drive the pickers.
///
/// The two rows honestly describe different timings, because they have them:
/// presentation decides which WINDOW hosts the app and so cannot change one
/// that is already open, while mode is per pane and applies to the next pane.
/// Neither morphs the pane you are looking at, and saying "applies the next
/// time" on both is the truthful version.
public struct AinkradSurfaceSettings: View {
    private let appName: String
    private let presentation: any PluginPresentationControl
    /// `nil` for an app with no basic mode — the row is then omitted entirely
    /// rather than shown disabled. A control that cannot do anything is worse
    /// than no control: it invites the click and then refuses it.
    private let mode: (any PluginModeControl)?
    /// `nil` when the caller has no size control to offer. The row is also
    /// hidden while the app is presented as a PANE — a size that applies to a
    /// surface you are not using is a control that does nothing.
    private let overlaySize: (any PluginOverlaySizeControl)?

    @State private var presentationSelection: PluginPresentation
    @State private var modeSelection: PluginMode
    @State private var sizeSelection: PluginOverlaySize

    public init(appName: String,
                presentation: any PluginPresentationControl,
                mode: (any PluginModeControl)? = nil,
                overlaySize: (any PluginOverlaySizeControl)? = nil) {
        self.appName = appName
        self.presentation = presentation
        self.mode = mode
        self.overlaySize = overlaySize
        _presentationSelection = State(initialValue: presentation.current)
        _modeSelection = State(initialValue: mode?.current ?? .advanced)
        _sizeSelection = State(initialValue: overlaySize?.current ?? .default)
    }

    public var body: some View {
        Group {
            AinkradFormRow(title: "Open as",
                           help: "Applies the next time \(appName) opens.") {
                AinkradSegmentedPicker(items: [PluginPresentation.pane, .overlay],
                                       selection: $presentationSelection) {
                    $0 == .overlay ? "Overlay" : "Pane"
                }
            }
            if mode != nil {
                AinkradFormRow(title: "Open in",
                               help: "Basic shows only what \(appName) is usually opened for. "
                                   + "Applies the next time it opens; you can switch a pane "
                                   + "at any time without changing this.") {
                    AinkradSegmentedPicker(items: [PluginMode.basic, .advanced],
                                           selection: $modeSelection) {
                        $0 == .basic ? "Basic" : "Advanced"
                    }
                }
            }
            if overlaySize != nil, presentationSelection == .overlay {
                AinkradFormRow(title: "Overlay size",
                               help: "How large \(appName) is drawn when it opens as an "
                                   + "overlay. Applies the next time it is summoned.") {
                    AinkradSegmentedPicker(items: PluginOverlaySize.allCases,
                                           selection: $sizeSelection) { $0.title }
                }
            }
        }
        .onChange(of: presentationSelection) { _, new in presentation.set(new) }
        .onChange(of: modeSelection) { _, new in mode?.set(new) }
        .onChange(of: sizeSelection) { _, new in overlaySize?.set(new) }
    }
}
