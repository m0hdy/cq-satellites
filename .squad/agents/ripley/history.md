# Project Context

- **Owner:** Damien
- **Project:** iPhone app for amateur radio satellite pass tracking. Downloads Kepler/TLE data, uses current location to compute satellite passes with azimuth, elevation, countdown timers. Stretch goal: AR overlay showing satellite positions in real-time.
- **Stack:** Swift, SwiftUI, CoreLocation, ARKit, iOS
- **Created:** 2026-03-31

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### Architecture (2026-03-31)
- **Pattern:** MVVM with SwiftUI + `@Observable` (iOS 17) + Swift concurrency (async/await). No Combine.
- **SGP4 library:** SatelliteKit v2.1.1 (gavineadie/SatelliteKit). Pure Swift, zero deps. Note: `TLE` type was renamed to `Elements` in v2.x.
- **TLE source:** CelesTrak GP API — `https://celestrak.org/NORAD/elements/gp.php?GROUP=amateur&FORMAT=TLE`. Refresh every 12 hours.
- **Target:** iOS 17.0+ (also macOS 14+ in Package.swift for local `swift build`)
- **Swift 6 concurrency:** ViewModels and SatelliteStore are `@MainActor`. Services are actors or `Sendable` structs. `Task.detached` for CPU-intensive pass computation.
- **Project structure:** `SatPass/` (App, Models, Services, ViewModels, Views/Components, AR, Utilities, Resources), `SatPassTests/`, `docs/ARCHITECTURE.md`
- **Key files:** `Package.swift` (SPM root), `SatPass/App/SatPassApp.swift` (entry point), `SatPass/Services/PassPredictionService.swift` (SGP4 integration point — has TODO for SatelliteKit wiring)
- **Decision records:** `.squad/decisions.md` (6 ADRs merged from inbox)

### Team Status (2026-03-31)
- **Dallas (iOS):** Built 4 core views (CountdownView, AzimuthView, PassRowView, PassDetailView), 9 formatters. TimelineView pattern for self-contained countdown updates. PassQuality enum maps elevation to signal quality tiers.
- **Parker (Backend):** Wired full ECI→topocentric SGP4 pipeline with SatelliteKit free functions. Fixed SatelliteStore Swift 6 concurrency. Real ISS pass data flowing (7+ passes/day over London, elevations 6°–71°).
- **Lambert (Tester):** 83 tests passing across 7 suites. Discovered SatelliteKit crash on invalid TLE (mitigated with format guard). All edge cases validated (poles, equator, high altitude).
