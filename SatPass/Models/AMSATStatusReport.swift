import Foundation

/// A single status report from the AMSAT Oscar Satellite Status page.
/// Source: https://www.amsat.org/status/
struct AMSATStatusReport: Identifiable, Sendable, Decodable {
    let id: UUID
    let name: String
    let reportedTime: String
    let callsign: String
    let report: String
    let gridSquare: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case reportedTime = "reported_time"
        case callsign
        case report
        case gridSquare = "grid_square"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.reportedTime = try container.decode(String.self, forKey: .reportedTime)
        self.callsign = try container.decode(String.self, forKey: .callsign)
        self.report = try container.decode(String.self, forKey: .report)
        self.gridSquare = try container.decode(String.self, forKey: .gridSquare)
    }
}
