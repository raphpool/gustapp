import SwiftUI

struct TimestampCell: View {
    let timestamp: String
    private let days = ["Di", "Lu", "Ma", "Me", "Je", "Ve", "Sa"]
    
    var body: some View {
        let localTimestamp = timestamp.replacingOccurrences(of: "Z", with: "")
        if let date = DateFormatter.timestampFormatter.date(from: localTimestamp) {
            let dayIndex = Calendar.current.component(.weekday, from: date) - 1 // Adjust for the array index
            let dayName = days[dayIndex % days.count] // Ensure we stay within the array bounds
            let dayOfMonth = Calendar.current.component(.day, from: date)
            let hour = Calendar.current.component(.hour, from: date)
            
            VStack {
                Text(dayName) // "Lu", "Ma", "Me", ...
                Text(String(dayOfMonth))
                Text("\(hour)h")
            }
            .frame(minWidth: 27, maxWidth: 27, minHeight: 50, maxHeight: 50) // Fixed width for the cell
            .background(getDayBackgroundColor(dayIndex: dayIndex)) // Function to get the background color
            .border(Color.white, width: 0.5)
            .font(.custom("Inter-Regular", size: 12))
        } else {
            Text("Invalid Date")
        }
    }
    
    func getDayBackgroundColor(dayIndex: Int) -> Color {
        // Alternate the background color for each day
        dayIndex % 2 == 0 ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
    }
}

extension DateFormatter {
    static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

// Preview
struct TimestampCell_Previews: PreviewProvider {
    static var previews: some View {
        TimestampCell(timestamp: "2024-01-16T15:00:00.000Z")
            .previewLayout(.sizeThatFits)
    }
}
