import SwiftUI

struct ForecastTableStandalone: View {
    var records: [Record]
    var bestWindDirection: [String]
    var lowTide: String
    var midTide: String
    var highTide: String
    @State private var expanded: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                LabelCell(icon: Image("Calendar"), text: "Heure", expanded: $expanded)
                    .frame(height: 50)
                LabelCell(icon: Image("Wind"), text: "Vitesse", expanded: $expanded)
                LabelCell(icon: Image("Wind"), text: "Rafales", expanded: $expanded)
                LabelCell(icon: Image("Earth"), text: "Modèles", expanded: $expanded)
                LabelCell(icon: Image("Direction"), text: "Direction", expanded: $expanded)
                LabelCell(icon: Image("Direction"), text: "Orientation", expanded: $expanded)
                LabelCell(icon: Image("Wave"), text: "Marée", expanded: $expanded)
                LabelCell(icon: Image("Wave"), text: "Extrêmes", expanded: $expanded)
            }
            .background(Color.gray.opacity(0.2))
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(records, id: \.fields.timestamp) { record in
                        ForecastColumn(
                            record: record,
                            bestWindDirection: bestWindDirection,
                            lowTide: lowTide,
                            midTide: midTide,
                            highTide: highTide
                        )
                    }
                }
            }
        }
    }
}
