import Foundation

/// Fetches and parses TLE data from CelesTrak.
actor TLEService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetch amateur radio satellite TLEs from CelesTrak.
    func fetchAmateurSatellites() async throws -> [Satellite] {
        let url = URL(string: Constants.API.amateurTLEURL)!
        return try await fetchSatellites(from: url)
    }

    /// Fetch space station TLEs (ISS, etc.) from CelesTrak.
    func fetchStations() async throws -> [Satellite] {
        let url = URL(string: Constants.API.stationsTLEURL)!
        return try await fetchSatellites(from: url)
    }

    /// Fetch and parse TLE data from a URL.
    private func fetchSatellites(from url: URL) async throws -> [Satellite] {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TLEServiceError.fetchFailed
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw TLEServiceError.invalidData
        }

        return parseTLEText(text)
    }

    /// Parse three-line TLE format (name + line1 + line2).
    func parseTLEText(_ text: String) -> [Satellite] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var satellites: [Satellite] = []

        var i = 0
        while i + 2 < lines.count {
            let name = lines[i]
            let line1 = lines[i + 1]
            let line2 = lines[i + 2]

            // Validate TLE line markers
            guard line1.hasPrefix("1 "), line2.hasPrefix("2 ") else {
                i += 1
                continue
            }

            if let satellite = try? Satellite(name: name, tleLine1: line1, tleLine2: line2) {
                satellites.append(satellite)
            }
            i += 3
        }

        return satellites
    }
}

enum TLEServiceError: LocalizedError {
    case fetchFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .fetchFailed: "Failed to fetch TLE data from CelesTrak."
        case .invalidData: "TLE data could not be decoded."
        }
    }
}
