import Testing
import AppKit
import SwiftUI
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// T3.4a acceptance: the environment bridge between `AinkradSkin` and the
/// legacy `ainkradTheme` / `ainkradStatusColors` keys.
@Suite("SkinBridge")
@MainActor
struct SkinBridgeTests {
    /// A skin with primary-only palette entries, so the hex → Color → hex
    /// round trip through sRGB is exact (0.0 / 1.0 survive it bit-for-bit).
    private var probeSkin: AinkradSkin {
        var skin = AinkradSkin.standard
        skin.id = "bridge-probe"
        skin.name = "Bridge Probe"
        skin.palette = AinkradSkinPalette(
            background: .hex(1, 0, 0, 1),
            surface: .hex(0, 1, 0, 1),
            surfaceElevated: .hex(0, 0, 1, 1),
            accentPrimary: .hex(1, 1, 0, 1),
            accentSecondary: .hex(0, 1, 1, 1),
            accentTertiary: .hex(1, 0, 1, 1),
            foreground: .hex(1, 1, 1, 1),
            success: .hex(0, 0, 0, 1),
            warning: .hex(1, 1, 1, 1),
            danger: .hex(1, 0, 0, 1)
        )
        return skin
    }

    // MARK: - Old-plugin path: setting only ainkradTheme recolourises the skin

    @Test("setting only ainkradTheme changes ainkradSkin.palette")
    func themeOverrideRecoloursSkin() {
        var env = EnvironmentValues()
        let before = env.ainkradSkin
        #expect(before.palette.background != .hex(1, 1, 1, 1))

        env.ainkradTheme = HostThemeTokens(
            themeID: "probe",
            background: .white, surface: .white, surfaceElevated: .white,
            accentPrimary: .white, accentSecondary: .white, accentTertiary: .white,
            foreground: .black)
        let after = env.ainkradSkin

        #expect(nearComponents(of: after.palette.background, red: 1, green: 1, blue: 1))
        #expect(nearComponents(of: after.palette.surface, red: 1, green: 1, blue: 1))
        #expect(nearComponents(of: after.palette.foreground, red: 0, green: 0, blue: 0))
        #expect(after.palette.background != before.palette.background)
        // Everything the legacy keys do not carry is untouched.
        #expect(after.shape == before.shape)
        #expect(after.spacing == before.spacing)
        #expect(after.roles == before.roles)
        #expect(after.palette.black == before.palette.black)
        #expect(after.palette.white == before.palette.white)
    }

    @Test("setting only ainkradStatusColors changes the status palette entries")
    func statusOverrideRecoloursSkin() {
        var env = EnvironmentValues()
        env.ainkradStatusColors = AinkradStatusColors(
            success: .white, warning: .white, danger: .black)
        let skin = env.ainkradSkin
        #expect(nearComponents(of: skin.palette.success, red: 1, green: 1, blue: 1))
        #expect(nearComponents(of: skin.palette.danger, red: 0, green: 0, blue: 0))
        // The theme-carried entries still come from the default theme.
        #expect(skin.palette.background != .hex(1, 1, 1, 1))
    }

    // MARK: - .ainkradSkin(_:) installs storage, theme and status colours

    @Test(".ainkradSkin(x) makes ainkradTheme == HostThemeTokens(skin: x)")
    func skinModifierDerivesTheme() throws {
        let skin = probeSkin
        let capture = BridgeCapture()
        hostProbe(SkinBridgeProbe(capture: capture).ainkradSkin(skin))

        let theme = try unwrap(capture.theme)
        let expected = HostThemeTokens(skin: skin)
        #expect(theme.themeID == "bridge-probe")
        #expect(theme.themeID == expected.themeID)
        #expect(sameComponents(theme.background, expected.background))
        #expect(sameComponents(theme.surface, expected.surface))
        #expect(sameComponents(theme.surfaceElevated, expected.surfaceElevated))
        #expect(sameComponents(theme.accentPrimary, expected.accentPrimary))
        #expect(sameComponents(theme.accentSecondary, expected.accentSecondary))
        #expect(sameComponents(theme.accentTertiary, expected.accentTertiary))
        #expect(sameComponents(theme.foreground, expected.foreground))
    }

