# SatPass — Architecture

> Satellite pass prediction for amateur radio operators.
> Lean utility app. Ship a solid foundation, not a feature-complete mess.

## Architecture Pattern

**MVVM with SwiftUI + Swift Concurrency (async/await)**

- **Views** — SwiftUI views, declarative, no business logic
- **ViewModels** — `@Observable` classes (iOS 17 Observation framework), own presentation logic
- **Models** — Plain value types (structs), immutable where possible
- **Services** — Stateless or actor-isolated, handle I/O and computation

Why not Combine? Swift concurrency is the modern path. Combine is maintenance-mode.
Why not TCA/Redux? This is a focused utility app. MVVM is the right weight class.

## Deployment Target

**iOS 17.0+**

Rationale:
- `@Observable` macro (eliminates `ObservableObject`/`@Published` boilerplate)
- Modern SwiftUI APIs (`ContentUnavailableView`, improved `NavigationStack`)
- `SwiftData` available if we need local persistence later
- ARKit improvements for stretch goal
- iOS 17 adoption is high enough for a new app launching now

## Module Structure

```
SatPass/
├── App/                        # App entry point, root navigation
│   └── SatPassApp.swift
├── Models/                     # Data types — plain structs
│   ├── Satellite.swift         # Satellite identity + TLE data
│   ├── SatellitePass.swift     # Computed pass (AOS, LOS, TCA, elevations, azimuths)
│   └── GroundStation.swift     # Observer location
├── Services/                   # Business logic, I/O, computation
│   ├── TLEService.swift        # Fetch + parse TLE from CelesTrak
│   ├── LocationService.swift   # CoreLocation wrapper
│   ├── PassPredictionService.swift  # Orchestrates SGP4 → pass computation
│   └── SatelliteStore.swift    # In-memory cache of satellites + passes
├── ViewModels/                 # Presentation logic, @Observable
│   ├── PassListViewModel.swift
│   └── PassDetailViewModel.swift
├── Views/                      # SwiftUI views
│   ├── PassListView.swift      # Main screen — upcoming passes
│   ├── PassDetailView.swift    # Single pass detail with countdown + azimuth
│   └── Components/             # Reusable view components
│       ├── PassRowView.swift   # List row for a pass
│       ├── CountdownView.swift # Countdown timer display
│       └── AzimuthView.swift   # Compass-style azimuth indicator
├── AR/                         # Stretch goal — ARKit overlay
│   ├── SatelliteARView.swift
│   └── SatelliteARViewModel.swift
├── Utilities/                  # Shared helpers
│   ├── Constants.swift         # API URLs, refresh intervals, etc.
│   └── Formatters.swift        # Degree, time, coordinate formatting
└── Resources/
    └── Assets.xcassets
```

## Data Flow

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────────┐
│  CelesTrak   │────▶│  TLEService  │────▶│  [Satellite] models  │
│  (HTTP GET)  │     │  fetch+parse │     │  (name + TLE lines)  │
└─────────────┘     └──────────────┘     └──────────┬───────────┘
                                                     │
┌─────────────┐     ┌────────────────┐              │
│ CoreLocation │────▶│LocationService │──┐           │
│   (GPS)      │     │  (lat/lon/alt) │  │           │
└─────────────┘     └────────────────┘  │           │
                                         ▼           ▼
                                  ┌──────────────────────────┐
                                  │  PassPredictionService    │
                                  │  SatelliteKit (SGP4)      │
                                  │  → compute AOS/LOS/TCA    │
                                  │  → max elevation           │
                                  │  → azimuth from/to        │
                                  └────────────┬─────────────┘
                                               │
                                               ▼
                                  ┌──────────────────────────┐
                                  │  SatelliteStore (cache)   │
                                  │  sorted passes by time    │
                                  └────────────┬─────────────┘
                                               │
                              ┌────────────────┼────────────────┐
                              ▼                ▼                ▼
                      ┌─────────────┐  ┌─────────────┐  ┌───────────┐
                      │ PassListView │  │PassDetailView│  │  AR View  │
                      │ (upcoming)   │  │ (countdown,  │  │ (stretch) │
                      │              │  │  azimuth)    │  │           │
                      └─────────────┘  └─────────────┘  └───────────┘
