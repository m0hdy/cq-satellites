import Foundation
import SatelliteKit

/// A satellite with its identity and orbital elements.
struct Satellite: Identifiable, Sendable {
    let id: String  // NORAD catalog number
    let name: String
    let elements: Elements

    /// Known uplink/downlink frequencies and modes from the built-in database.
    var frequencies: [SatelliteFrequency] {
        FrequencyDatabase.frequencies(for: id)
    }

    init(name: String, tleLine1: String, tleLine2: String) throws {
        self.name = name.trimmingCharacters(in: .whitespaces)
        self.elements = try Elements(self.name, tleLine1, tleLine2)
        self.id = String(elements.noradIndex)
    }
}
