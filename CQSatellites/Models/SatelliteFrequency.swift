import Foundation

/// A single frequency entry for a satellite (e.g., FM repeater, CW beacon, transponder).
/// A satellite can have multiple frequency entries.
struct SatelliteFrequency: Sendable, Identifiable {
    let id = UUID()
    let uplink: String?        // e.g., "145.950 MHz"
    let downlink: String?      // e.g., "435.340 MHz"
    let beacon: String?        // e.g., "435.340 MHz"
    let mode: String           // e.g., "FM", "CW", "SSB", "Linear Transponder"
    let description: String?   // e.g., "V/U FM repeater"
}
