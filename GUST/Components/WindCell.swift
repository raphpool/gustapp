import SwiftUI

enum WindValue {
    case speed(Double)
    case gust(Double)
    
    // Computed property to extract the double value
    var value: Double {
        switch self {
        case .speed(let speed):
            return speed
        case .gust(let gust):
            return gust
        }
    }
}

struct WindCell: View {
    let windValue: WindValue

    var body: some View {
            Text("\(windValue.value, specifier: "%.0f")")
                .frame(width: 27, height: 28)
                .background(backgroundColor(for: windValue.value))
                .foregroundColor(.black)
                .font(.custom(windValue.value >= 12 ? "Inter-Regular_SemiBold" : "Inter-Regular", size: 12))
                .border(Color.white, width: 0.5)
        }
    
    private func backgroundColor(for windSpeed: Double) -> Color {
        switch windSpeed {
        case 8...11:
            return Color.blueScale(ceil((windSpeed - 7) / 4 * 10))
        case 12...17:
            return Color.greenScale(ceil((windSpeed - 11) / 6 * 10))
        case 18...24:
            return Color.orangeScale(ceil((windSpeed - 17) / 7 * 10))
        case 25...30:
            return Color.redScale(ceil((windSpeed - 24) / 6 * 10))
        case 31...60:
            return Color.purpleScale(ceil((windSpeed - 30) / 30 * 10))
        default:
            return .clear
        }
    }
}

// Define Color extensions to handle scales
extension Color {
    static func blueScale(_ intensity: Double) -> Color {
        Color(red: 0, green: 224/255, blue: 255/255, opacity: intensity / 10)
    }
    
    static func greenScale(_ intensity: Double) -> Color {
        Color(red: 0, green: 255/255, blue: 71/255, opacity: 0.5 + intensity / 20)
    }
    
    static func orangeScale(_ intensity: Double) -> Color {
        Color(red: 255/255, green: 107/255, blue: 0, opacity: 0.6 + intensity / 20)
    }
    
    static func redScale(_ intensity: Double) -> Color {
        Color(red: 255/255, green: 59/255, blue: 48/255, opacity: 0.7 + intensity / 30)
    }
    
    static func purpleScale(_ intensity: Double) -> Color {
        Color(red: 255/255, green: 48/255, blue: 135/255, opacity: 0.8 + intensity / 20)
    }
}

// Preview
struct WindCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WindCell(windValue: .speed(9))
            WindCell(windValue: .gust(13))
            WindCell(windValue: .speed(19))
            WindCell(windValue: .gust(26))
            WindCell(windValue: .speed(35))
        }
        .previewLayout(.sizeThatFits)
    }
}
