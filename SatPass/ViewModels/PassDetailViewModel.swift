import Foundation
import SwiftUI

/// Presentation logic for pass detail screen.
@MainActor @Observable
final class PassDetailViewModel {
    let pass: SatellitePass

    init(pass: SatellitePass) {
        self.pass = pass
    }

    // MARK: - Frequencies

    /// Frequency entries for this satellite from the database (may be empty).
    var frequencies: [SatelliteFrequency] {
        FrequencyDatabase.frequencies(for: pass.noradID)
    }

    // MARK: - Formatted Properties

    var aosDescription: String {
        Formatters.riseDescription(pass.aosAzimuth)
    }

    var losDescription: String {
        Formatters.setDescription(pass.losAzimuth)
    }

    var maxElevationFormatted: String {
        Formatters.degreesWhole(pass.maxElevation)
    }

    var durationFormatted: String {
        Formatters.duration(pass.duration)
    }

    var directionSummary: String {
        Formatters.passDirection(aos: pass.aosAzimuth, los: pass.losAzimuth)
    }

    // MARK: - Pass Quality

    /// Signal quality estimate based on max elevation — higher passes = stronger signal.
    var quality: PassQuality {
        if pass.maxElevation >= 60 { return .excellent }
        if pass.maxElevation >= 30 { return .good }
        if pass.maxElevation >= 15 { return .fair }
        return .low
    }

    enum PassQuality {
        case excellent, good, fair, low

        var label: String {
            switch self {
            case .excellent: "Excellent"
            case .good: "Good"
            case .fair: "Fair"
            case .low: "Low"
            }
        }

        var color: Color {
            switch self {
            case .excellent: .green
            case .good: .blue
            case .fair: .orange
            case .low: .secondary
            }
        }

        var icon: String {
            switch self {
            case .excellent: "antenna.radiowaves.left.and.right"
            case .good: "antenna.radiowaves.left.and.right"
            case .fair: "antenna.radiowaves.left.and.right"
            case .low: "antenna.radiowaves.left.and.right"
            }
        }

        /// Number of bars to fill (out of 4) for a signal-strength style indicator.
        var bars: Int {
            switch self {
            case .excellent: 4
            case .good: 3
            case .fair: 2
            case .low: 1
            }
        }
    }
}
