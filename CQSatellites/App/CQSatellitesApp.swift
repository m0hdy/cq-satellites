import SwiftUI

@main
struct CQSatellitesApp: App {
    @State private var store = SatelliteStore()
    @State private var showSplash = true
    @State private var splashFinished = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if splashFinished {
                    PassListView()
                        .environment(store)
                        .transition(.opacity)
                }

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .task {
                // Hold splash for enough time to see the animated logo
                try? await Task.sleep(for: .seconds(2))

                // Reveal the main content underneath before fading splash
                withAnimation(.easeOut(duration: 0.1)) {
                    splashFinished = true
                }

                // Fade out the splash
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}
