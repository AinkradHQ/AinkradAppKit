import Foundation
import SwiftUI
// design-lint: allow-file radius-literal,opacity-literal,frame-literal,chamfer-literal,motion-literal theme layer — skin model tests
import Testing

@testable import AinkradAppKitUI

@Suite("SkinModelTests")
@MainActor
struct SkinModelTests {
    @Test("standard JSON round-trip unchanged")
    func jsonRoundTrip() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(AinkradSkin.standard)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AinkradSkin.self, from: data)

        #expect(decoded == AinkradSkin.standard)
    }

    @Test("state precedence: disabled > pressed > selected > focused > hover > rest")
    func statePrecedence() {
        let colorState = AinkradStateColor(
            rest: .hex(1, 0, 0, 1),
            hover: .hex(0, 1, 0, 1),
            pressed: .hex(1, 0, 1, 1),
            selected: .hex(1, 1, 0, 1),
            focused: .hex(0, 0, 1, 1),
            disabled: .hex(0, 1, 1, 1)
        )

        #expect(colorState.resolve([]) == .hex(1, 0, 0, 1))
        #expect(colorState.resolve([AinkradControlState.hover]) == .hex(0, 1, 0, 1))
        #expect(colorState.resolve([.hover, .focused] as AinkradControlState) == .hex(0, 0, 1, 1))
        #expect(colorState.resolve([.hover, .focused, .selected] as AinkradControlState) == .hex(1, 1, 0, 1))
        #expect(colorState.resolve([.hover, .focused, .selected, .pressed] as AinkradControlState) == .hex(1, 0, 1, 1))
        #expect(
            colorState.resolve([.hover, .focused, .selected, .pressed, .disabled] as AinkradControlState)
                == .hex(0, 1, 1, 1))
    }

    @Test("AinkradSkinShape produces identical CGPath to ChamferShape for every cut/corner set used")
    func skinShapePathEquality() {
        let testRect = CGRect(x: 0, y: 0, width: 200, height: 100)

        let cuts: [Double] = [2, 3, 4, 5, 6, 7, 8, 12, 14, 20, 22]
        let cornerCases: [(String?, ChamferCorners)] = [
            ("diagonal", .diagonal),
            ("all", .all),
            ("top", [.topLeft, .topRight]),
            (nil, .diagonal),
        ]

        for cut in cuts {
            for (cornerStr, expectedCorners) in cornerCases {
                let token = AinkradShapeToken(style: "chamfer", cut: cut, corners: cornerStr)
                let skinShape = AinkradSkinShape(token: token)
                let chamferShape = ChamferShape(cut: CGFloat(cut), corners: expectedCorners)

                let skinPath = skinShape.path(in: testRect).cgPath
                let chamferPath = chamferShape.path(in: testRect).cgPath

                #expect(skinPath == chamferPath)
            }
        }
    }

    @Test("component group builders complete on 512 KiB stack thread")
    func componentGroupBuildersStackSize() async throws {
        let builders: [(@Sendable () -> Void)] = [
            { _ = AinkradComponentTokens.makeStandardPart1() },
            { _ = AinkradComponentTokens.makeStandardPart2() },
            { _ = AinkradComponentTokens.makeStandardPart3() },
            { _ = AinkradComponentTokens.makeStandardPart4() },
            { _ = AinkradComponentTokens.makeStandard() },
            { _ = AinkradSkin.standard },
        ]

        let names = ["p1", "p2", "p3", "p4", "makeStandard", "AinkradSkin.standard"]
        for (i, block) in builders.enumerated() {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let thread = Thread {
                    print("--> EXECUTING BUILDER: \(names[i])")
                    fflush(stdout)
                    block()
                    print("<-- DONE BUILDER: \(names[i])")
                    fflush(stdout)
                    continuation.resume()
                }
                thread.stackSize = 512 * 1024
                thread.start()
            }
        }
    }

    @Test("reading AinkradSpacing.xs completes on 512 KiB stack thread")
    func spacingAccessStackSize() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let thread = Thread {
                let xs = AinkradSpacing.xs
                #expect(xs == 4)
                continuation.resume()
            }
            thread.stackSize = 512 * 1024
            thread.start()
        }
    }
}
