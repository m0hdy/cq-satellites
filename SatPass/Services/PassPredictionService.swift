import Foundation
import SatelliteKit

/// Computes satellite passes over a ground station using SGP4 propagation.
struct PassPredictionService: Sendable {

    /// Time step for coarse pass search (seconds).
    private static let coarseStep: TimeInterval = 60
    /// Time step for fine-grained peak finding (seconds).
    private static let fineStep: TimeInterval = 1

    /// Minimum elevation (degrees) to consider a valid pass.
    let minimumElevation: Double

    init(minimumElevation: Double = 0) {
        self.minimumElevation = minimumElevation
    }

    /// Predict all passes for a satellite over a time window.
    func predictPasses(
        for satellite: Satellite,
        from station: GroundStation,
        startDate: Date = .now,
        duration: TimeInterval = 86400 // 24 hours
    ) -> [SatellitePass] {
        let endDate = startDate.addingTimeInterval(duration)
        var passes: [SatellitePass] = []

        // Create SGP4/SDP4 propagator once per satellite via SatelliteKit free function
        let propagator = selectPropagator(tle: satellite.elements)
        // Observer position: LatLonAlt expects altitude in km
        let observer = LatLonAlt(station.latitude, station.longitude, station.altitude / 1000.0)

        var currentDate = startDate
        var inPass = false
        var passStart: Date?
        var maxEl: Double = 0
        var maxElTime: Date = startDate
        var startAz: Double = 0

        while currentDate <= endDate {
            let topocentric = computeTopocentric(
                propagator: propagator,
                observer: observer,
                at: currentDate
            )

            if let topo = topocentric {
                let elevation = topo.elevation
                let azimuth = topo.azimuth

                if elevation > minimumElevation {
                    if !inPass {
                        // AOS
                        inPass = true
                        passStart = currentDate
                        startAz = azimuth
                        maxEl = elevation
                        maxElTime = currentDate
                    }
                    if elevation > maxEl {
                        maxEl = elevation
                        maxElTime = currentDate
                    }
                } else if inPass {
                    // LOS
                    inPass = false
                    if let aos = passStart {
                        let pass = SatellitePass(
                            id: UUID(),
                            satelliteName: satellite.name,
                            noradID: satellite.id,
                            aos: aos,
                            los: currentDate,
                            tca: maxElTime,
                            maxElevation: maxEl,
                            aosAzimuth: startAz,
                            losAzimuth: azimuth
                        )
                        passes.append(pass)
                    }
                    maxEl = 0
                }
            }

            currentDate = currentDate.addingTimeInterval(Self.coarseStep)
        }

        return passes.sorted()
    }

    /// Compute topocentric coordinates (azimuth, elevation) for a satellite at a given time.
    /// Pipeline: SGP4 propagation → ECI position → topocentric (az/el) via SatelliteKit free functions.
    private func computeTopocentric(
        propagator: any Propagable,
        observer: LatLonAlt,
        at date: Date
    ) -> (azimuth: Double, elevation: Double)? {
        guard let pv = try? propagator.getPVCoordinates(date) else {
            return nil
        }

        // PVCoordinates are in meters; geographic functions expect km
        let satECI = Vector(pv.position.x / 1000.0,
                            pv.position.y / 1000.0,
                            pv.position.z / 1000.0)

        let aed = topPosition(julianDays: date.julianDate, satCel: satECI, obsLLA: observer)
        return (azimuth: aed.azim, elevation: aed.elev)
    }
}
