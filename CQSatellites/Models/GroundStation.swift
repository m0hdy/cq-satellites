import Foundation
import CoreLocation

/// The observer's ground position for pass calculations.
struct GroundStation: Sendable {
    let latitude: Double   // degrees
    let longitude: Double  // degrees
    let altitude: Double   // meters above sea level

    init(latitude: Double, longitude: Double, altitude: Double = 0) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
    }

    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
    }
}
