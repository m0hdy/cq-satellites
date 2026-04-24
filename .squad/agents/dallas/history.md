# Project Context

- **Owner:** Damien
- **Project:** iPhone app for amateur radio satellite pass tracking. Downloads Kepler/TLE data, uses current location to compute satellite passes with azimuth, elevation, countdown timers. Stretch goal: AR overlay showing satellite positions in real-time.
- **Stack:** Swift, SwiftUI, CoreLocation, ARKit, iOS
- **Created:** 2026-03-31

## Core Context

**Summarized from 225 lines of detailed learnings spanning 2026-03-31 to 2026-04-23.**

Dallas built the entire **UI layer** for SatPass: pass countdown, azimuth compass, pass list, elevation filter, frequency display, AMSAT status section, landscape orientation support, and AR satellite overlay. Key patterns: `TimelineView` for self-contained countdowns, `LoadingPhase` enum for state, `@Environment(\.verticalSizeClass)` for orientation detection, ARKit/RealityKit entity hierarchy with text billboarding, `#if os(iOS)` platform guards.

**Key technical decisions:**
- Countdown & compass are hero UI (users need instant "when" and "where")
- Signal quality tiers mapped from pass elevation (≥60° excellent, ≥30° good, ≥15° fair, <15° low)
- Elevation filter uses segmented picker (discrete presets 0/10/20/30/45°) not slider — matches ham radio operator mental models
- AR triggered by `verticalSizeClass == .compact` (landscape) with two modes: list shows 5 targets, detail shows 1
- Entity hierarchy: parent (positioned) → sphere + label parent → label text (billboarded, mesh throttled by elevation rounding)
- Target satellites green (0.3 radius), others blue (0.15 radius), labels ~1.5-2× larger for visibility
- Frequency database backed by FrequencyDatabase lookup (Parker provides real data)
- AMSAT status lazy-loaded when user scrolls to that section
- All work uses `@Observable`, `@MainActor`, `Task`-based concurrency, no Combine

**Build status:** 83 tests passing, clean builds across all changes.

## Learnings

<!-- Append new recent learnings below. -->

### 2026-04-24 — AR Countdown Timer on Satellite Labels

**Problem:** AR labels only showed "NAME ELEV°" — no timing info. Users couldn't tell when a pass starts or how long it lasts without leaving AR.

**Files touched:**
- `CQSatellites/Utilities/Constants.swift` — Added 4 constants: `targetCountdownFontSize` (1.8), `nonTargetCountdownFontSize` (1.12), `targetCountdownOffset` (-2.5), `nonTargetCountdownOffset` (-1.6).
- `CQSatellites/AR/SatelliteARViewModel.swift` — Changed `visibleSatellites` tuple to include `pass: SatellitePass?`. Added `findRelevantPass(forNoradID:in:)` static helper (prefers active pass, then next upcoming). `startTracking()` now takes `allPasses: [SatellitePass]` parameter.
- `CQSatellites/AR/SatelliteARView.swift` — Added `countdownEntities` and `lastRenderedCountdowns` dictionaries to Coordinator. Each satellite label now has a second `ModelEntity` for countdown text, positioned below the name via negative Y offset. Countdown mesh throttled to 1-second string changes. Added `countdownInfo(for:)` and `formatCountdown(seconds:prefix:)` static helpers. Colors: red for pre-AOS, green for active, gray "—" for post-LOS.

**Key patterns:**
- RealityKit `MeshResource.generateText()` only supports one color per mesh — separate entity required for colored countdown text.
- Countdown updates every frame but mesh only regenerates when formatted string changes (1-sec granularity), same throttling philosophy as elevation text.
- Used `monospacedDigitSystemFont` for countdown to prevent digit-width jitter during counting.
- Pass lookup for visible satellites uses static method to find active or next upcoming pass by noradID.

**Build:** `swift build` clean. **Tests:** 83 pass.

## Sessions

## Session: AR Overlay Integration (2026-04-23T16:37:45Z)

**Cross-team milestone:** SatelliteARView fully operational with Parker's SatelliteTracker.

- **Implemented ADR-012–ADR-016:** Landscape orientation support, ARKit world alignment (X=east, Y=up, Z=south), entity hierarchy (parent/sphere/label), text mesh throttling, platform guards.
- **Integration complete:** Wired SatelliteTracker into SatelliteARViewModel. Real-time position calculation at 10 Hz feeds RealityKit entity positioning.
- **ARWorldTrackingConfiguration:** worldAlignment = .gravityAndHeading for magnetic north alignment.
- **Entity hierarchy:** Parent at `arDirection * markerDistance`, sphere child, billboarded text label.
- **Performance optimization:** Text mesh regeneration only when rounded elevation changes (~1×/sec per satellite, not 10×/sec).
- **Test status:** All 83 tests pass, clean build.

### 2026-04-24 — Landscape-to-AR Trigger with Multi-Satellite Support

**Context:** Damien requested AR activation via landscape rotation instead of a toolbar button. Two modes: list view shows next 5 satellites, detail view shows just the selected one.

**Files touched:**
- `SatPass/AR/SatelliteARViewModel.swift` — `targetPass` → `targetPasses: [SatellitePass]` array. `targetPosition` → `targetPositions` array of (pass, position) tuples. Visible satellites now exclude all target IDs.
- `SatPass/AR/SatelliteARView.swift` — Accepts `passes: [SatellitePass]`. Removed dismiss button (rotation dismisses). Coordinator renders all targets as green markers. TargetInfoPanel adapts: single target shows full telemetry, multi-target shows compact list with elevation.
- `SatPass/Views/PassDetailView.swift` — Removed `showARView` state, toolbar ARKit button, and fullScreenCover. Added `verticalSizeClass` environment. Compact size class shows `SatelliteARView(passes: [pass])` with hidden nav bar.
- `SatPass/Views/PassListView.swift` — Added `verticalSizeClass` and `NavigationPath` tracking. Overlay shows `SatelliteARView` with first 5 filtered passes when landscape + at root (not pushed to detail).
- `SatPass/Utilities/Constants.swift` — Added `Constants.AR.maxListTargets = 5`.

**Key patterns:**
- `@Environment(\.verticalSizeClass)` detects landscape (`.compact`) — SwiftUI-native, no NotificationCenter.
- `NavigationPath.isEmpty` prevents list-level AR from overlaying when a detail view is pushed (detail handles its own AR).
- `if/else` swap in body vs `.overlay` — used `if/else` in PassDetailView (replaces content), `.overlay` in PassListView (preserves NavigationStack state).
- Multi-target TargetInfoPanel uses `targets.max(by:)` for primary satellite selection by elevation.

**Test status:** All 83 tests pass, clean build.

### 2026-04-23T16:49:19Z — Session Logged & Decision Merged

Scribe tasks completed:
- **Orchestration log:** `.squad/orchestration-log/2026-04-23T16:49:19Z-dallas.md`
- **Session log:** `.squad/log/2026-04-23T16:49:19Z-ar-landscape-trigger.md`
- **Decision merged:** ADR-018 appended to `.squad/decisions.md` (deduplicated inbox)
- **Build status:** 9f1fea3 clean, 83 tests pass

### 2026-04-24 — AR Marker Visibility Overhaul + ISS Custom Icon

**Problem:** AR satellite markers (spheres + labels) were completely unreadable — too small at 50m distance. ISS had no special treatment.

