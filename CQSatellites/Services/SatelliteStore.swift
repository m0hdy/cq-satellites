import Foundation

/// Loading phase for progress reporting during startup.
enum LoadingPhase: Sendable, Equatable {
    case idle
    case locating
    case downloading
    case parsing(count: Int)
    case predicting(current: Int, total: Int)
    case complete
    case error(String)

    var isActive: Bool {
        switch self {
        case .locating, .downloading, .parsing, .predicting:
            return true
        case .idle, .complete, .error:
            return false
        }
    }
}

/// Central store for satellite data and computed passes.
@MainActor @Observable
final class SatelliteStore {
    private(set) var satellites: [Satellite] = []
    private(set) var passes: [SatellitePass] = []
    private(set) var loadingPhase: LoadingPhase = .idle
    private(set) var lastTLEFetch: Date?

    private let tleService = TLEService()
    private let predictionService = PassPredictionService(minimumElevation: 5)

    /// Signal that location resolution is starting.
    func beginLocating() {
        loadingPhase = .locating
    }

    /// Load satellites and compute passes for the given location.
    func loadPasses(from station: GroundStation) async {
        loadingPhase = .downloading

        do {
            let amateur = try await tleService.fetchAmateurSatellites()
            satellites = amateur
            lastTLEFetch = .now

            loadingPhase = .parsing(count: amateur.count)
            passes = await computePassesWithProgress(for: amateur, from: station)
            loadingPhase = .complete
        } catch {
            loadingPhase = .error(error.localizedDescription)
        }
    }

    /// Recompute passes with current satellite data (no progress reporting).
    func refreshPasses(from station: GroundStation) async {
        passes = await computePasses(for: satellites, from: station)
    }

    /// Whether TLE data is stale (older than 12 hours).
    var isTLEStale: Bool {
        guard let last = lastTLEFetch else { return true }
        return Date.now.timeIntervalSince(last) > Constants.Timing.tleRefreshInterval
    }

    /// Process satellites one at a time, reporting progress at throttled intervals.
    private func computePassesWithProgress(for satellites: [Satellite], from station: GroundStation) async -> [SatellitePass] {
        let service = self.predictionService
        let total = satellites.count
        var allPasses: [SatellitePass] = []
        var lastReportedIndex = -1
        // Report progress at most every 2% of total, minimum every satellite if total is small.
        let reportInterval = max(1, total / 50)

        for (index, satellite) in satellites.enumerated() {
            if index - lastReportedIndex >= reportInterval || index == total - 1 {
                loadingPhase = .predicting(current: index + 1, total: total)
                lastReportedIndex = index
            }

            let satellitePasses = await Task.detached(priority: .userInitiated) {
                service.predictPasses(for: satellite, from: station)
            }.value

            allPasses.append(contentsOf: satellitePasses)
        }

        return allPasses.sorted()
    }

    /// Batch computation without progress (used for refresh).
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
