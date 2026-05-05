import SwiftUI

/// Splash screen displayed at launch showing the app icon and title.
struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image("ISSIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text("CQ Satellites")
                .font(.title)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
