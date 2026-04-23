import SwiftUI

@main
struct SatPassApp: App {
    @State private var store = SatelliteStore()

    var body: some Scene {
        WindowGroup {
            PassListView()
                .environment(store)
        }
    }
}
