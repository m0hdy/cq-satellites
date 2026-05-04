import SwiftUI

@main
struct CQSatellitesApp: App {
    @State private var store = SatelliteStore()

    var body: some Scene {
        WindowGroup {
            PassListView()
                .environment(store)
        }
    }
}
