import SwiftUI

let windDirections = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]

func degreesToDirection(_ degrees: Int) -> String {
    let normalizedDegrees = ((degrees % 360) + 360) % 360
    let index = Int(round(Double(normalizedDegrees) / 22.5)) % 16
    return windDirections[index]
}

struct WindDirectionCell: View {
    var degrees: Int
    var bestWindDirection: [String]
    
    private var directionString: String {
        degreesToDirection(degrees)
    }
    
    private var isBestWindDirection: Bool {
        bestWindDirection.contains(directionString)
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 27, height: 28)
                .border(Color.white, width: 0.5)
            
            Image("Arrow")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .rotationEffect(.degrees(Double(degrees) - 90))
                .foregroundColor(isBestWindDirection ? .green : .black)
        }
    }
}

struct WindDirectionCell_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            VStack {
                WindDirectionCell(degrees: 45, bestWindDirection: ["NE", "E"])
                Text("Best Wind Direction\n(Green Arrow)")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            VStack {
                WindDirectionCell(degrees: 180, bestWindDirection: ["NE", "E"])
                Text("Not Best Wind Direction\n(Black Arrow)")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

