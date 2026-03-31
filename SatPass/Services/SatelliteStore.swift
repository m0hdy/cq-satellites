import Foundation

/// Central store for satellite data and computed passes.
@MainActor @Observable
final class SatelliteStore {
    private(set) var satellites: [Satellite] = []
    private(set) var passes: [SatellitePass] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var lastTLEFetch: Date?

    private let tleService = TLEService()
    private let predictionService = PassPredictionService(minimumElevation: 5)

    /// Load satellites and compute passes for the given location.
    func loadPasses(from station: GroundStation) async {
        isLoading = true
        error = nil

        do {
            let amateur = try await tleService.fetchAmateurSatellites()
            satellites = amateur
            lastTLEFetch = .now

            passes = await computePasses(for: amateur, from: station)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    /// Recompute passes with current satellite data.
    func refreshPasses(from station: GroundStation) async {
        passes = await computePasses(for: satellites, from: station)
    }

    /// Whether TLE data is stale (older than 12 hours).
    var isTLEStale: Bool {
        guard let last = lastTLEFetch else { return true }
        return Date.now.timeIntervalSince(last) > Constants.Timing.tleRefreshInterval
    }

    private func computePasses(for satellites: [Satellite], from station: GroundStation) async -> [SatellitePass] {
        let service = self.predictionService
        return await Task.detached(priority: .userInitiated) {
            satellites.flatMap { satellite in
                service.predictPasses(for: satellite, from: station)
            }
            .sorted()
        }.value
    }
}
