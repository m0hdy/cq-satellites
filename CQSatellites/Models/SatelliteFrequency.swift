import Foundation

/// A radio operating mode supported by a satellite.
enum OperatingMode: String, CaseIterable, Identifiable, Sendable {
    case fm = "FM"
    case ssb = "SSB"
    case cw = "CW"
    case digital = "Digital"

    var id: String { rawValue }
}

/// A single frequency entry for a satellite (e.g., FM repeater, CW beacon, transponder).
/// A satellite can have multiple frequency entries.
struct SatelliteFrequency: Sendable, Identifiable {
    let id = UUID()
    let uplink: String?        // e.g., "145.950 MHz"
    let downlink: String?      // e.g., "435.340 MHz"
    let beacon: String?        // e.g., "435.340 MHz"
    let mode: String           // e.g., "FM", "CW", "SSB", "Linear Transponder"
    let description: String?   // e.g., "V/U FM repeater"

    /// Standard operating modes represented by this entry's source metadata.
    var operatingModes: Set<OperatingMode> {
        let normalizedMode = mode.uppercased()
        var modes: Set<OperatingMode> = []

        if normalizedMode.contains("FM") { modes.insert(.fm) }
        if normalizedMode.contains("SSB") { modes.insert(.ssb) }
        if normalizedMode.contains("CW") { modes.insert(.cw) }
        if ["DIGITAL", "APRS", "PACKET", "DIGIPEATER", "DVB", "APT", "LRPT"]
            .contains(where: normalizedMode.contains) {
            modes.insert(.digital)
        }

        return modes
    }
}
