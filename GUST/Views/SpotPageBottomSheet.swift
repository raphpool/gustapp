import SwiftUI

struct SpotDetailBottomSheet: View {
    let kiteSpot: KiteSpotFields
    
    init(kiteSpot: KiteSpotFields) {
        self.kiteSpot = kiteSpot
        print("SpotDetailBottomSheet initialized with spot: \(kiteSpot.spotName ?? "Unknown")")
    }
    
    var body: some View {
        SpotPage(kiteSpot: kiteSpot)
            .onAppear {
                print("SpotDetailBottomSheet appeared with spot: \(kiteSpot.spotName ?? "Unknown")")
            }
    }
}
