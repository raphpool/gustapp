import SwiftUI

struct SpinningImage: View {
    @State private var isSpinning = false
    
    var body: some View {
        Image("GustSpinner")
            .resizable() // Make the image resizable
            .aspectRatio(contentMode: .fit) // Maintain the aspect ratio of the image
            .frame(width: 30) // Sets the width to 50 points and height scales automatically
            .rotationEffect(Angle(degrees: self.isSpinning ? 360 : 0)) // Rotate the image
            .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isSpinning)
            .onAppear() {
                self.isSpinning = true // Start the animation when the view appears
            }
    }
}
