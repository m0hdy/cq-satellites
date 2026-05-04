import Foundation

/// A predicted satellite pass over the observer's location.
struct SatellitePass: Identifiable, Sendable {
    let id: UUID
    let satelliteName: String
    let noradID: String

    /// Acquisition of signal — satellite rises above horizon
    let aos: Date
    /// Loss of signal — satellite drops below horizon
    let los: Date
    /// Time of closest approach — maximum elevation
    let tca: Date

    /// Maximum elevation during pass (degrees, 0–90)
    let maxElevation: Double
    /// Azimuth at AOS (degrees, 0–360, north = 0)
    let aosAzimuth: Double
    /// Azimuth at LOS (degrees, 0–360, north = 0)
    let losAzimuth: Double

    /// Pass duration
    var duration: TimeInterval {
        los.timeIntervalSince(aos)
    }

    /// Whether the pass is currently in progress
    func isActive(at date: Date = .now) -> Bool {
        date >= aos && date <= los
    }

    /// Whether the pass is in the future
    func isUpcoming(at date: Date = .now) -> Bool {
        date < aos
    }

    /// Time until AOS (negative if pass has started)
    func timeUntilAOS(from date: Date = .now) -> TimeInterval {
        aos.timeIntervalSince(date)
    }

    /// Time remaining in pass (negative if pass is over)
    func timeRemaining(from date: Date = .now) -> TimeInterval {
        los.timeIntervalSince(date)
    }
}

extension SatellitePass: Comparable {
    static func < (lhs: SatellitePass, rhs: SatellitePass) -> Bool {
        lhs.aos < rhs.aos
    }
}
