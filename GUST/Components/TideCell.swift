import SwiftUI

struct TideCell: View {
    let description: String
    let height: Double
    let spotId: String
    let lowTide: String
    let midTide: String
    let highTide: String
    
    var body: some View {
        let tidePracticable = practicableTide(for: description)
        
        // Assuming `TidesView` is your destination view
        NavigationLink(destination: TidesView(spotId: spotId)) {
            Text(capitalizeFirstLetter(string: description))
                .frame(width: 27, height:28) // Fixed width like in your React component
                .font(.custom("Inter-Regular", size: 11))
                .foregroundColor(tidePracticable == "No" ? Color.red : Color.black)
                .border(Color.white, width: 0.5)
        }
    }
    
    private func capitalizeFirstLetter(string: String) -> String {
        return string.prefix(1).uppercased() + string.dropFirst()
    }
    
    private func practicableTide(for description: String) -> String {
        switch description {
        case "low":
            return lowTide
        case "mid":
            return midTide
        case "high":
            return highTide
        default:
            return ""
        }
    }
}

struct TidesView: View {
    let spotId: String
    
    var body: some View {
        Text("Tides for spot \(spotId)")
        // Your tides view content goes here
    }
}

struct TideCell_Previews: PreviewProvider {
    static var previews: some View {
        TideCell(description: "high", height: 1.5, spotId: "1", lowTide: "Yes", midTide: "Yes", highTide: "No")
            .previewLayout(.sizeThatFits)
    }
}
