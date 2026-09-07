import Testing
import Foundation
@testable import AinkradSignal

@Suite("Signal socket path and client")
struct SignalSocketClientTests {
    @Test("the default path is beside the event store, under the bundle id")
    func defaultPath() {
        let url = SignalSocketPath.default(bundleID: "com.example.test")
        #expect(url.lastPathComponent == "signal.sock")
        #expect(url.deletingLastPathComponent().lastPathComponent == "com.example.test")
        #expect(!url.path.hasPrefix("/tmp"), "/tmp is world-writable")
    }

    @Test("the path cap matches what sockaddr_un can actually hold")
    func pathCap() {
        // If this drifts from the struct, one end refuses paths the other
        // truncates, and the socket binds somewhere nobody looks.
        #expect(SignalSocketPath.maxPathBytes == MemoryLayout.size(ofValue: sockaddr_un().sun_path) - 1)
        #expect(SignalSocketPath.maxPathBytes > 90)
    }

    @Test("an overlong path is refused rather than truncated")
    func refusesOverlongPath() {
        let long = URL(fileURLWithPath: "/tmp/" + String(repeating: "d", count: 200) + "/x.sock")
        #expect(throws: SignalSocketClient.SendFailure.pathTooLong(length: long.path.utf8.count)) {
            try SignalSocketClient.send(Data("{}\n".utf8), to: long)
        }
    }

    @Test("sending with nobody listening reports notListening, the ordinary case")
    func notListening() {
        let absent = FileManager.default.temporaryDirectory
            .appendingPathComponent("absent-\(UUID().uuidString.prefix(8)).sock")
        do {
            try SignalSocketClient.send(Data("{}\n".utf8), to: absent)
            Issue.record("expected a failure")
        } catch let failure as SignalSocketClient.SendFailure {
            guard case .notListening = failure else {
                Issue.record("expected .notListening, got \(failure)")
                return
            }
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }
}