```

### Refresh Strategy

1. **On launch:** Fetch TLEs from CelesTrak, compute passes for next 24 hours
2. **Background refresh:** Re-fetch TLEs every 12 hours (TLE data drifts over days, not hours)
3. **Location updates:** Significant-change monitoring. Re-compute passes on meaningful position change (>1 km)
4. **Pass list:** Re-sort/filter on a 1-minute timer. Countdown timers update on a 1-second timer.
5. **Cache:** Keep TLE data in memory. Persist to `UserDefaults` or file for offline launch. No database needed — the dataset is small.

## Key Technical Decisions

### SGP4: SatelliteKit

**Decision:** Use [SatelliteKit](https://github.com/gavineadie/SatelliteKit) (gavineadie/SatelliteKit)

- Pure Swift, zero external dependencies
- Implements SGP4/SDP4 per SpaceTrack Report #3 (Vallado refinements)
- Swift 6 tools-version, actively maintained through 2025
- MIT license
- Supports all Apple platforms (iOS 12+, but we target 17+)

**Rejected alternatives:**
- SGPKit (csanfilippo/swift-sgp4) — wraps C++ via Swift-C++ interop. Unnecessary complexity for our use case.
- Roll our own — SGP4 is well-specified but fiddly. No reason to reimplement.

### TLE Data Source

**Primary:** CelesTrak GP API
- `https://celestrak.org/NORAD/elements/gp.php?GROUP=amateur&FORMAT=TLE` — amateur radio sats
- `https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=TLE` — ISS, etc.
- JSON format available (`FORMAT=JSON`) if we want structured data later
- Free, no API key required, reliable

**Refresh:** Every 12 hours. TLEs are valid for days; more frequent is wasteful.

### Location Services

- `CLLocationManager` wrapped in an actor-isolated `LocationService`
- Request "When In Use" authorization (no background location needed)
- Use `startMonitoringSignificantLocationChanges()` for passive updates
- Request one accurate fix on launch, then rely on significant-change
- Fallback: last known location from cache

### Pass Prediction

The core computation loop:
1. For each satellite, propagate position at 1-minute intervals over next 24h
2. Compute topocentric coordinates (azimuth, elevation) from observer position
3. A "pass" starts when elevation > 0° (AOS) and ends when it drops below 0° (LOS)
4. TCA = time of closest approach (max elevation during pass)
5. Record: AOS time, LOS time, TCA time, max elevation, AOS azimuth, LOS azimuth

This is CPU-intensive for many satellites. Mitigations:
- Run on a background thread (Swift concurrency task)
- Pre-filter: skip satellites with very low inclination from high-latitude observers (they'll never pass overhead)
- Cache results; only recompute on TLE refresh or location change

### AR Overlay (Stretch Goal)

- ARKit + RealityKit in landscape mode
- Continuous SGP4 propagation to get real-time satellite ECEF position
- Convert to local horizon coordinates (az/el) relative to device
- Render as labeled dot/icon in AR space
- Use device compass + gyroscope (ARKit handles this) to anchor positions
- Separate `AR/` module, lazy-loaded, behind a feature flag

## Dependencies

| Package | Purpose | URL |
|---------|---------|-----|
| SatelliteKit | SGP4/SDP4 propagation, TLE parsing | `https://github.com/gavineadie/SatelliteKit` |

That's it. One dependency. Everything else is Apple frameworks:
- **SwiftUI** — UI
- **CoreLocation** — GPS
- **ARKit + RealityKit** — AR overlay (stretch)
- **Foundation** — Networking (`URLSession`), date math, etc.

## Testing Strategy

- **Unit tests:** Pass prediction math, TLE parsing, model logic
- **Service tests:** Mock `URLSession` for TLE fetch, mock `CLLocationManager` for location
- **UI tests:** Deferred until UI stabilizes. SwiftUI previews serve as visual tests early on.

## What We're NOT Doing

- No SwiftData/CoreData — dataset is tiny, in-memory + file cache is enough
- No Combine — async/await is cleaner for this use case
- No third-party UI libraries — SwiftUI is sufficient
- No server component — everything runs on-device
- No user accounts — this is a local utility
