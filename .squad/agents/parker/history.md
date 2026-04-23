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

### Frequency Database Architecture (2026-03-31)
- **Built-in lookup over API**: No reliable free API for amateur satellite frequencies in machine-readable format. Used a static `FrequencyDatabase` enum keyed by NORAD catalog ID (String). This is stable data — AMSAT frequency assignments rarely change. Updates ship with app releases.
- **Model shape**: `SatelliteFrequency` is `Sendable` + `Identifiable` (UUID-based `id` for SwiftUI `ForEach`). Fields: `uplink`, `downlink`, `beacon` (all optional Strings), `mode` (required), `description` (optional).
- **One-to-many**: A satellite can have multiple frequency entries (e.g., ISS has FM repeater + APRS + voice downlink). `Satellite.frequencies` returns `[SatelliteFrequency]`.
- **Lookup integration**: Added computed property `var frequencies: [SatelliteFrequency]` on `Satellite` — zero-cost for sats not in the database (returns `[]`).
- **Database scope**: 30+ satellites covered including ISS, SO-50, AO-91, AO-92, RS-44, XW-2 series, CAS-4 series, TEVEL constellation (11 sats via range), FUNcube, NOAA weather sats, QO-100 (geostationary), and more.
- **Dallas stub had bugs**: The original stub had ISS downlink wrong (437.800 → should be 145.800) and AO-91 uplink/downlink swapped. Fixed both.

### Frequency Database Architecture (2026-03-31)
- **Built-in lookup over API**: No reliable free API for amateur satellite frequencies in machine-readable format. Used a static `FrequencyDatabase` enum keyed by NORAD catalog ID (String). This is stable data — AMSAT frequency assignments rarely change. Updates ship with app releases.
- **Model shape**: `SatelliteFrequency` is `Sendable` + `Identifiable` (UUID-based `id` for SwiftUI `ForEach`). Fields: `uplink`, `downlink`, `beacon` (all optional Strings), `mode` (required), `description` (optional).
- **One-to-many**: A satellite can have multiple frequency entries (e.g., ISS has FM repeater + APRS + voice downlink). `Satellite.frequencies` returns `[SatelliteFrequency]`.
- **Lookup integration**: Added computed property `var frequencies: [SatelliteFrequency]` on `Satellite` — zero-cost for sats not in the database (returns `[]`).
- **Database scope**: 30+ satellites covered including ISS, SO-50, AO-91, AO-92, RS-44, XW-2 series, CAS-4 series, TEVEL constellation (11 sats via range), FUNcube, NOAA weather sats, QO-100 (geostationary), and more.
- **Dallas stub had bugs**: The original stub had ISS downlink wrong (437.800 → should be 145.800) and AO-91 uplink/downlink swapped. Fixed both.

### Team Status (2026-03-31)
- **Ripley (Architecture):** Designed MVVM + SatelliteKit architecture (6 ADRs merged). 21 source files, clean build.
- **Dallas (iOS):** Built 4 core views (CountdownView, AzimuthView, PassRowView, PassDetailView), 9 formatters. TimelineView self-contained pattern.
- **Lambert (Tester):** 83 tests passing across 7 suites. Discovered SatelliteKit crash on invalid TLE (mitigated).

### 2026-03-31 — Feature Spawn Completion

**Parker spawned:** Built production frequency database with 30+ amateur radio satellites  
**Dallas spawned:** Elevation filter, Xcode project (XcodeGen), default London location, frequency display UI, loading progress screen

**ADRs added to decisions.md:**
- ADR-007: Elevation Filter UX — segmented picker matches ham radio operator thinking
- ADR-008: Xcode Project via XcodeGen — proper iOS app bundle, declarative YAML
- ADR-009: Built-in Frequency Database — zero API deps, stable frequency assignments
- ADR-010: LoadingPhase Enum — single source of truth for loading state

**Team coordination:** Decision inbox merged (4 files). Orchestration logs written. Cross-agent history updated (Dallas/Parker).

### AMSAT Status Report Integration (2026-04-23)
- **Data layer created:** `AMSATStatusReport` model and `AMSATStatusService` actor for fetching operator-reported satellite health status from https://amsat.org/status/api/v1/sat_info.php
- **NORAD → AMSAT mapping:** Static dictionary maps 18 satellites with NORAD IDs to AMSAT names (ISS-FM, AO-91, SO-50, etc.). Conservative approach — only satellites present in both FrequencyDatabase and AMSAT's valid names list.
- **Actor pattern:** `AMSATStatusService` follows TLEService pattern — actor isolation, URLSession-based, returns empty array on error (no throws).
- **API integration:** `PassDetailViewModel` already had a stub calling `fetchReports(forNoradID:hours:)`. Service implements this signature.
- **UUID generation:** AMSATStatusReport generates UUID locally in `init(from:)` since API JSON has no `id` field. Satisfies `Identifiable` for SwiftUI.
- **Constants:** Added `Constants.AMSAT` enum with API base URL, website URL, and default hours (24).
- **Key files:** `SatPass/Models/AMSATStatusReport.swift`, `SatPass/Services/AMSATStatusService.swift`, updated `Constants.swift`
- **AMSAT valid names (reference):** AO-7[A], AO-7[B], AO-27, AO-73, AO-91, CAS-4A, CAS-4B, FO-29, FO-99, HO-113, IO-117, ISS-FM, ISS-DATA, ISS-SSTV, ISS-DATV, JO-97, LilacSat-2, PO-101[FM], QO-100_NB, QO-100_WB, RS-44, SO-50, TO-108, and 50+ others

### AMSAT Satellite Name Format Update (2026-04-23)
- **Name format standardization:** Updated all satellite name mappings in `AMSATStatusService.swift` to use AMSAT's live status page dropdown format with `_[mode]` suffixes
- **Examples:** `SO-50` → `SO-50_[FM]`, `ISS-FM` → `ISS_[FM]`, `FO-29` → `FO-29_[FM]`
- **Removals:** Deleted 6 satellites no longer in AMSAT's valid dropdown list
- **Bug fix:** Corrected IO-86 NORAD ID in mapping dictionary
- **Backward compatibility:** All 83 tests passing. Mapping ready for production
- **Rationale:** AMSAT API requires exact names from their dropdown; standardized format ensures reliable API calls

**Cross-team coordination (Dallas):**
- Dallas updated `PassDetailViewModel` with lazy-loaded AMSAT status reports (StatusLoadingState enum, loadStatusReports method)
- Dallas updated `PassDetailView` with new "Satellite Status" section between Radio and Timing
- Section shows colored status indicators (green/red/blue/gray), reporter info, and AMSAT attribution link
- Lazy loading via `.task` modifier — fetches only when section appears
