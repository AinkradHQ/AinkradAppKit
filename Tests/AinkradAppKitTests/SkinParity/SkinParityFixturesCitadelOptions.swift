import SwiftUI

@testable import AinkradAppKitContract
@testable import AinkradAppKitUI

/// The third Citadel round: options on existing components, with the data of
/// the Citadel mockups (home 02, org 03, run 05, cost 09).
@MainActor
enum SkinParityFixturesCitadelOptions {
    static var fixtures: [SkinParityFixture] {
        [
            // Org 03: a department card holding team cards. Under Glass the inner cards draw no fill of
            // their own, so the layers do not stack lighter.
            SkinParityFixture(
                name: "card-nested",
                view: AnyView(
                    AinkradCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Engineering").font(.headline)
                            HStack(spacing: 10) {
                                AinkradCard { Text("Citadel Core").frame(maxWidth: .infinity, alignment: .leading) }
                                AinkradCard { Text("Mac Client").frame(maxWidth: .infinity, alignment: .leading) }
                            }
                        }
                    }.frame(width: 340)),
                sweepSize: CGSize(width: 400, height: 200))
        ]
    }
}
