import SwiftUI
import Testing

@testable import AinkradAppKitUI

@Suite("AinkradBrandChevron")
struct AinkradBrandMarkTests {
    @Test("path is the Emblem chevron geometry")
    func pathGeometry() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let path = AinkradBrandChevron().path(in: rect)
        #expect(path.boundingRect == rect)
        #expect(path.contains(CGPoint(x: 50, y: 10)))
        #expect(!path.contains(CGPoint(x: 50, y: 49)))  // the bottom notch
    }
}
