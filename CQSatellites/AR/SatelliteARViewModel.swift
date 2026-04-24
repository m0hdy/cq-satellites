import Foundation

/// Manages real-time satellite position updates for the AR overlay.
///
/// Runs a 10Hz update loop that propagates SGP4 positions for all target
/// satellites and other visible satellites, publishing results for SwiftUI/RealityKit.
/// Supports both single-satellite mode (from detail view) and multi-satellite mode
/// (from list view with up to 5 targets).
@MainActor @Observable
final class SatelliteARViewModel {

    // MARK: - Input

    let targetPasses: [SatellitePass]

    // MARK: - Computed Positions

    /// Positions for all target satellites (rendered as green markers).
    private(set) var targetPositions: [(pass: SatellitePass, position: SatellitePosition)] = []
    /// Other visible satellites above the horizon (rendered as blue markers).
    private(set) var visibleSatellites: [(name: String, noradID: String, position: SatellitePosition, pass: SatellitePass?)] = []

    // MARK: - State

    private(set) var isTracking = false
    var arSessionError: String?

    /// Set of NORAD IDs for all target satellites (for fast lookup).
    var targetNoradIDs: Set<String> {
        Set(targetPasses.map(\.noradID))
    }

    // MARK: - Dependencies

    private let tracker = SatelliteTracker()
    private var updateTask: Task<Void, Never>?

    init(targetPasses: [SatellitePass]) {
        self.targetPasses = targetPasses
    }

    // MARK: - Tracking

    /// Start the 10Hz position update loop.
    func startTracking(satellites: [Satellite], observer: GroundStation, allPasses: [SatellitePass]) {
        guard !isTracking else { return }
        isTracking = true

        let tracker = self.tracker
        let targetIDs = targetNoradIDs
        let interval = UInt64(Constants.AR.updateInterval * 1_000_000_000)

        updateTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                // Compute positions for all target satellites
                var positions: [(pass: SatellitePass, position: SatellitePosition)] = []
                for pass in self.targetPasses {
                    if let sat = satellites.first(where: { $0.id == pass.noradID }),
                       let pos = tracker.position(for: sat, from: observer) {
                        positions.append((pass: pass, position: pos))
                    }
                }
                self.targetPositions = positions

                // Other visible satellites (exclude targets), with pass lookup
                let visible = tracker.visibleSatellites(from: satellites, observer: observer)
                self.visibleSatellites = visible
                    .filter { $0.position.elevation > Constants.AR.minimumElevation }
                    .filter { !targetIDs.contains($0.satellite.id) }
                    .map { vis in
                        let pass = Self.findRelevantPass(
                            forNoradID: vis.satellite.id, in: allPasses
                        )
                        return (
                            name: vis.satellite.name,
                            noradID: vis.satellite.id,
                            position: vis.position,
                            pass: pass
                        )
                    }

                try? await Task.sleep(nanoseconds: interval)
            }
        }
    }

    /// Find the most relevant pass for a satellite — active or next upcoming.
    private static func findRelevantPass(
        forNoradID noradID: String,
        in passes: [SatellitePass]
    ) -> SatellitePass? {
        let now = Date.now
        let matching = passes.filter { $0.noradID == noradID }
        // Prefer an active pass
        if let active = matching.first(where: { $0.isActive(at: now) }) {
            return active
        }
        // Otherwise next upcoming pass
        return matching.filter { $0.isUpcoming(at: now) }.min(by: { $0.aos < $1.aos })
    }

    /// Cancel the position update loop.
    func stopTracking() {
        updateTask?.cancel()
        updateTask = nil
        isTracking = false
    }
}
