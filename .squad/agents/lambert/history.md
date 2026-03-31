# Project Context

- **Owner:** Damien
- **Project:** iPhone app for amateur radio satellite pass tracking. Downloads Kepler/TLE data, uses current location to compute satellite passes with azimuth, elevation, countdown timers. Stretch goal: AR overlay showing satellite positions in real-time.
- **Stack:** Swift, SwiftUI, CoreLocation, ARKit, iOS
- **Created:** 2026-03-31

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-31 — Initial test suite (83 tests, 7 suites)

- **Test fixtures**: Real ISS TLE (NORAD 25544, epoch 24058) and INTELSAT 39 (NORAD 44476, GEO) data validated against SatelliteKit. Historical ISS TLE (epoch 17108) also works. All sourced from SatelliteKit's own test corpus.
- **SatelliteKit crash bug**: `Elements.init` crashes (array-index-out-of-range) on completely invalid TLE strings instead of throwing. The `parseTLEText` guard (`hasPrefix("1 ")` / `hasPrefix("2 ")`) protects against this in production, but direct `Satellite.init` with garbage input will crash. Do NOT pass unvalidated strings to `Satellite(name:tleLine1:tleLine2:)`.
- **parseTLEText testability**: Made `parseTLEText` internal (was private) on the TLEService actor to enable direct parsing tests. It doesn't access actor state — could be `nonisolated static` for cleaner API, but that's an implementation decision.
- **SGP4 is wired**: PassPredictionService is producing real pass data. ISS over London yields 7+ passes/day with plausible elevations (6°–71°) and durations (5–12 min). North Pole correctly shows zero ISS passes (inclination 51.6° < 90°).
- **Equatable gap**: SatellitePass conforms to Comparable but not Equatable. The original tests used `==` on arrays which wouldn't compile. Tests now compare by property (`.aos`) instead. Consider adding Equatable conformance.
- **Swift Testing framework**: Tests use `import Testing` with `@Suite`/`@Test`/`#expect`. Async tests (for actor methods) work with `@Test func foo() async { }`. All 83 tests run in parallel successfully.
- **Ground station edge cases**: Poles (±90°), equator (0°,0°), antimeridian (0°,180°), high altitude (8849m Everest) — all handled correctly by GroundStation model.
- **Formatter coverage**: 16-point compass works correctly. Azimuth wrapping at 360° is handled. Countdown shows "Now" for zero/negative values.

### Team Status (2026-03-31)
- **Ripley (Architecture):** Designed MVVM + SatelliteKit architecture (6 ADRs merged). 21 source files, clean build.
- **Dallas (iOS):** Built 4 core views (CountdownView, AzimuthView, PassRowView, PassDetailView), 9 formatters. TimelineView self-contained.
- **Parker (Backend):** Wired full ECI→topocentric SGP4 pipeline. Fixed SatelliteStore concurrency. Real pass data flowing.
