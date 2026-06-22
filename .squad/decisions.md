# Squad Decisions

## Architecture Decisions (Ripley)

### ADR-001: MVVM with SwiftUI + async/await

**Status:** Accepted  
**Context:** Need an architecture pattern for a focused utility app.  
**Decision:** MVVM with `@Observable` (iOS 17), Swift concurrency. No Combine, no TCA.  
**Rationale:** Right weight class for the problem. `@Observable` eliminates boilerplate. Async/await is cleaner than Combine for network + computation workflows. TCA is overkill for a single-screen utility.  
**Consequences:** Requires iOS 17+. Team must use `@Observable` not `ObservableObject`.

### ADR-002: SatelliteKit for SGP4 Propagation

**Status:** Accepted  
**Context:** Need SGP4/SDP4 orbit propagation. Options: SatelliteKit (pure Swift), SGPKit (C++ wrapper), roll our own.  
**Decision:** Use SatelliteKit (gavineadie/SatelliteKit).  
**Rationale:** Pure Swift, zero dependencies, MIT license, actively maintained, Swift 6 compatible. SGPKit requires C++ interop — unnecessary complexity. Rolling our own is pointless when a solid library exists.  
**Consequences:** One external dependency. Must validate its API covers our topocentric coordinate needs.

### ADR-003: iOS 17+ Deployment Target

**Status:** Accepted  
**Context:** Need to choose minimum iOS version.  
**Decision:** iOS 17.0+.  
**Rationale:** Gives us `@Observable`, modern SwiftUI APIs, improved ARKit. Adoption is high enough for a new app. No reason to support older versions.  
**Consequences:** Excludes iOS 16 devices (small population for a new app).

### ADR-004: CelesTrak as TLE Data Source

**Status:** Accepted  
**Context:** Need satellite orbital data in TLE format.  
**Decision:** CelesTrak GP API (`celestrak.org/NORAD/elements/gp.php`).  
**Rationale:** Free, no API key, reliable, supports amateur radio satellite group directly. JSON and TLE formats available. Well-established in the amateur radio community.  
**Consequences:** Single point of failure. Could add Space-Track.org as fallback later (requires account).

### ADR-005: In-Memory Data, No Database

**Status:** Accepted  
**Context:** Need to store satellite TLEs and computed passes.  
**Decision:** In-memory storage with file-based cache for offline launch. No CoreData/SwiftData.  
**Rationale:** The dataset is tiny (< 200 satellites, < 1000 passes). A database adds complexity for zero benefit. Simple file cache handles offline.  
**Consequences:** Data is transient. If we add favorites or history later, revisit this decision.

### ADR-006: AR as Stretch Goal, Behind Feature Flag

**Status:** Accepted  
**Context:** AR overlay for real-time satellite tracking in the sky.  
**Decision:** Isolate in `AR/` module. Implement after core functionality ships. Landscape-only mode with ARKit + RealityKit.  
**Rationale:** Core pass prediction is the MVP. AR is compelling but complex — don't let it block shipping.  
**Consequences:** AR module is a placeholder until core is solid.

### ADR-007: Elevation Filter UX — Segmented Picker with Presets

**Status:** Implemented  
**Context:** Damien requested elevation filtering for the pass list. Low-elevation passes (< 10° max elevation) are barely usable for amateur radio — weak signals, atmospheric interference, obstructed line of sight.  
**Decision:** Used a **segmented picker** with fixed presets (All, 10°, 20°, 30°, 45°) rather than a freeform slider or stepper.  
**Rationale:**
- Ham radio operators already think in these specific elevation tiers (they map to signal quality categories in PassDetailViewModel).
- Five discrete options are faster to tap than dragging a slider.
- "All" (0°) provides an escape hatch for users who want every pass.
- Default 10° matches common amateur radio practice.

