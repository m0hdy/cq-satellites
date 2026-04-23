import Foundation

/// App-wide constants.
enum Constants {
    enum API {
        static let amateurTLEURL = "https://celestrak.org/NORAD/elements/gp.php?GROUP=amateur&FORMAT=TLE"
        static let stationsTLEURL = "https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=TLE"
    }

    enum Timing {
        /// How often to re-fetch TLE data (12 hours in seconds).
        static let tleRefreshInterval: TimeInterval = 43200
        /// Countdown timer update interval.
        static let countdownInterval: TimeInterval = 1.0
        /// Pass list refresh interval.
        static let passListRefreshInterval: TimeInterval = 60.0
    }

    enum ElevationFilter {
        static let userDefaultsKey = "minimumElevation"
        /// Default minimum max-elevation for pass filtering (degrees).
        static let defaultMinimum: Double = 10
        /// Preset options for the segmented control.
        static let presets: [Double] = [0, 10, 20, 30, 45]
    }

    enum FrequencyFilter {
        static let userDefaultsKey = "showOnlyWithFrequencies"
        /// Default: only show satellites that have amateur radio frequencies.
        static let defaultValue = true
    }

    /// Default fallback values when GPS is unavailable.
    enum Defaults {
        static let londonLatitude = 51.5074
        static let londonLongitude = -0.1278
        static let londonAltitude = 11.0

        static var londonStation: GroundStation {
            GroundStation(latitude: londonLatitude, longitude: londonLongitude, altitude: londonAltitude)
        }
    }
    
    enum AMSAT {
        static let statusAPIBase = "https://amsat.org/status/api/v1/sat_info.php"
        static let websiteURL = "https://www.amsat.org/status/"
        /// Default number of hours of status reports to fetch.
        static let defaultHours = 24
    }
}
