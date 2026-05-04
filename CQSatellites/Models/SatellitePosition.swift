import Foundation

/// A satellite's real-time topocentric position relative to an observer.
struct SatellitePosition: Sendable {
    /// Azimuth in degrees (0–360, north = 0, clockwise).
    let azimuth: Double
    /// Elevation in degrees (-90 to +90, horizon = 0).
    let elevation: Double
    /// Distance from observer in kilometers.
    let distance: Double
    /// Whether the satellite is above the horizon.
    let isVisible: Bool

    /// 3D direction unit vector for ARKit (.gravityAndHeading alignment: X = east, Y = up, Z = south).
    var arDirection: SIMD3<Float> {
        let azRad = azimuth * .pi / 180.0
        let elRad = elevation * .pi / 180.0
        return SIMD3<Float>(
            Float(cos(elRad) * sin(azRad)),    // east
            Float(sin(elRad)),                   // up
            Float(-cos(elRad) * cos(azRad))     // south (negated for ARKit Z-axis)
        )
    }
}
