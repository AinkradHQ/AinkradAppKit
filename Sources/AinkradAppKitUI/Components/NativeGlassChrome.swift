// design-lint: allow-file radius-literal,frame-literal,opacity-literal,raw-color native macOS field metrics and system colours under Glass Native
import AppKit
import SwiftUI

/// The bezel a native macOS editor wears under Glass Native: the system text
/// background, a hairline, and the accent focus ring. Fields are content, not
/// controls, so they stay opaque rather than glass (Apple's layering rule).
struct NativeFieldChrome: ViewModifier {
    let focused: Bool
    let accent: Color

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        content
            .background(Color(nsColor: .textBackgroundColor), in: shape)
            .overlay(
                shape.strokeBorder(
                    focused ? accent.opacity(0.7) : Color(nsColor: .separatorColor), lineWidth: focused ? 2 : 1))
    }
}

extension View {
    func nativeFieldChrome(focused: Bool, accent: Color) -> some View {
        modifier(NativeFieldChrome(focused: focused, accent: accent))
    }
}

/// A picker panel's chrome: Neon's popover fill, stroke and shadow, or under
/// Glass Native (macOS 26+) a glass panel like a system menu. Reads the skin
/// from the environment so the large struct is never copied into the modifier.
struct PopoverChrome: ViewModifier {
    @Environment(\.ainkradSkin) private var skin

    func body(content: Content) -> some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            content.glassEffect(.regular, in: .rect(cornerRadius: 12))
        } else {
            let popover = skin.roles.popover
            let shape = AinkradSkinShape(token: popover.shape)
            content
                .background(shape.fill(skin.color(popover.fill)))
                .overlay(
                    shape.strokeBorder(skin.color(popover.stroke.color), lineWidth: popover.stroke.width.resolve([]))
                )
                .shadow(color: skin.color(popover.shadow.color), radius: popover.shadow.radius, y: popover.shadow.y)
        }
    }
}

/// A picker row's hover/highlight background: the kit's `kit` fill, or under
/// Glass Native the system menu highlight (an accent rounded rectangle).
@ViewBuilder
func optionRowBackground(native: Bool, highlighted: Bool, accent: Color, kit: some View) -> some View {
    if native {
        RoundedRectangle(cornerRadius: 6, style: .continuous).fill(highlighted ? accent : .clear)
    } else {
        kit
    }
}

/// The selected-row marker: Neon's diamond, a menu checkmark under Glass Native.
func optionSelectedGlyph(native: Bool) -> String { native ? "checkmark" : "diamond.fill" }

/// A select's trigger under Glass Native: Apple's pop-up button look — a
/// glass capsule with the value and the up/down chevrons.
@available(macOS 26, *)
struct NativePopUpButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AinkradSpacing.sm) {
                Text(title).lineLimit(1)
                Spacer(minLength: AinkradSpacing.sm)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}

/// A panel's search field: the kit's own chrome, or Apple's rounded field
/// under Glass Native.
struct PanelSearchChrome: ViewModifier {
    @Environment(\.ainkradSkin) private var skin

    func body(content: Content) -> some View {
        if #available(macOS 26, *), skin.usesNativeGlass {
            content.textFieldStyle(.roundedBorder)
        } else {
            let panelSearch = skin.roles.panelSearch
            let searchShape = AinkradSkinShape(token: panelSearch.shape)
            content
                .textFieldStyle(.plain)
                .padding(.horizontal, skin.spacing.sm)
                .padding(.vertical, panelSearch.paddingV)
                .background(searchShape.fill(skin.color(panelSearch.fill)))
                .overlay(
                    searchShape.strokeBorder(
                        skin.color(panelSearch.stroke.color), lineWidth: panelSearch.stroke.width.resolve([])))
        }
    }
}

/// The macOS selection look for a row, rail tile or list item under Glass
/// Native: an accent rounded fill when selected, a quiet system fill on hover.
struct NativeSelectionBackground: View {
    let isSelected: Bool
    let isHovered: Bool
    let accent: Color
    var cornerRadius: CGFloat = 8

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if isSelected {
            shape.fill(accent)
        } else if isHovered {
            shape.fill(.quaternary)
        } else {
            shape.fill(.clear)
        }
    }
}