**Files touched:**
- `CQSatellites/Utilities/Constants.swift` — Added 8 new `Constants.AR` entries: `targetSphereRadius` (0.9), `nonTargetSphereRadius` (0.5), `targetLabelFontSize` (0.45), `nonTargetLabelFontSize` (0.28), `targetLabelOffset` (1.5), `nonTargetLabelOffset` (1.0), `issNoradID` ("25544"), `issIconPlaneSize` (2.0)
- `CQSatellites/AR/SatelliteARView.swift` — Replaced hardcoded sizes with constants. Added ISS detection (NORAD 25544) to render a textured `generatePlane` instead of `generateSphere`. Added `iconEntities` dictionary for ISS icon billboarding. Added `loadISSTexture()` for lazy-cached `TextureResource` loading from bundle. ISS icon uses `UnlitMaterial` with tint×texture for green/blue coloring, `opacityThreshold` for alpha cutout.
- `CQSatellites/Resources/iss_icon.png` — White-on-transparent 512×512 ISS silhouette (converted from SVG via sips + PIL).
- `Package.swift` — Added `.process("Resources")` so SPM picks up the PNG and xcassets.

**Size changes (old → new):**
| Property | Old | New |
|---|---|---|
| Target sphere radius | 0.3 | 0.9 |
| Non-target sphere radius | 0.15 | 0.5 |
| Target label font | 0.15 | 0.45 |
| Non-target label font | 0.1 | 0.28 |
| Target label offset | 0.8 | 1.5 |
| Non-target label offset | 0.5 | 1.0 |

**ISS icon approach:** `MeshResource.generatePlane(width:height:)` with `UnlitMaterial(tint × texture)` and `opacityThreshold: 0.05`. Icon wrapper entity billboarded alongside labels. Falls back to regular sphere if texture fails to load.

**Build:** `swift build` clean.

**Test status:** 83 tests pass.

### 2026-04-24T07:08:00Z — Session Logged & Decision Merged

Scribe tasks completed:
- **Orchestration log:** `.squad/orchestration-log/2026-04-24T07:08:00Z-dallas.md`
- **Session log:** `.squad/log/2026-04-24T07:08:00Z-ar-marker-improvements.md`
- **Decision merged:** ADR-019 appended to `.squad/decisions.md` (deduplicated & deleted inbox)
- **Build status:** clean, 83 tests pass

### 2026-04-24T08:04:00Z — AR Countdown Timer Labels on Satellite Markers

**Context:** AR satellite markers had name + elevation but no timing info. Users need to see when passes start (AOS) and end (LOS) in real time.

**Files touched:**
- `CQSatellites/AR/SatelliteARViewModel.swift` — `startTracking()` now accepts `allPasses: [SatellitePass]`. Added `findRelevantPass(forNoradID:in:)` static helper (prefers active pass, then next upcoming).
- `CQSatellites/AR/SatelliteARView.swift` — Added `countdownEntities` and `lastRenderedCountdowns` dictionaries. Each satellite label now has a second `ModelEntity` for countdown text, positioned below the name via negative Y offset. Countdown mesh throttled to 1-second string changes. Added `countdownInfo(for:)` and `formatCountdown(seconds:prefix:)` static helpers. Colors: red for pre-AOS (`"T— mm:ss"`), green for active (`"↓ mm:ss"`), gray for post-LOS (`"— —:—"`).
- `CQSatellites/Utilities/Constants.swift` — Added 4 countdown sizing constants: `targetCountdownFontSize` (1.8), `nonTargetCountdownFontSize` (1.12), `targetCountdownOffset` (-2.5), `nonTargetCountdownOffset` (-1.6).

**Key patterns:**
- Dual-entity label system: RealityKit `MeshResource.generateText()` only supports one color, so separate entity required for colored countdown.
- Countdown updates every frame but mesh only regenerates when formatted string changes (1-sec granularity).
- Used `monospacedDigitSystemFont` for countdown to prevent digit-width jitter during counting.
- Pass lookup for visible satellites uses static method to find active or next upcoming pass by noradID.

**Build:** `swift build` clean. **Tests:** 83 pass.

### 2026-04-24T08:04:00Z — Session Logged & Decision Merged

Scribe tasks completed:
- **Orchestration log:** `.squad/orchestration-log/2026-04-24T08:04:00Z-dallas.md`
- **Session log:** `.squad/log/2026-04-24T08:04:00Z-ar-countdown-labels.md`
- **Decision merged:** ADR-020 appended to `.squad/decisions.md` (no inbox files)
- **Build status:** clean, 83 tests pass
