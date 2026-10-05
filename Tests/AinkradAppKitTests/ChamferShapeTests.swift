import CoreGraphics
import Testing

@testable import AinkradAppKit
@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

@Suite("ChamferShape")
struct ChamferShapeTests {
    @Test("all-corners chamfer yields 8 points for a rect")
    func eightPoints() {
        let pts = chamferPoints(in: CGRect(x: 0, y: 0, width: 100, height: 60), cut: 10, corners: .all)
        #expect(pts.count == 8)
    }
    @Test("no corners yields the 4 rect corners")
    func fourPoints() {
        let pts = chamferPoints(in: CGRect(x: 0, y: 0, width: 100, height: 60), cut: 10, corners: [])
        #expect(pts.count == 4)
    }
}
