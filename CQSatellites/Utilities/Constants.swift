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
    
    enum AR {
        /// Position update frequency for the AR overlay (10 Hz).
        static let updateInterval: TimeInterval = 0.1
        /// Distance in meters to place AR markers from the camera.
        static let markerDistance: Float = 50.0
        /// Minimum elevation (degrees) to display a satellite in AR.
        static let minimumElevation: Double = 0.0
        /// Maximum number of target satellites shown when launching AR from the list view.
        static let maxListTargets = 5

        // MARK: - Marker sizes

        /// Sphere radius for target (green) satellites.
        static let targetSphereRadius: Float = 0.9
        /// Sphere radius for non-target (blue) satellites.
        static let nonTargetSphereRadius: Float = 0.5

        // MARK: - Label sizes

        /// Font size for target satellite labels.
        static let targetLabelFontSize: CGFloat = 2.25
        /// Font size for non-target satellite labels.
        static let nonTargetLabelFontSize: CGFloat = 1.4
        /// Label vertical offset above target marker center.
        static let targetLabelOffset: Float = 3.5
        /// Label vertical offset above non-target marker center.
        static let nonTargetLabelOffset: Float = 2.5

        // MARK: - ISS custom icon

        /// NORAD catalog ID for the International Space Station.
        static let issNoradID = "25544"
        /// Width/height of the ISS icon plane in meters.
        static let issIconPlaneSize: Float = 2.0
    }

    enum AMSAT {
        static let statusAPIBase = "https://amsat.org/status/api/v1/sat_info.php"
        static let websiteURL = "https://www.amsat.org/status/"
        /// Default number of hours of status reports to fetch.
        static let defaultHours = 24
    }
}
