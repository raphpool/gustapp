import SwiftUI

// Enum to represent the possible relative wind directions
enum RelativeWindDirection: String {
    case sideshore = "sideshore"
    case sideOffshore = "side-offshore"
    case sideOnshore = "side-onshore"
    case offshore = "offshore"
    case onshore = "onshore"

    // Translate the direction to a short form
    func translate() -> String {
        switch self {
        case .sideshore:
            return "Side"
        case .sideOffshore:
            return "Side off"
        case .sideOnshore:
            return "Side on"
        case .offshore:
            return "Off"
        case .onshore:
            return "On"
        }
    }
}

struct RelativeDirectionCell: View {
    let relativeDirection: String
    
    var body: some View {
        let translation = RelativeWindDirection(rawValue: relativeDirection)?.translate() ?? relativeDirection
        let isOffshore = translation == "Off"
        
        Text(translation)
            .frame(width: 27, height: 28)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(isOffshore ? Color.red : .black)
            .font(.custom("Inter-Regular", size: 11))
            .border(Color.white, width: 0.5)
            .multilineTextAlignment(.center) // Center align the text horizontally
    }
}

// Preview
struct RelativeDirectionCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RelativeDirectionCell(relativeDirection: "sideshore")
            RelativeDirectionCell(relativeDirection: "offshore")
        }
        .previewLayout(.sizeThatFits)
    }
}
