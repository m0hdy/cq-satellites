# Project Context

- **Owner:** Damien
- **Project:** iPhone app for amateur radio satellite pass tracking. Downloads Kepler/TLE data, uses current location to compute satellite passes with azimuth, elevation, countdown timers. Stretch goal: AR overlay showing satellite positions in real-time.
- **Stack:** Swift, SwiftUI, CoreLocation, ARKit, iOS
- **Created:** 2026-03-31

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### SatelliteKit API patterns (2026-03-31)
- **Module/struct name collision**: SatelliteKit has a `struct SatelliteKit` that shadows the module name. You CANNOT write `SatelliteKit.Satellite` — it resolves to the struct, not the module. Use SatelliteKit's free functions instead of referencing its `Satellite` type directly.
- **Free function approach**: `selectPropagator(tle: Elements)` → `any Propagable` for SGP4/SDP4. `Propagable.getPVCoordinates(_ date: Date)` → `PVCoordinates` (meters). `topPosition(julianDays:satCel:obsLLA:)` → `AziEleDst` (azimuth, elevation, distance).
- **Unit conversions**: `PVCoordinates` position is in **meters**, geographic functions (`topPosition`, `eci2geo`) expect **km** — divide by 1000. `LatLonAlt.alt` is in **km**, our `GroundStation.altitude` is in **meters**.
- **Time conversion**: `Date.julianDate` extension property (from SatelliteKit) converts Swift `Date` to Julian Days.
- **Key files**: `Propagator.swift` has `selectPropagator()` and `Propagable` protocol. `Geography.swift` has `topPosition()`, `LatLonAlt`, `AziEleDst`, coordinate converters. `Astronomy.swift` has sidereal time. `TimeUtility.swift` has `Date.julianDate`, `JD` epoch constants.
- **SatelliteStore concurrency**: When using `Task.detached` from `@MainActor` context, capture `Sendable` properties into local variables before the closure to satisfy Swift 6 strict concurrency.

### Team Status (2026-03-31)
- **Ripley (Architecture):** Designed MVVM + SatelliteKit architecture (6 ADRs merged). 21 source files, clean build.
- **Dallas (iOS):** Built 4 core views (CountdownView, AzimuthView, PassRowView, PassDetailView), 9 formatters. TimelineView self-contained pattern.
- **Lambert (Tester):** 83 tests passing across 7 suites. Discovered SatelliteKit crash on invalid TLE (mitigated).
