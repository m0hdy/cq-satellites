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
