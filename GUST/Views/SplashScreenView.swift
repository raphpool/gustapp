import SwiftUI

struct SplashScreenView: View {
    
    var body: some View {
        ZStack {
            Color.black
            VStack {
                Image("SplashScreen")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        .ignoresSafeArea()
    }
}
