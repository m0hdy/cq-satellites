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

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction
