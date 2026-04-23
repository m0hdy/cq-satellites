import SwiftUI

// MARK: - Stretch Goal: AR Satellite Overlay
// This module will use ARKit + RealityKit to show satellite positions
// in the sky as an augmented reality overlay in landscape mode.
//
// Implementation deferred. When ready:
// 1. Continuous SGP4 propagation for real-time satellite positions
// 2. Convert satellite ECEF → local horizon (az/el)
// 3. RealityKit entities anchored in AR space
// 4. Landscape-only orientation lock

/// Placeholder for the AR satellite tracking view.
struct SatelliteARView: View {
    var body: some View {
        ContentUnavailableView(
            "AR View",
            systemImage: "arkit",
            description: Text("Augmented reality satellite tracking coming soon.")
        )
    }
}