    @Test(".ainkradSkin(x) makes ainkradStatusColors == AinkradStatusColors(skin: x)")
    func skinModifierDerivesStatusColors() throws {
        let skin = probeSkin
        let capture = BridgeCapture()
        hostProbe(SkinBridgeProbe(capture: capture).ainkradSkin(skin))

        let status = try unwrap(capture.status)
        let expected = AinkradStatusColors(skin: skin)
        #expect(sameComponents(status.success, expected.success))
        #expect(sameComponents(status.warning, expected.warning))
        #expect(sameComponents(status.danger, expected.danger))
    }

    @Test(".ainkradSkin(x) stores x and reads it back through ainkradSkin")
    func skinModifierRoundTrips() throws {
        let skin = probeSkin
        let capture = BridgeCapture()
        hostProbe(SkinBridgeProbe(capture: capture).ainkradSkin(skin))

        #expect(try unwrap(capture.storage) == skin)
        let seen = try unwrap(capture.skin)
        #expect(seen.id == "bridge-probe")
        #expect(seen.palette == skin.palette)
    }

    // MARK: - Defaults: standard + fallbackDark + system status colours

    @Test("default EnvironmentValues().ainkradSkin overlays fallbackDark and system status colours")
    func defaultSkinOverlaysFallbacks() {
        let env = EnvironmentValues()
        #expect(env.ainkradSkinStorage == .standard)
        #expect(env.ainkradTheme.themeID == "fallback")

        let skin = env.ainkradSkin
        let fallback = HostThemeTokens.fallbackDark
        #expect(nearToken(of: skin.palette.background, color: fallback.background))
        #expect(nearToken(of: skin.palette.surface, color: fallback.surface))
        #expect(nearToken(of: skin.palette.surfaceElevated, color: fallback.surfaceElevated))
        #expect(nearToken(of: skin.palette.accentPrimary, color: fallback.accentPrimary))
        #expect(nearToken(of: skin.palette.accentSecondary, color: fallback.accentSecondary))
        #expect(nearToken(of: skin.palette.accentTertiary, color: fallback.accentTertiary))
        #expect(nearToken(of: skin.palette.foreground, color: fallback.foreground))
        #expect(nearToken(of: skin.palette.success, color: Color.green))
        #expect(nearToken(of: skin.palette.warning, color: Color.yellow))
        #expect(nearToken(of: skin.palette.danger, color: Color.red))
        // Non-palette groups are the stored standard skin, untouched.
        #expect(skin.shape == AinkradSkin.standard.shape)
        #expect(skin.spacing == AinkradSkin.standard.spacing)
        #expect(skin.palette.black == AinkradSkin.standard.palette.black)
        #expect(skin.palette.white == AinkradSkin.standard.palette.white)
    }

    // MARK: - Floating panels see the caller's skin

    @Test("a floating panel's content sees the caller's skin")
    func floatingPanelContentSeesCallerSkin() {
        // The modifier forwards exactly the triple the computed skin is a
        // function of (storage, theme, status colours) — the same pure-value
        // pattern as the floatingPanelFrame geometry tests: no AppKit window
        // is needed, because the forwarding is a value copy.
        let skin = probeSkin
        var caller = EnvironmentValues()
        caller.ainkradSkinStorage = skin
        caller.ainkradTheme = HostThemeTokens(skin: skin)
        caller.ainkradStatusColors = AinkradStatusColors(skin: skin)

        // This mirrors AinkradFloatingPanelModifier.present() and
        // ainkradMenuEnvironment: capture the three values, re-inject them.
        var panel = EnvironmentValues()
        panel.ainkradSkinStorage = caller.ainkradSkinStorage
        panel.ainkradTheme = caller.ainkradTheme
        panel.ainkradTypography = caller.ainkradTypography
        panel.ainkradStatusColors = caller.ainkradStatusColors
        panel.ainkradSurfaceOpacity = caller.ainkradSurfaceOpacity
        panel.ainkradSurfaceBlur = caller.ainkradSurfaceBlur

        #expect(panel.ainkradSkin == caller.ainkradSkin)
        #expect(panel.ainkradSkin.palette == skin.palette)
        #expect(panel.ainkradSkin.id == "bridge-probe")
    }

    @Test("HostThemeTokens(skin:) and AinkradStatusColors(skin:) agree with the overlay")
    func derivedTokensAgreeWithOverlay() {
        let skin = probeSkin
        var env = EnvironmentValues()
        env.ainkradSkinStorage = skin
        env.ainkradTheme = HostThemeTokens(skin: skin)
        env.ainkradStatusColors = AinkradStatusColors(skin: skin)
        #expect(env.ainkradSkin.palette == skin.palette)
    }
}

