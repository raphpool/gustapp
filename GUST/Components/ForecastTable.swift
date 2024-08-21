import SwiftUI
import SwiftUIIntrospect

struct ForecastTable: View {
    var records: [Record]
    var bestWindDirection: [String]
    var lowTide: String
    var midTide: String
    var highTide: String
    @State private var expanded: Bool = false
    var scrollHandler: SimultaneouslyScrollViewHandler
    
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
            .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17, .v18)) { scrollView in
                scrollHandler.addScrollView(scrollView)
            }
        }
    }
}

struct ForecastColumn: View {
    let record: Record
    let bestWindDirection: [String]
    let lowTide: String
    let midTide: String
    let highTide: String
    
    var body: some View {
        VStack(spacing: 0) {
            TimestampCell(timestamp: record.fields.timestamp)
            
            CellContent(content: "\(Int(record.fields.windSpeed))", color: windColor(record.fields.windSpeed))
            CellContent(content: "\(Int(record.fields.windGust))", color: windColor(record.fields.windGust))
            CellContent(content: modelAbbreviation(record.fields.model), color: .gray.opacity(0.2))
            
            WindDirectionCell(degrees: record.fields.windDegrees, bestWindDirection: bestWindDirection)
                .frame(width: 27, height: 28)
            
            RelativeDirectionCell(relativeDirection: record.fields.relativeDirection)
            
            TideCell(description: record.fields.tideDescription ?? "",
                     height: record.fields.tideHeight ?? 0,
                     spotId: record.fields.spotId,
                     lowTide: lowTide, midTide: midTide, highTide: highTide)
            .frame(width: 27, height: 28)
            
            TideExtremeCell(extremeHour: record.fields.extremeHour, extremeType: record.fields.extremeType)
                .frame(width: 27, height: 28)
        }
    }
    
    private func windColor(_ speed: Double) -> Color {
        switch speed {
        case 8...11:
            return Color.blueScale(ceil((speed - 7) / 4 * 10))
        case 12...17:
            return Color.greenScale(ceil((speed - 11) / 6 * 10))
        case 18...24:
            return Color.orangeScale(ceil((speed - 17) / 7 * 10))
        case 25...30:
            return Color.redScale(ceil((speed - 24) / 6 * 10))
        case 31...60:
            return Color.purpleScale(ceil((speed - 30) / 30 * 10))
        default:
            return .clear
        }
    }
    
    private func modelAbbreviation(_ model: String) -> String {
        let modelTranslations: [String: String] = [
            "meteofrance_arome_france_hd": "Ar",
            "meteofrance_arpege_europe": "Arp",
            "gfs_seamless": "Gfs"
        ]
        return modelTranslations[model] ?? model
    }
}

struct CellContent: View {
    let content: String
    let color: Color
    
    var body: some View {
        Text(content)
            .frame(width: 27, height: 28)
            .background(color)
            .foregroundColor(.black)
            .font(.custom("Inter-Regular", size: 11))
            .border(Color.white, width: 0.5)
    }
}
