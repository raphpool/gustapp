//import SwiftUI
//
//struct SpotDetailBottomSheet: View {
//    let kiteSpot: KiteSpotFields
//    let records: [Record]
//    let scrollHandler: SimultaneouslyScrollViewHandler
//    
//    init(kiteSpot: KiteSpotFields, records: [Record], scrollHandler: SimultaneouslyScrollViewHandler) {
//        self.kiteSpot = kiteSpot
//        self.records = records
//        self.scrollHandler = scrollHandler
//        print("SpotDetailBottomSheet initialized with spot: \(kiteSpot.spotName ?? "Unknown")")
//    }
//    
//    var body: some View {
//        SpotPage(kiteSpot: kiteSpot, records: records, scrollHandler: scrollHandler)
//            .onAppear {
//                print("SpotDetailBottomSheet appeared with spot: \(kiteSpot.spotName ?? "Unknown")")
//            }
//    }
//}
