import SwiftUI

func degreesToDirection(degrees: Double) -> String {
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"]
    let index = Int((degrees + 11.25) / 22.5) % 16
    return directions[index]
}


struct WindDirectionCell: View {
    var degrees: Double
    var bestWindDirection: [String]

    var body: some View {
        let directionString = degreesToDirection(degrees: degrees)
        let isBestWindDirection = bestWindDirection.contains(directionString)
        
        Image("Arrow") // Make sure this is the correct system name or your asset name.
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 16, height: 16)
            .border(Color.white, width: 0.5)
            .rotationEffect(.degrees(degrees))
            .foregroundColor(isBestWindDirection ? .green : .black)
    }
}

struct WindDirectionCell_Previews: PreviewProvider {
    static var previews: some View {
            WindDirectionCell(degrees: 45, bestWindDirection: ["NE"])
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Best Wind Direction (Green Arrow)")
    }
}


