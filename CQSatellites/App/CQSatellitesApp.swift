import SwiftUI

@main
struct CQSatellitesApp: App {
    @State private var store = SatelliteStore()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                PassListView()
                    .environment(store)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(1))
                withAnimation(.easeOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}
