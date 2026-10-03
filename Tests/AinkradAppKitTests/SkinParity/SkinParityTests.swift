import Foundation
import Testing
import AppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("SkinParityTests")
struct SkinParityTests {
    @Test("all catalogue §6 fixtures match goldens or record when SKIN_GOLDEN_RECORD=1")
    @MainActor
    func verifyOrRecordGoldens() throws {
        let isRecording = ProcessInfo.processInfo.environment["SKIN_GOLDEN_RECORD"] == "1"

        // Locate Goldens directory within package bundle / source directory
        let sourceFile = URL(fileURLWithPath: #filePath)
        let goldensDir = sourceFile.deletingLastPathComponent().appendingPathComponent("Goldens")

        if isRecording {
            try FileManager.default.createDirectory(at: goldensDir, withIntermediateDirectories: true)
        }

        for fixture in SkinParityFixtures.allFixtures {
            guard let rep = SkinParityRenderer.render(fixture.view) else {
                Issue.record("Failed to render fixture \(fixture.name)")
                continue
            }

            guard let pngData = rep.representation(using: .png, properties: [:]) else {
                Issue.record("Failed to encode PNG for fixture \(fixture.name)")
                continue
            }

            let goldenURL = goldensDir.appendingPathComponent("\(fixture.name).png")

            if isRecording {
                try pngData.write(to: goldenURL)
            } else {
                guard FileManager.default.fileExists(atPath: goldenURL.path) else {
                    Issue.record("Golden missing for \(fixture.name) at \(goldenURL.path)")
                    continue
                }
                let goldenData = try Data(contentsOf: goldenURL)
                #expect(pngData == goldenData, "Fixture \(fixture.name) rendered image differs from golden record")
            }
        }
    }
}
