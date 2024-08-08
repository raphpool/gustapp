import SwiftUI

struct LabelCell: View {
    var icon: Image
    var text: String
    @Binding var expanded: Bool // State to control expanded/collapsed
    
    var body: some View {
        HStack {
            if expanded {
                Text(text)
                    .transition(.opacity)
            } else {
                icon
                    .resizable()
                    .scaledToFit() // This maintains the aspect ratio
                    .frame(width: 14, height: 28) // Set the icon's frame
                    .foregroundColor(.black) // Set the foreground color to black
            }
        }
        .frame(width: expanded ? 90 : 30)
        .font(.custom("Inter-Regular", size: 12))
        .onTapGesture {
            expanded.toggle()
        }
    }
}

