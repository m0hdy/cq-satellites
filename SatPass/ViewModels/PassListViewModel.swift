import Foundation

/// Whether the location came from GPS or a hardcoded default.
enum LocationSource: Equatable {
    case gps
    case defaultLocation(name: String)

    var label: String {
        switch self {
        case .gps:
            return "GPS"
        case .defaultLocation(let name):
            return "Default — \(name)"
        }
    }
}

/// Presentation logic for the pass list screen.
@MainActor @Observable
final class PassListViewModel {
    private let locationService = LocationService()
    private var hasLoaded = false

    private(set) var currentStation: GroundStation?
    private(set) var locationSource: LocationSource?

    /// Minimum max-elevation threshold for displayed passes (persisted in UserDefaults).
    var minimumElevation: Double {
        didSet {
            UserDefaults.standard.set(minimumElevation, forKey: Constants.ElevationFilter.userDefaultsKey)
        }
    }

    /// Human-readable summary of the active location, e.g. "📍 51.51°N, 0.13°W (GPS)".
    var locationDescription: String? {
        guard let station = currentStation, let source = locationSource else { return nil }
        let lat = abs(station.latitude)
        let lon = abs(station.longitude)
        let latDir = station.latitude >= 0 ? "N" : "S"
        let lonDir = station.longitude >= 0 ? "E" : "W"
        return String(format: "📍 %.2f°%@, %.2f°%@ (%@)", lat, latDir, lon, lonDir, source.label)
    }

    init() {
        let stored = UserDefaults.standard.object(forKey: Constants.ElevationFilter.userDefaultsKey) as? Double
        self.minimumElevation = stored ?? Constants.ElevationFilter.defaultMinimum
    }

    /// Label for the current elevation filter (e.g. "Min: 10°" or "All").
    var elevationFilterLabel: String {
        minimumElevation == 0 ? "All passes" : "Min: \(Int(minimumElevation))°"
    }

    /// Filter passes to only upcoming + active that meet the minimum elevation.
    func filteredPasses(from passes: [SatellitePass]) -> [SatellitePass] {
        let now = Date.now
        return passes.filter { pass in
            (pass.isActive(at: now) || pass.isUpcoming(at: now))
                && pass.maxElevation >= minimumElevation
        }
    }

    /// Called when the view appears. Fetches location and loads passes.
    /// Falls back to London if GPS is unavailable.
    func onAppear(store: SatelliteStore) async {
        guard !hasLoaded else { return }
        hasLoaded = true

        locationService.requestAuthorization()

        do {
            let location = try await locationService.getCurrentLocation()
            let station = GroundStation(location: location)
            currentStation = station
            locationSource = .gps
            await store.loadPasses(from: station)
        } catch {
            let station = Constants.Defaults.londonStation
            currentStation = station
            locationSource = .defaultLocation(name: "London")
            await store.loadPasses(from: station)
        }
    }

    /// Manual refresh — re-fetch TLE if stale, recompute passes.
    func refresh(store: SatelliteStore) async {
        guard let station = currentStation else { return }

        if store.isTLEStale {
            await store.loadPasses(from: station)
        } else {
            await store.refreshPasses(from: station)
        }
    }
}
