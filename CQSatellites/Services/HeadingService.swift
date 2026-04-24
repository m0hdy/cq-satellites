import Foundation
import CoreLocation

/// Provides real-time compass heading from the device magnetometer.
/// Used by the pass detail compass to rotate with the phone's orientation.
@Observable
final class HeadingService: NSObject, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()

    /// Current device heading in degrees (0–360, 0 = true north).
    private(set) var heading: Double = 0

    override init() {
        super.init()
        manager.delegate = self
        #if os(iOS)
        manager.headingFilter = 1
        #endif
    }

    func startUpdating() {
        #if os(iOS)
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
        #endif
    }

    func stopUpdating() {
        #if os(iOS)
        manager.stopUpdatingHeading()
        #endif
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }
}
