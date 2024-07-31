import SwiftUI

struct TideExtremeCell: View {
    var extremeHour: String?
    var extremeType: String?

    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 27, height: 28)
            
            VStack {
                if extremeType == "Low" {
                    Spacer()
                }
                Text(extremeHour ?? "")
                    .font(.custom("Inter-Regular", size: 11))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false) // Allow text to overflow horizontally
                if extremeType == "High" {
                    Spacer()
                }
            }
            .frame(width: 27, height: 28)
        }
        .overlay(
            VStack {
                Rectangle().frame(height: 0.5).foregroundColor(.white)
                Spacer()
                Rectangle().frame(height: 0.5).foregroundColor(.white)
            }
        )
    }
}

struct TideExtremeCell_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            TideExtremeCell(extremeHour: "14:00", extremeType: "Low")
            TideExtremeCell(extremeHour: "02:00", extremeType: "High")
        }
        .previewLayout(.sizeThatFits)
    }
}
