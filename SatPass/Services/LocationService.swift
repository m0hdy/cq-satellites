import Foundation
import CoreLocation

/// Wraps CoreLocation to provide the observer's current position.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()

    private(set) var currentLocation: CLLocation?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    private(set) var error: Error?

    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Request location authorization and start monitoring.
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// Get the current location, requesting a fresh fix.
    func getCurrentLocation() async throws -> CLLocation {
        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    /// Start monitoring for significant location changes.
    func startMonitoring() {
        manager.startMonitoringSignificantLocationChanges()
    }

    /// Current position as a GroundStation, if available.
    var groundStation: GroundStation? {
        guard let location = currentLocation else { return nil }
        return GroundStation(location: location)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
