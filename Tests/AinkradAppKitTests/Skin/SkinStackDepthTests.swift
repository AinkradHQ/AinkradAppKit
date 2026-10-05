import Foundation
import Testing

@testable import AinkradAppKitUI

/// Debug builds give every token temporary its own stack slot, so the skin
/// path is deep. The host first touches its theme catalog from whatever
/// thread asks, which can be a 512 KiB Swift Testing or GCD worker.
@Suite("SkinStackDepthTests")
struct SkinStackDepthTests {
    @Test("loading theme files, valid and invalid, completes on a 512 KiB stack thread")
    func loadThemesOnSmallStack() async throws {
        let complete = try JSONEncoder().encode(AinkradSkin.standard)
        var object = try #require(try JSONSerialization.jsonObject(with: complete) as? [String: Any])
        object["id"] = "broken"
        object["palette"] = nil
        let incomplete = try JSONSerialization.data(withJSONObject: object)

        let counts = await withCheckedContinuation { (continuation: CheckedContinuation<(Int, Int), Never>) in
            let thread = Thread {
                let result = ainkradLoadThemes([complete, incomplete])
                continuation.resume(returning: (result.themes.count, result.issues.count))
            }
            thread.stackSize = 512 * 1024
            thread.start()
        }
        #expect(counts.0 == 1)
        #expect(counts.1 == 1)
    }
}
