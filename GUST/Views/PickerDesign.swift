import SwiftUI

struct PNGFilesScrollView: View {
    var pngFiles: [PNGFile]
    var onPNGFileTap: (PNGFile) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(groupedPNGFiles, id: \.0) { (date, files) in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(formatDay(date))
                            .font(.custom("Inter", size: 16).weight(.medium))
                            .foregroundColor(Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.6))
                            .padding(.horizontal, 8)
                        
                        HStack(spacing: 8) {
                            ForEach(files.sorted(by: { fileDate($0) < fileDate($1) }), id: \.fullName) { pngFile in
                                Button(action: {
                                    onPNGFileTap(pngFile)
                                }) {
                                    Text(formatTime(pngFile))
                                        .font(.custom("Inter", size: 16).weight(.medium))
                                        .padding(12)
                                        .background(Color(red: 0/255, green: 122/255, blue: 255/255).opacity(0.12))
                                        .foregroundColor(.blue)
                                        .cornerRadius(100)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private var groupedPNGFiles: [(Date, [PNGFile])] {
        let grouped = Dictionary(grouping: pngFiles) { pngFile -> Date in
            let date = fileDate(pngFile)
            return Calendar.current.startOfDay(for: date)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE dd MMM"
        return formatter.string(from: date).capitalized
    }
    
    private func formatTime(_ pngFile: PNGFile) -> String {
        return String(pngFile.displayName.suffix(4).prefix(2)) + "h"
    }
    
    private func fileDate(_ pngFile: PNGFile) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HHmm"
        if let dateString = pngFile.fullName.split(separator: "/").last?.dropLast(4),
           let date = dateFormatter.date(from: String(dateString)) {
            return date
        }
        return Date()
    }
}



struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Preview provider
struct PNGFilesScrollView_Previews: PreviewProvider {
    static var previews: some View {
        PNGFilesScrollView(
            pngFiles: PNGFile.sampleData,
            onPNGFileTap: { pngFile in
                print("PNG file tapped:", pngFile.displayName)
            }
        )
    }
}

extension PNGFile {
    static var sampleData: [PNGFile] {
        [
            PNGFile(fullName: "processed/2024-03-05T1000.png"),
            PNGFile(fullName: "processed/2024-03-07T0900.png"),
            PNGFile(fullName: "processed/2024-03-05T1100.png"),
            PNGFile(fullName: "processed/2024-03-05T1200.png"),
            PNGFile(fullName: "processed/2024-03-06T0800.png"),
            PNGFile(fullName: "processed/2024-03-06T0900.png"),
            PNGFile(fullName: "processed/2024-03-06T1000.png")
        ]
    }
}

