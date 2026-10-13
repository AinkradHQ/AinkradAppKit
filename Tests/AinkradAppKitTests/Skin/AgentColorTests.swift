import Foundation
import Testing

@testable import AinkradAppKitUI

@Suite("AgentColorTests")
@MainActor
struct AgentColorTests {
    private func hex(_ r: Double, _ g: Double, _ b: Double) -> AinkradColorToken {
        .hex(r / 255.0, g / 255.0, b / 255.0, 1.0)
    }

    @Test("harness and CLI names map to agents, anything else is unknown")
    func identifiers() {
        #expect(AinkradAgent(identifier: "claude") == .claude)
        #expect(AinkradAgent(identifier: "Claude Code") == .claude)
        #expect(AinkradAgent(identifier: "claude-code") == .claude)
        #expect(AinkradAgent(identifier: "Codex") == .codex)
        #expect(AinkradAgent(identifier: "OpenCode") == .opencode)
        #expect(AinkradAgent(identifier: "open-code") == .opencode)
        #expect(AinkradAgent(identifier: "agy") == .agy)
        #expect(AinkradAgent(identifier: "Antigravity") == .agy)
        #expect(AinkradAgent(identifier: "gemini") == .unknown)
        #expect(AinkradAgent(identifier: "") == .unknown)
    }

    @Test("Neon uses the mockup badge tints, Glass the brand hues")
    func tokens() {
        #expect(AinkradAgent.claude.colorToken(glass: false) == hex(0xE3, 0xA0, 0x7F))
        #expect(AinkradAgent.claude.colorToken(glass: true) == hex(0xCC, 0x78, 0x5C))
        #expect(AinkradAgent.agy.colorToken(glass: false) == hex(0x93, 0xC5, 0xFD))
        #expect(AinkradAgent.codex.colorToken(glass: true) == .palette("foreground", 0.85))
        // Every known agent differs between the two looks; unknown is neutral in both.
        for agent in AinkradAgent.allCases where agent != .unknown {
            #expect(agent.colorToken(glass: false) != agent.colorToken(glass: true))
        }
        #expect(AinkradAgent.unknown.colorToken(glass: false) == .palette("foreground", 0.55))
        #expect(AinkradAgent.unknown.colorToken(glass: true) == .palette("foreground", 0.55))
    }

    @Test("the skin resolves Neon values on the standard skin and Glass values on a glass one")
    func skinResolves() throws {
        let neon = AinkradSkin.standard
        #expect(neon.agentColor(.claude) == neon.color(AinkradAgent.claude.colorToken(glass: false)))
        let base = try JSONEncoder().encode(AinkradSkin.standard)
        let json = #"{"schemaVersion":1,"id":"g","name":"G","base":"neonBlue","material":{"kind":"glass"}}"#
        let glass = try #require(ainkradLoadThemes([base, Data(json.utf8)]).themes["g"]).skin
        #expect(glass.agentColor(.claude) == glass.color(AinkradAgent.claude.colorToken(glass: true)))
        #expect(glass.agentColor(.unknown) == glass.color(.palette("foreground", 0.55)))
    }
}
