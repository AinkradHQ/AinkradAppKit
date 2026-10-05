// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — skin storage
import Foundation

extension AinkradSkin {
    /// The skin's stored values. Same names as the public properties, so the
    /// synthesized coding keys — and every theme file — are unchanged.
    struct Fields: Codable, Equatable, Sendable {
        var schemaVersion: Int
        var id: String
        var name: String
        var palette: AinkradSkinPalette
        var shape: AinkradShapeToken
        var spacing: AinkradSpacingTokens
        var radius: AinkradRadiusTokens
        var elevation: AinkradElevationTokens
        var type: AinkradTypeTokens
        var opacity: AinkradOpacityTokens
        var size: AinkradSizeTokens
        var cut: AinkradCutTokens
        var text: AinkradTextTokens
        var syntax: AinkradSyntaxTokens
        var terminal: AinkradTerminalTokens
        var motion: AinkradMotionTokens
        var material: AinkradMaterialTokens
        var roles: AinkradRoleTokens
        var effects: AinkradEffectTokens
        var chrome: AinkradChromeTokens
        var components: AinkradComponentTokens
    }

    final class Box: @unchecked Sendable {
        var fields: Fields
        init(_ fields: Fields) { self.fields = fields }
    }

    /// The box to write through: shared boxes are copied first.
    private mutating func uniqueBox() -> Box {
        if !isKnownUniquelyReferenced(&box) { box = Box(box.fields) }
        return box
    }

    public var schemaVersion: Int {
        get { box.fields.schemaVersion }
        set { uniqueBox().fields.schemaVersion = newValue }
    }
    public var id: String {
        get { box.fields.id }
        set { uniqueBox().fields.id = newValue }
    }
    public var name: String {
        get { box.fields.name }
        set { uniqueBox().fields.name = newValue }
    }
    public var palette: AinkradSkinPalette {
        get { box.fields.palette }
        set { uniqueBox().fields.palette = newValue }
    }
    public var shape: AinkradShapeToken {
        get { box.fields.shape }
        set { uniqueBox().fields.shape = newValue }
    }
    public var spacing: AinkradSpacingTokens {
        get { box.fields.spacing }
        set { uniqueBox().fields.spacing = newValue }
    }
    public var radius: AinkradRadiusTokens {
        get { box.fields.radius }
        set { uniqueBox().fields.radius = newValue }
    }
    public var elevation: AinkradElevationTokens {
        get { box.fields.elevation }
        set { uniqueBox().fields.elevation = newValue }
    }
    public var type: AinkradTypeTokens {
        get { box.fields.type }
        set { uniqueBox().fields.type = newValue }
    }
    public var opacity: AinkradOpacityTokens {
        get { box.fields.opacity }
        set { uniqueBox().fields.opacity = newValue }
    }
    public var size: AinkradSizeTokens {
        get { box.fields.size }
        set { uniqueBox().fields.size = newValue }
    }
    public var cut: AinkradCutTokens {
        get { box.fields.cut }
        set { uniqueBox().fields.cut = newValue }
    }
    public var text: AinkradTextTokens {
        get { box.fields.text }
        set { uniqueBox().fields.text = newValue }
    }
    public var syntax: AinkradSyntaxTokens {
        get { box.fields.syntax }
        set { uniqueBox().fields.syntax = newValue }
    }
    public var terminal: AinkradTerminalTokens {
        get { box.fields.terminal }
        set { uniqueBox().fields.terminal = newValue }
    }
    public var motion: AinkradMotionTokens {
        get { box.fields.motion }
        set { uniqueBox().fields.motion = newValue }
    }
    public var material: AinkradMaterialTokens {
        get { box.fields.material }
        set { uniqueBox().fields.material = newValue }
    }
    public var roles: AinkradRoleTokens {
        get { box.fields.roles }
        set { uniqueBox().fields.roles = newValue }
    }
    public var effects: AinkradEffectTokens {
        get { box.fields.effects }
        set { uniqueBox().fields.effects = newValue }
    }
    public var chrome: AinkradChromeTokens {
        get { box.fields.chrome }
        set { uniqueBox().fields.chrome = newValue }
    }
    var components: AinkradComponentTokens {
        get { box.fields.components }
        set { uniqueBox().fields.components = newValue }
    }

    public init(from decoder: any Decoder) throws {
        self.box = Box(try Fields(from: decoder))
    }

    public func encode(to encoder: any Encoder) throws {
        try box.fields.encode(to: encoder)
    }

    public static func == (lhs: AinkradSkin, rhs: AinkradSkin) -> Bool {
        lhs.box === rhs.box || lhs.box.fields == rhs.box.fields
    }
}
