import Foundation

/// Formatting helpers for satellite pass data.
enum Formatters {

    // MARK: - Degrees & Azimuth

    /// Format degrees with one decimal place (e.g., "42.3°").
    static func degrees(_ value: Double) -> String {
        String(format: "%.1f°", value)
    }

    /// Format degrees as whole number (e.g., "42°").
    static func degreesWhole(_ value: Double) -> String {
        String(format: "%.0f°", value)
    }

    /// Format azimuth as compass bearing with 16-point direction (e.g., "225° SW").
    static func azimuth(_ degrees: Double) -> String {
        let normalized = ((degrees.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let cardinal = cardinalDirection(for: normalized)
        return String(format: "%.0f° %@", normalized, cardinal)
    }

    /// 8-point cardinal direction from degrees (e.g., 225° → "SW").
    static func compassDirection(_ degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let normalized = ((degrees.truncatingRemainder(dividingBy: 360)) + 360)
            .truncatingRemainder(dividingBy: 360)
        let index = Int((normalized + 22.5) / 45.0) % 8
        return directions[index]
    }

    /// Direction summary for a pass (e.g., "SW → NE").
    static func passDirection(aos: Double, los: Double) -> String {
        "\(compassDirection(aos)) → \(compassDirection(los))"
    }

    /// AOS description (e.g., "Rises from 225° SW").
    static func riseDescription(_ azimuth: Double) -> String {
        "Rises from \(self.azimuth(azimuth))"
    }

    /// LOS description (e.g., "Sets at 45° NE").
    static func setDescription(_ azimuth: Double) -> String {
        "Sets at \(self.azimuth(azimuth))"
    }

    // MARK: - Countdown & Time

    /// Launch-style countdown (e.g., "T-02:34" or "T-1:02:34").
    static func tCountdown(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "T-%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "T-%02d:%02d", minutes, seconds)
    }

    /// Time remaining as mm:ss (e.g., "02:34").
    static func timeRemaining(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Friendly countdown (e.g., "2h 15m 30s" or "3m 45s").
    static func countdown(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "Now" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    /// Pass duration in minutes and seconds (e.g., "12m 34s").
    static func duration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return "\(minutes)m \(seconds)s"
    }

    /// Relative time for list display: "In 23 min" for <1hr, absolute time for >1hr.
    static func relativePassTime(_ date: Date, from now: Date = .now) -> String {
        let interval = date.timeIntervalSince(now)
        guard interval > 0 else { return "Now" }

        let minutes = Int(interval) / 60
        if minutes < 1 {
            return "In <1 min"
        }
        if minutes < 60 {
            return "In \(minutes) min"
        }
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Private

    /// 16-point cardinal direction from degrees.
    private static func cardinalDirection(for degrees: Double) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees + 11.25) / 22.5) % 16
        return directions[index]
    }
}