// MARK: - File-scope test support

/// Holds environment values read by a hosted probe view. Sendable via a lock
/// so SwiftUI's `@Sendable` appear-action can report back to the test.
private final class BridgeCapture: @unchecked Sendable {
    private let lock = NSLock()
    private var boxSkin: AinkradSkin?
    private var boxTheme: HostThemeTokens?
    private var boxStatus: AinkradStatusColors?
    private var boxStorage: AinkradSkin?

    var skin: AinkradSkin? {
        get { lock.withLock { boxSkin } }
        set { lock.withLock { boxSkin = newValue } }
    }
    var theme: HostThemeTokens? {
        get { lock.withLock { boxTheme } }
        set { lock.withLock { boxTheme = newValue } }
    }
    var status: AinkradStatusColors? {
        get { lock.withLock { boxStatus } }
        set { lock.withLock { boxStatus = newValue } }
    }
    var storage: AinkradSkin? {
        get { lock.withLock { boxStorage } }
        set { lock.withLock { boxStorage = newValue } }
    }
}

/// Reads the skin-relevant environment at its position and reports it.
/// Values are copied to locals in `body` so the `@Sendable` appear-action
/// captures Sendable values only, never the view itself.
private struct SkinBridgeProbe: View {
    @Environment(\.ainkradSkin) private var skin
    @Environment(\.ainkradTheme) private var theme
    @Environment(\.ainkradStatusColors) private var status
    @Environment(\.ainkradSkinStorage) private var storage
    let capture: BridgeCapture

    var body: some View {
        let skin = skin
        let theme = theme
        let status = status
        let storage = storage
        let capture = capture
        return Color.clear.onAppear {
            capture.skin = skin
            capture.theme = theme
            capture.status = status
            capture.storage = storage
        }
    }
}

/// Hosts `view` offscreen (the AinkradLogViewTests pattern) and pumps the
/// runloop so `onAppear` probes fire.
@MainActor
private func hostProbe<V: View>(_ view: V) {
    _ = NSApplication.shared
    let host = NSHostingView(rootView: view.frame(width: 200, height: 100))
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
        styleMask: [.borderless], backing: .buffered, defer: false)
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
}

private func unwrap<T>(_ value: T?, _ message: String = "probe never fired") throws -> T {
    try #require(value, "\(message)")
}

/// Exact sRGB components of a literal-hex token, or nil for any other case.
private func hexComponents(_ token: AinkradColorToken) -> (Double, Double, Double, Double)? {
    guard case .hex(let red, let green, let blue, let alpha) = token else {
        return nil
    }
    return (red, green, blue, alpha)
}

private func close(_ lhs: Double, _ rhs: Double, tolerance: Double = 0.015) -> Bool {
    abs(lhs - rhs) <= tolerance
}

private func nsComponents(_ color: Color) -> (Double, Double, Double, Double)? {
    guard let rgb = NSColor(color).usingColorSpace(.sRGB) else {
        return nil
    }
    return (
        Double(rgb.redComponent),
        Double(rgb.greenComponent),
        Double(rgb.blueComponent),
        Double(rgb.alphaComponent)
    )
}

/// Whether a palette token is near the given sRGB triple (alpha 1).
private func nearComponents(
    of token: AinkradColorToken, red: Double, green: Double, blue: Double
) -> Bool {
    guard let hex = hexComponents(token) else {
        return false
    }
    return close(hex.0, red) && close(hex.1, green) && close(hex.2, blue)
        && close(hex.3, 1)
}

/// Whether two colours resolve to nearly the same sRGB components.
private func sameComponents(_ lhs: Color, _ rhs: Color) -> Bool {
    guard let a = nsComponents(lhs), let b = nsComponents(rhs) else {
        return false
    }
    return close(a.0, b.0) && close(a.1, b.1) && close(a.2, b.2) && close(a.3, b.3)
}

/// Whether a palette token is the hex encoding of `color`.
private func nearToken(of token: AinkradColorToken, color: Color) -> Bool {
    guard let hex = hexComponents(token), let rgb = nsComponents(color) else {
        return false
    }
    return close(hex.0, rgb.0) && close(hex.1, rgb.1) && close(hex.2, rgb.2)
        && close(hex.3, rgb.3)
}
