import Foundation
import SatelliteKit

/// Computes real-time satellite positions for AR overlay and live tracking.
///
/// Stateless value type — mirrors PassPredictionService patterns.
/// Uses SatelliteKit free functions to avoid the module/struct name collision.
struct SatelliteTracker: Sendable {

    /// Compute the current topocentric position of a satellite relative to an observer.
    func position(
        for satellite: Satellite,
        from observer: GroundStation,
        at date: Date = .now
    ) -> SatellitePosition? {
        let propagator = selectPropagator(tle: satellite.elements)
        let obsLLA = LatLonAlt(observer.latitude, observer.longitude, observer.altitude / 1000.0)

        return computeTopocentric(propagator: propagator, observer: obsLLA, at: date)
    }

    /// Compute positions for all satellites currently above the horizon.
    func visibleSatellites(
        from satellites: [Satellite],
        observer: GroundStation,
        at date: Date = .now
    ) -> [(satellite: Satellite, position: SatellitePosition)] {
        let obsLLA = LatLonAlt(observer.latitude, observer.longitude, observer.altitude / 1000.0)

        return satellites.compactMap { satellite in
            let propagator = selectPropagator(tle: satellite.elements)
            guard let pos = computeTopocentric(propagator: propagator, observer: obsLLA, at: date),
                  pos.isVisible else {
                return nil
            }
            return (satellite: satellite, position: pos)
        }
    }

    // MARK: - Private

    /// SGP4 propagation → ECI → topocentric (az/el/dist).
    /// Same pipeline as PassPredictionService.computeTopocentric, extended with distance.
    private func computeTopocentric(
        propagator: any Propagable,
        observer: LatLonAlt,
        at date: Date
    ) -> SatellitePosition? {
        guard let pv = try? propagator.getPVCoordinates(date) else {
            return nil
        }

        // PVCoordinates are in meters; geographic functions expect km
        let satECI = Vector(pv.position.x / 1000.0,
                            pv.position.y / 1000.0,
                            pv.position.z / 1000.0)

        let aed = topPosition(julianDays: date.julianDate, satCel: satECI, obsLLA: observer)

        return SatellitePosition(
            azimuth: aed.azim,
            elevation: aed.elev,
            distance: aed.dist,
            isVisible: aed.elev > 0
        )
    }
}
