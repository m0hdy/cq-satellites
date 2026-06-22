# CQ Satellites — Architecture

> Satellite pass prediction for amateur radio operators.
> Lean iOS utility app. Clear contributor workflow, predictable build surface, and no platform ambiguity.

## Platform contract

CQ Satellites is an **iOS-only** application.

- **Supported platform:** iOS
- **Minimum deployment target:** iOS 17.0
- **Toolchain:** Swift 6, Xcode 16+
- **Unsupported targets:** macOS, tvOS, watchOS

For contributors, the canonical validation surface is `CQSatellites.xcodeproj` via `xcodebuild test`. Root-level `swift test` is not the supported app validation path.

## Architecture pattern

**MVVM with SwiftUI + Swift Concurrency (async/await)**

- **Views** — SwiftUI views, declarative, no business logic
- **ViewModels** — `@Observable` classes (iOS 17 Observation framework), own presentation logic
- **Models** — Plain value types (structs), immutable where possible
- **Services** — Stateless or actor-isolated, handle I/O and computation

Why not Combine? Swift concurrency is the modern path. Combine is maintenance-mode.
Why not TCA/Redux? This is a focused utility app. MVVM is the right weight class.

## Repository and project surfaces

- **`CQSatellites.xcodeproj`** — checked-in project used for app builds and test runs
- **`project.yml`** — XcodeGen source of truth for target/configuration changes
- **`Package.swift`** — package metadata and dependency definition; not the canonical contributor test entry point

After regenerating project artifacts, verify that:

1. The repo remains **iOS-only**
2. The deployment target is still **iOS 17.0**
3. `Package.swift`, `project.yml`, and the generated project stay aligned
4. The documented `xcodebuild test` command still passes

## Module structure

```
CQSatellites/
├── App/                        # App entry point, root navigation
│   └── CQSatellitesApp.swift
├── Models/                     # Data types — plain structs
│   ├── Satellite.swift         # Satellite identity + TLE data
│   ├── SatellitePass.swift     # Computed pass (AOS, LOS, TCA, elevations, azimuths)
│   ├── GroundStation.swift     # Observer location
│   └── AMSATStatusReport.swift # Community-reported satellite health entries
├── Services/                   # Business logic, I/O, computation
│   ├── TLEService.swift        # Fetch + parse TLE data from CelesTrak
│   ├── AMSATStatusService.swift# Fetch AMSAT status reports
│   ├── LocationService.swift   # CoreLocation wrapper
│   ├── HeadingService.swift    # Heading/compass integration for AR and UI
│   ├── PassPredictionService.swift  # Orchestrates SGP4 → pass computation
│   └── SatelliteStore.swift    # In-memory satellite + pass state
├── ViewModels/                 # Presentation logic, @Observable
│   ├── PassListViewModel.swift
│   └── PassDetailViewModel.swift
├── Views/                      # SwiftUI views
│   ├── PassListView.swift      # Main screen — upcoming passes
│   ├── PassDetailView.swift    # Single pass detail with countdown + azimuth
│   ├── AboutView.swift         # Project/about metadata
│   └── Components/             # Reusable view components
├── AR/                         # ARKit/RealityKit visualization
├── Utilities/                  # Shared helpers and constants
└── Resources/                  # Bundled assets
```

## Data flow

```
CelesTrak TLEs ──▶ TLEService ──▶ Satellite models ──┐
                                                      │
AMSAT status API ─▶ AMSATStatusService ───────────────┤
                                                      ▼
CoreLocation ────▶ LocationService ───────────▶ PassPredictionService
                                                      ▼
                                              SatelliteStore / ViewModels
                                                      ▼
                                         Pass list / pass detail / AR views
```

## Refresh and state strategy

1. **On launch:** fetch current TLE data and compute upcoming passes
2. **Network refresh:** CelesTrak and AMSAT data are fetched when needed for current views/workflows
3. **Location updates:** request a current fix and use location services to support live pass prediction
4. **UI state:** filters such as minimum elevation and frequency-only mode are stored in `UserDefaults`
5. **Computed pass state:** held in memory and refreshed when inputs change

## External data sources

### CelesTrak

Primary source for orbital elements used in pass prediction:

- `https://celestrak.org/NORAD/elements/gp.php?GROUP=amateur&FORMAT=TLE`
- `https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=TLE`

### AMSAT

Satellite health/status information for supported satellites:

- API base: `https://amsat.org/status/api/v1/sat_info.php`
- Website: `https://www.amsat.org/status/`

## Key technical decisions

### SGP4 propagation: SatelliteKit

**Decision:** use [SatelliteKit](https://github.com/gavineadie/SatelliteKit)

- Pure Swift
- Appropriate for Swift 6 codebases
- Avoids introducing extra service infrastructure
- Keeps prediction logic local to the device

### Location behavior

- Uses `CLLocationManager`
- Requests **When In Use** authorization
- Calculates passes for the current user location when available
- Falls back to a default location in some flows if GPS access is unavailable

### AR behavior

- Uses **ARKit** and **RealityKit** on supported iOS devices
- Requires camera access to render the live AR experience
- Remains an iOS-specific feature and should not drive cross-platform project assumptions

## Testing strategy

- **Primary contributor validation:** `xcodebuild test -project CQSatellites.xcodeproj -scheme CQSatellites -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'`
- **Unit/integration coverage:** model logic, parsing, pass prediction, formatting, and service behavior
- **Documentation alignment:** contributor docs should always describe the same build/test path CI enforces

## What we are intentionally not doing

- No server-side account system
- No analytics stack in the repository
- No non-iOS platform targets
- No extra app-framework abstraction layers that would complicate a small utility app
