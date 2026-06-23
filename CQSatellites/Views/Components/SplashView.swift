import SwiftUI

/// Splash screen displayed at launch showing the app icon and title.
/// Animates in, holds briefly, then signals completion via the binding.
struct SplashView: View {
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            Image("ISSIcon")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 120, height: 120)
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
                .foregroundStyle(.blue)

            Text("CQ Satellites")
                .font(.title)
                .fontWeight(.semibold)
                .opacity(titleOpacity)

            Text("by M0HDY")
                .font(.caption)
                .opacity(subtitleOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                logoOpacity = 1
                logoScale = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                titleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                subtitleOpacity = 1
            }
        }
    }
}