**Storage:** Single `Double` in `UserDefaults` under key `"minimumElevation"`. This aligns with ADR-005 (no database for simple preferences).  
**Impact:** `PassListViewModel.filteredPasses()` now applies elevation filter alongside the existing time-based filter (upcoming + active). The filter presets (0, 10, 20, 30, 45) are defined in `Constants.ElevationFilter.presets` — if we later want to add more tiers, change one place.

### ADR-008: Xcode Project via XcodeGen

**Status:** Implemented  
**Context:** The project was structured as an SPM `.executableTarget` in Package.swift. This does not produce an iOS app bundle — SPM executable targets don't process Info.plist, set bundle identifiers, or support simulator/device deployment. Xcode was erroring: "Cannot index window tabs due to missing main bundle identifier."  
**Decision:** Use **XcodeGen** (`project.yml`) to generate a proper `SatPass.xcodeproj` with:
- iOS App target (`SatPass`) referencing all sources in `SatPass/`
- Unit test target (`SatPassTests`)
- SatelliteKit as an SPM dependency
- Bundle ID: `com.satpass.app`
- Deployment target: iOS 17.0
- Swift 6.0 with strict concurrency

Package.swift is kept for `swift build`/`swift test` CLI compatibility.  
**Rationale:**
- XcodeGen is declarative (YAML) and reproducible — avoids brittle manual .pbxproj edits.
- `project.yml` is small, readable, and diffable. The generated `.xcodeproj` is tracked in git so the team doesn't need XcodeGen installed to open the project.
- Keeping Package.swift means CI can still use `swift test` without Xcode.

**Regeneration:** After editing `project.yml`, run: `xcodegen generate`  
**Impact:**
- **All team members:** Open `SatPass.xcodeproj` in Xcode (not Package.swift) for simulator/device builds.
- **CI:** Can use either `swift test` (Package.swift) or `xcodebuild` (SatPass.xcodeproj).
- **New dependencies:** Add to both `project.yml` (packages section) and `Package.swift`.

### ADR-009: Built-in Frequency Database (Static Lookup)

**Status:** Implemented  
**Context:** TLE data only contains orbital elements — no frequency information. We need uplink/downlink frequencies and modes for amateur radio satellites. Options considered:
1. **External API** — No reliable free API provides amateur satellite frequencies in machine-readable format. SatNOGS has a DB API but it's complex and not 1:1 with our satellite list.
2. **Bundled JSON file** — Could work, but adds file I/O and parsing overhead for relatively static data.
3. **Built-in static lookup** — Compile-time constant, zero I/O, type-safe, easy to extend.

**Decision:** Use a built-in `FrequencyDatabase` enum with a static dictionary keyed by NORAD catalog ID. Data ships with the app binary and updates with releases.  
**Rationale:**
- Amateur satellite frequency assignments are **very stable** — changes happen maybe a few times per year across the whole fleet.
- The dataset is small (30-40 satellites × 1-3 entries each).
- No network dependency, no parsing failures, no API keys.
- Matches ADR-005 (in-memory data, no database).

**Impact:**
- `Satellite.frequencies` computed property is the public interface — returns `[SatelliteFrequency]` (empty array if satellite not in database).
- `SatelliteFrequency` conforms to `Identifiable` (UUID) for SwiftUI `ForEach`.
- Dallas is building frequency display UI against this shape.
- To add a satellite: single edit to `FrequencyDatabase.swift`, add entry to the dictionary.

### ADR-010: LoadingPhase Enum Replaces Bool/Error State

**Status:** Implemented  
**Context:** SatelliteStore used `isLoading: Bool` + `error: Error?` for loading state. This allowed impossible state combinations and gave the UI no way to show what was actually happening during the multi-step startup (locate → download → parse → predict).  
**Decision:** Replaced with a single `LoadingPhase` enum:
```swift
enum LoadingPhase: Sendable, Equatable {
    case idle, locating, downloading, parsing(count: Int),
         predicting(current: Int, total: Int), complete, error(String)
}
```

**Rationale:**
- **Single source of truth** — one property, no contradictory states.
- **Progress granularity** — associated values carry satellite count and prediction progress, enabling a real progress bar.
- **Sendable + Equatable** — works with Swift 6 concurrency and SwiftUI diffing.

**Impact:**
- `store.isLoading` → check `store.loadingPhase.isActive`
- `store.error` → check `if case .error(let msg) = store.loadingPhase`
- Any future code reading loading state must use `loadingPhase` instead of the old Bool/Error pair.

## View Implementation Decisions (Dallas)

### CountdownView uses TimelineView (self-contained)

**Status:** Implemented  
**Context:** CountdownView needs 1-second updates for live countdown.  
**Decision:** CountdownView uses `TimelineView(.periodic(from: .now, by: 1.0))` internally. No `now` parameter needed from parent views.  
**Rationale:**
- **Reusability:** Drop CountdownView anywhere without wiring up a timer in the parent.
- **Modern SwiftUI:** TimelineView is the SwiftUI-native solution (avoids Combine's `Timer.publish`).
- **Performance:** TimelineView only redraws its content closure, not the whole parent view hierarchy.
- **Simplicity:** PassDetailView no longer needs any timer state — the countdown handles itself.

**Impact:** PassDetailView no longer has `@State private var now` or `Timer.publish`. PassRowView still uses `Timer.publish` since it needs `now` for multiple display calculations (active/upcoming state, time formatting). This is fine — different component, different needs.

## Backend Integration Decisions (Parker)

### SGP4 Integration: Free Functions over SatelliteKit.Satellite

**Status:** Implemented  
**Context:** SatelliteKit has a module/struct name collision that prevents `SatelliteKit.Satellite` from resolving.  
**Decision:** Use SatelliteKit's **free functions** (`selectPropagator`, `topPosition`, `eci2geo`) instead of its `Satellite` type for orbital propagation.  
**Rationale:** Avoids a naming collision where `SatelliteKit.Satellite` is unresolvable because the module name is shadowed by a `struct SatelliteKit` inside the library.

**Pipeline:**
1. `selectPropagator(tle:)` → creates SGP4 or SDP4 propagator (`any Propagable`)
2. `propagator.getPVCoordinates(date)` → ECI position/velocity in **meters**
3. `topPosition(julianDays:satCel:obsLLA:)` → azimuth, elevation, distance in **degrees/km**

**Impact:**
- All code that needs satellite position should use `selectPropagator()` + free functions
- Never reference `SatelliteKit.Satellite` by name — it won't compile
- `LatLonAlt` altitude must be in **km** (our `GroundStation` stores meters)

## Testing Decisions (Lambert)

### SatelliteKit Crash Mitigation

**Status:** Documented & Mitigated  
**Finding:** SatelliteKit's `Elements.init(_ line0:, _ line1:, _ line2:)` crashes with `Array index out of range` when fed completely invalid TLE strings (empty strings, random text) instead of throwing an error.  
**Current Mitigation:** `TLEService.parseTLEText()` guards with `hasPrefix("1 ")` / `hasPrefix("2 ")` checks before attempting `Satellite.init`, preventing the crash path in production.  
**Recommendation:**
1. **Never pass unvalidated strings to `Satellite(name:tleLine1:tleLine2:)`** — always pre-validate format first.
2. Consider adding a `Satellite.isValidTLE(line1:line2:) -> Bool` helper that checks format without crashing.
3. Optionally: file an issue upstream on `gavineadie/SatelliteKit` for the crash-instead-of-throw behavior.

**Impact:** Low risk currently (guard is in place), but any future code path that creates Satellite objects from user input or untrusted data must go through parseTLEText or equivalent validation.

## Data Layer Decisions (Parker)

### ADR-011: AMSAT Status Report Integration

**Status:** Implemented  
**Author:** Parker  
**Date:** 2026-04-23  

**Context:** Amateur radio satellite operators report satellite health status to AMSAT's community page (https://www.amsat.org/status/). These reports include working/broken transponders, mode changes, and operational issues. The app needs a data layer to fetch and display these reports so users can see if a satellite is currently operational before planning QSO attempts.

**Decision:** Implemented a non-throwing, actor-based service (`AMSATStatusService`) that:
1. Maps NORAD IDs to AMSAT names using a static dictionary (18 satellites)
2. Fetches reports via AMSAT API: `https://amsat.org/status/api/v1/sat_info.php?name=<name>&hours=<hours>`
3. Returns empty array on any error (no throwing)
4. Generates UUID locally in `AMSATStatusReport.init(from:)` for `Identifiable` compliance
5. Matches existing stub in `PassDetailViewModel` with signature `fetchReports(forNoradID:hours:)`

**Rationale:**
- **Static mapping over API lookup:** No AMSAT API endpoint maps NORAD IDs to names. Static dictionary is maintainable and follows `FrequencyDatabase` pattern.
- **Conservative mapping:** Only included satellites in both FrequencyDatabase and AMSAT's valid names list — avoids false positives.
- **Actor isolation:** Consistent with `TLEService` pattern.
- **No throws:** Returns `[]` on failure. ViewModel treats this as "no reports available." Simplifies UI.
- **UUID in Decodable:** JSON lacks `id` field, but SwiftUI `ForEach` requires `Identifiable`.

**API Details:**
- Endpoint: `GET https://amsat.org/status/api/v1/sat_info.php`
- Query params: `name` (AMSAT satellite name), `hours` (default 96, we use 24)
- Response: JSON array of `{name, reported_time, callsign, report, grid_square}`

**Files Created/Modified:**
- `SatPass/Models/AMSATStatusReport.swift`
- `SatPass/Services/AMSATStatusService.swift`
- `SatPass/Utilities/Constants.swift` (added `Constants.AMSAT`)

**NORAD → AMSAT Mappings (18 satellites):**
| NORAD ID | AMSAT Name | Satellite |
|----------|------------|-----------|
| 25544 | ISS-FM | ISS |
| 7530 | AO-7[A] | AMSAT-OSCAR 7 |
| 22825 | AO-27 | AMSAT-OSCAR 27 |
| 39444 | AO-73 | FUNcube-1 |
| 43017 | AO-91 | Fox-1B |
| 27607 | SO-50 | SaudiSat-1C |
| 24278 | FO-29 | Fuji-OSCAR 29 |
| 43937 | FO-99 | NEXUS |
| 44909 | RS-44 | DOSAAF-85 |
| 43803 | JO-97 | JY1Sat |
| 42761 | CAS-4A | ZHUHAI-1 01 |
| 42759 | CAS-4B | ZHUHAI-1 02 |
| 53106 | IO-117 | GreenCube |
| 45119 | HO-113 | HuskySat-1 |
| 44881 | TO-108 | CAS-6 / TIANQIN-1 |
| 43678 | PO-101[FM] | DIWATA-2 |
| 43700 | QO-100_NB | Es'hail-2 |
| 40908 | LilacSat-2 | CAS-3H |

**Testing:** `swift build` clean, `swift test` all 83 tests pass.

**Future Considerations:**
- Add more satellite mappings as AMSAT database grows
- Consider caching reports for a few minutes
- UI implementation complete by Dallas (PassDetailView)

## Governance

## View Implementation Decisions (Dallas) — Part 2

### ADR-012: Landscape Orientation Support

**Status:** Implemented  
**Author:** Dallas  
**Date:** 2026-04-23  

**Context:** Damien requested landscape support. The app was portrait-locked.

**Decision:** Enabled landscape left + right orientations with `@Environment(\.verticalSizeClass)` layouts.

**Responsive Sizing:** `verticalSizeClass == .compact` for landscape. Compass 200pt→150pt, countdown 56pt→40pt, LoadingView VStack→HStack, filter sheet .medium detent.

**Rationale:** Standard Apple approach. Portrait untouched, landscape additive.

**Consequences:** App rotates to landscape. Smoother AR transition (ADR-006).

## AR Implementation Decisions (Dallas)

### ADR-013: ARKit World Alignment

**Status:** Implemented  
**Decision:** `worldAlignment = .gravityAndHeading`. RealityKit: X=east, Y=up, Z=south, magnetic north aligned.

### ADR-014: Entity Hierarchy per Satellite

**Status:** Implemented  
**Decision:** Three-level hierarchy: Parent (positioned at `arDirection * markerDistance`), Sphere child, Label parent→Text child (billboarded separately).

### ADR-015: Text Mesh Update Throttling

**Status:** Implemented  
**Decision:** Regenerate text mesh only when rounded elevation changes, not at 10 Hz. Reduces from 10×/sec to ~1×/sec.

### ADR-016: Platform Guards for AR

**Status:** Implemented  
**Decision:** AR wrapped in `#if os(iOS)` with `ContentUnavailableView` fallback. Maintains `swift build` compatibility.

## Backend Integration Decisions (Parker) — Part 2

### ADR-017: SatelliteTracker as Stateless Struct

**Status:** Implemented  
**Decision:** `SatelliteTracker` is a stateless `Sendable` struct (not actor). Synchronous position calculation. Caller owns timer and state.

**Rationale:** No I/O, no caching, no shared state. Matches `PassPredictionService` pattern. 10 Hz update loop stays simple.

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction

### ADR-018: Landscape Rotation Triggers AR View

**Status:** Implemented  
**Author:** Dallas  
**Date:** 2026-04-23  

**Context:** Previously, AR was launched via a toolbar button in PassDetailView. Damien requested that rotating the phone to landscape automatically shows the AR view, and rotating back to portrait dismisses it.

**Decision:** AR is now triggered by `@Environment(\.verticalSizeClass) == .compact` (landscape) in both PassListView and PassDetailView. No toolbar button, no fullScreenCover, no dismiss button.

**Two AR modes:**
1. **From list view (landscape at root):** Shows next 5 upcoming satellites as targets (all green markers). Uses `.overlay` on NavigationStack, gated by `navigationPath.isEmpty` to avoid conflicting with detail-level AR.
2. **From detail view (landscape while viewing a satellite):** Shows only that satellite as target. Uses `if/else` body swap with `.toolbar(.hidden, for: .navigationBar)`.

**Multi-target support:**
- `SatelliteARViewModel` now accepts `targetPasses: [SatellitePass]` array
- All targets rendered as green markers; other visible satellites stay blue
- `TargetInfoPanel` adapts: single target = full telemetry, multi-target = compact elevation list

**Rationale:**
- `verticalSizeClass` is the SwiftUI-native way to detect orientation — no NotificationCenter or UIDevice observation needed
- If the user has orientation lock on, `verticalSizeClass` stays `.regular` and AR never activates (correct behavior)
- Rotation-to-dismiss is zero-friction — no button to find, just rotate back

**Impact:**
- **SatelliteARView API changed:** `passes: [SatellitePass]` instead of `pass: SatellitePass`
- **PassDetailView:** No more AR toolbar button — any code referencing `showARView` is gone
- **PassListView:** Now uses `NavigationPath` for path tracking
- **Constants:** New `Constants.AR.maxListTargets = 5`

### ADR-019: AR Marker Sizing Constants & ISS Custom Icon

**Status:** Implemented  
**Author:** Dallas  
**Date:** 2026-04-24  

**Context:** AR satellite markers were unreadable at 50m distance. Hardcoded sizes scattered through SatelliteARView.swift. ISS (the most popular satellite) had no special visual treatment.

**Decision:**
1. All AR marker sizes (sphere radii, label fonts, label offsets) are now named constants in `Constants.AR`.
2. ISS (NORAD 25544) renders as a textured plane with its actual silhouette instead of a generic sphere.
3. ISS icon is white-on-transparent PNG, tinted green/blue via `UnlitMaterial` color multiplication.
4. Falls back to regular sphere if texture load fails.

**Size changes:** Target sphere 0.3→0.9, non-target 0.15→0.5. Labels ~3× larger. Offsets increased proportionally.

**Impact:**
- Any future AR marker work should use `Constants.AR` sizes, not hardcoded values.
- ISS icon PNG lives at `CQSatellites/Resources/iss_icon.png` — to update, replace the file.
- Package.swift now has `.process("Resources")` for SPM resource bundling.

### ADR-020: AR Satellite Countdown Timers via Dual-Entity Labels

**Status:** Implemented  
**Author:** Dallas  
**Date:** 2026-04-24  

**Context:** AR labels only showed satellite name + elevation. Users couldn't see when a pass starts (AOS) or ends (LOS) without leaving AR. Real-time countdown timers are essential for amateur radio operators planning QSO windows.

**Decision:** Each satellite gets two text mesh entities:
1. **Primary label** (name + elevation, color = target green / non-target blue)
2. **Secondary label** (countdown timer, color = red pre-AOS / green in-pass / gray post-LOS)

Positioned vertically via Y offset (countdown below name). Pass data threaded through `SatelliteARViewModel.startTracking(allPasses:)`.

**Implementation:**
- `SatelliteARViewModel.findRelevantPass(forNoradID:in:)` — static helper that selects active pass (if in-window) or next upcoming pass by NORAD ID
- Countdown formats: `"T— mm:ss"` (red, pre-AOS), `"↓ mm:ss"` (green, in-pass), `"— —:—"` (gray, post-LOS)
- Mesh throttling: regenerate countdown text mesh only when formatted string changes (1-second granularity), not every frame — same pattern as elevation text
- `monospacedDigitSystemFont` to prevent digit-width jitter during countdown
- Four new `Constants.AR` entries: `targetCountdownFontSize`, `nonTargetCountdownFontSize`, `targetCountdownOffset`, `nonTargetCountdownOffset`

**Rationale:**
- **RealityKit limitation:** `MeshResource.generateText()` only supports one color per mesh. Dual entities work around this cleanly without complex material layering.
- **Throttling:** Mesh regeneration is the performance bottleneck, not frame updates. Only regenerate when display string changes (once per second) not ten times per second.
- **Pass lookup:** Static helper avoids circular dependency between ViewModel and View. Caller owns the all-passes array.

**Impact:**
- AR labels now carry real-time timing info — users see exact countdown to AOS/LOS without leaving AR
- `SatelliteARViewModel.startTracking(allPasses:)` API changed — callers must pass full pass array
- Any future AR countdown work should use the dual-entity + throttling pattern documented here

## Project Directives

### 2026-06-22T07:10:00Z: iOS-Only Platform Constraint

**By:** Damien Hardy  
**Status:** Active  
**Scope:** Copilot instructions, package/project regeneration

**What**  
This repository is an iOS app. Include in Copilot instructions that regenerated package targets must be verified against the iOS-only platform constraint.

**Why**  
Current state: `Package.swift` incorrectly declares both iOS and macOS platforms, causing `swift test` to fail when the build attempts to compile iOS-only UI code for macOS. This is a source of contributor confusion and CI fragility. When regenerating package/project files (e.g., with `xcodegen`, `swift package init`), the iOS-only constraint must be explicitly stated in the regeneration prompt to prevent the platform declaration from reverting.

**Implications**  
- Platform targets should default to iOS 17.0+ only
- README and ARCHITECTURE.md must explicitly state "iOS only"
- CI workflows should use `xcodebuild` (not `swift test`) as the canonical path
- Any automated regeneration of Package.swift or project files must be preceded by a directive reaffirming the iOS-only constraint
