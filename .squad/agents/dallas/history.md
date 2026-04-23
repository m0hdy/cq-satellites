# Project Context

- **Owner:** Damien
- **Project:** iPhone app for amateur radio satellite pass tracking. Downloads Kepler/TLE data, uses current location to compute satellite passes with azimuth, elevation, countdown timers. Stretch goal: AR overlay showing satellite positions in real-time.
- **Stack:** Swift, SwiftUI, CoreLocation, ARKit, iOS
- **Created:** 2026-03-31

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-31 — Initial View Build-out

**Files touched:**
- `SatPass/Utilities/Formatters.swift` — Added `tCountdown`, `timeRemaining`, `relativePassTime`, `compassDirection`, `passDirection`, `riseDescription`, `setDescription`, `degreesWhole`
- `SatPass/Views/Components/CountdownView.swift` — Self-contained with `TimelineView` (no parent timer needed). Shows "T-mm:ss" pre-pass, "mm:ss remaining" during pass.
- `SatPass/Views/Components/AzimuthView.swift` — Full compass rewrite: 8 cardinal directions, pass arc via custom `PassArcShape`, AOS/LOS markers with labels, auto-detects shorter arc direction.
- `SatPass/Views/Components/PassRowView.swift` — Green left-edge bar for active passes, simplified "SW → NE" direction, relative time ("In 23 min").
- `SatPass/Views/PassDetailView.swift` — Hero countdown at top, large compass, signal quality bars, uses `PassDetailViewModel`. `#if os(iOS)` guard on `navigationBarTitleDisplayMode`.
- `SatPass/ViewModels/PassDetailViewModel.swift` — Added `PassQuality` enum (4 tiers based on max elevation), formatted property getters for direction/elevation/duration.

**SwiftUI patterns used:**
- `TimelineView(.periodic(from:by:))` for self-contained countdown updates (avoids Combine Timer.publish)
- Counter-rotation trick for compass labels: `.rotationEffect(.degrees(-angle)).offset(y:).rotationEffect(.degrees(angle))` keeps text upright at positioned angles.
- Custom `Shape` (`PassArcShape`) with `addArc` for drawing the pass trajectory — handles SwiftUI's flipped coordinate system for clockwise/counterclockwise determination.
- `contentTransition(.numericText())` for smooth countdown digit transitions.
- `#if os(iOS)` for `navigationBarTitleDisplayMode` since Package.swift targets both iOS and macOS.
- Explicit `Color.primary` / `Color.secondary.opacity()` in ternaries to avoid `HierarchicalShapeStyle` type ambiguity.

**Design decisions:**
- Countdown and azimuth are the hero elements (top of detail view, largest type). Ham radio ops need instant "when" and "where" at a glance.
- PassQuality maps max elevation to signal quality (≥60° excellent, ≥30° good, ≥15° fair, <15° low) — higher passes = better line of sight.
- Used 8-point compass for row view direction summary, 16-point for detailed azimuth readout.
- CountdownView owns its own TimelineView — no timer state management in parent views.

### Team Status (2026-03-31)
- **Ripley (Architecture):** Designed MVVM + SatelliteKit architecture (6 ADRs merged). 21 source files, clean build.
- **Parker (Backend):** Wired full ECI→topocentric SGP4 pipeline. Fixed SatelliteStore concurrency. Real pass data flowing.
- **Lambert (Tester):** 83 tests passing across 7 suites. Discovered SatelliteKit crash on invalid TLE (mitigated).

### 2026-03-31 — Converted to Xcode Project (XcodeGen)

**Problem:** SPM `.executableTarget` in Package.swift does not create an iOS app bundle. Xcode showed "Cannot index window tabs due to missing main bundle identifier" — no simulator/device builds possible.

**Solution:** Used XcodeGen (`project.yml`) to generate a proper `SatPass.xcodeproj` with an iOS app target.

**Files touched:**
- `project.yml` — XcodeGen spec: iOS app target "SatPass", test target "SatPassTests", SatelliteKit SPM dependency, iOS 17.0 deployment, Swift 6.0.
- `Info.plist` — Added required Xcode build variable references: `CFBundleExecutable` (`$(EXECUTABLE_NAME)`), `CFBundlePackageType` (`$(PRODUCT_BUNDLE_PACKAGE_TYPE)`), `CFBundleIdentifier` (`$(PRODUCT_BUNDLE_IDENTIFIER)`), `UILaunchScreen`, `UISupportedInterfaceOrientations`.
- `.gitignore` — Unignored `*.xcodeproj` so the generated project is tracked. Still ignoring xcuserdata/xcworkspace.

**Key decisions:**
- Kept `Package.swift` intact for `swift build` / `swift test` CLI compatibility.
- Bundle ID: `com.satpass.app` (set in project.yml build settings, Info.plist uses `$(PRODUCT_BUNDLE_IDENTIFIER)`).
- To regenerate the project after editing `project.yml`: run `xcodegen generate`.
- XcodeGen installed via `brew install xcodegen`.

### 2026-03-31 — Elevation Filter for Pass List

**Files touched:**
- `SatPass/Utilities/Constants.swift` — Added `Constants.ElevationFilter` with UserDefaults key, default minimum (10°), and preset values.
- `SatPass/ViewModels/PassListViewModel.swift` — Added `minimumElevation` property (persisted via `UserDefaults` `didSet`), `elevationFilterLabel` computed property, and updated `filteredPasses()` to apply elevation threshold alongside existing time-based filter.
- `SatPass/Views/PassListView.swift` — Added toolbar filter button, bottom bar elevation label, and `ElevationFilterSheet` with segmented picker (All, 10°, 20°, 30°, 45°).

**Design decisions:**
- Segmented picker over freeform slider — ham radio ops know exactly what elevation values matter; discrete presets are faster to use.
- Default 10° — passes below 10° max elevation are barely usable (weak signal, atmospheric QRM). Matches common ham practice.
- Persisted in `UserDefaults` — lightweight, appropriate for a single Double preference. No need for SwiftData/CoreData per ADR-005.
- Used `@Bindable` on viewModel in the sheet to get two-way binding with `@Observable` — this is the iOS 17+ pattern (not `@ObservedObject`).
- Filter label shown in both toolbar and bottom bar so it's always visible regardless of scroll position.

### 2026-03-31 — Loading Screen with Progress Phases

**Files touched:**
- `SatPass/Services/SatelliteStore.swift` — Replaced `isLoading: Bool` + `error: Error?` with `LoadingPhase` enum (idle/locating/downloading/parsing/predicting/complete/error). Added `beginLocating()` for ViewModel to signal location phase start. Split `computePasses` into two variants: `computePassesWithProgress` (per-satellite loop with phase updates for initial load) and `computePasses` (batch flatMap for refresh).
- `SatPass/Views/Components/LoadingView.swift` — New component. Animated orbiting satellite around a pulsing globe. Shows phase-specific icon (location pin → download arrow → magnifying glass → satellite). Displays progress bar + counter during prediction phase, circular spinner during download. Uses `withAnimation(.repeatForever)` for orbit and pulse.
- `SatPass/Views/PassListView.swift` — Replaced `ProgressView("Computing passes…")` with `LoadingView`. Added error state with `ContentUnavailableView` + retry button when download fails and no cached passes exist.
- `SatPass/ViewModels/PassListViewModel.swift` — Added `store.beginLocating()` call before GPS request. Added `retry(store:)` method for error recovery.

**Design decisions:**
- `LoadingPhase` is an enum with associated values (not separate Bool flags) — single source of truth for loading state. Avoids impossible states like `isLoading=true + error≠nil`.
- Two compute paths: initial load reports per-satellite progress (important for ~150 satellites × SGP4), refresh uses fast batch flatMap (user already has data, doesn't need progress).
- Each satellite's SGP4 work dispatched to `Task.detached` but loop runs on MainActor — keeps UI responsive while allowing phase updates between satellites.
- Error retry preserves the resolved `currentStation` — doesn't re-request GPS on retry, just re-fetches TLE.
- LoadingView uses SF Symbols 5 (`satellite.fill`) which requires iOS 17+ — matches our deployment target per ADR-003.

### 2026-03-31 — Satellite Frequency Display on PassDetailView

**Files touched:**
- `SatPass/Models/SatelliteFrequency.swift` — New model: `uplink`, `downlink`, `beacon` (all optional Strings), `mode` (required), `description` (optional). Matches Parker's expected shape.
- `SatPass/Services/FrequencyDatabase.swift` — Static `FrequencyDatabase.frequencies(for:)` keyed by NORAD ID. Contains stub data for ISS/SO-50/AO-91. Parker to replace with full amateur radio frequency database.
- `SatPass/ViewModels/PassDetailViewModel.swift` — Added `frequencies` computed property that reads from `FrequencyDatabase` using `pass.noradID`.
- `SatPass/Views/PassDetailView.swift` — Added "Radio" section between "Pass Info" and "Timing". Three new private components: `FrequencyEntryView`, `ModeBadge`, plus empty-state handling.

**UI design for ham operators:**
- Downlink (RX) is most prominent — bold `.body` font with green ↓ arrow. That's what you tune your receiver to.
- Uplink (TX) is secondary — `.subheadline` with orange ↑ arrow.
- Beacon shown with cyan wave icon when present.
- Mode badge is a colored capsule: FM=green, CW=orange, SSB=blue, Linear=purple, other=indigo. Immediately visible so operators know their radio setup.
- Multiple frequency entries shown as separate list rows (satellite can have repeater + beacon + transponder).
- Empty state: "No frequency data available" in secondary text — not an error, just means the satellite isn't in the database yet.

### 2026-03-31 — Satellite Frequency Display on PassDetailView

**Files touched:**
- `SatPass/Models/SatelliteFrequency.swift` — New model: `uplink`, `downlink`, `beacon` (all optional Strings), `mode` (required), `description` (optional). Matches Parker's expected shape.
- `SatPass/Services/FrequencyDatabase.swift` — Static `FrequencyDatabase.frequencies(for:)` keyed by NORAD ID. Contains stub data for ISS/SO-50/AO-91. Parker to replace with full amateur radio frequency database.
- `SatPass/ViewModels/PassDetailViewModel.swift` — Added `frequencies` computed property that reads from `FrequencyDatabase` using `pass.noradID`.
- `SatPass/Views/PassDetailView.swift` — Added "Radio" section between "Pass Info" and "Timing". Three new private components: `FrequencyEntryView`, `ModeBadge`, plus empty-state handling.

**UI design for ham operators:**
- Downlink (RX) is most prominent — bold `.body` font with green ↓ arrow. That's what you tune your receiver to.
- Uplink (TX) is secondary — `.subheadline` with orange ↑ arrow.
- Beacon shown with cyan wave icon when present.
- Mode badge is a colored capsule: FM=green, CW=orange, SSB=blue, Linear=purple, other=indigo. Immediately visible so operators know their radio setup.
- Multiple frequency entries shown as separate list rows (satellite can have repeater + beacon + transponder).
- Empty state: "No frequency data available" in secondary text — not an error, just means the satellite isn't in the database yet.

**Coordination note:** Parker is building the full frequency database simultaneously. The `FrequencyDatabase` stub I created has the same API shape Parker should use. When Parker's real database lands, it replaces the stub dictionary contents — no UI changes needed.

### 2026-03-31 — AMSAT Satellite Status Integration

**Files touched:**
- `SatPass/ViewModels/PassDetailViewModel.swift` — Added `statusReports`, `statusLoadingState` enum (idle/loading/loaded/error), `hasAMSATData` computed property, and `loadStatusReports()` async method. Lazy loading pattern with guard against repeated fetches.
- `SatPass/Views/PassDetailView.swift` — Added "Satellite Status" section between Radio and Timing. Conditional rendering (only if `hasAMSATData` is true). Shows loading spinner, report rows, empty state, or error. Uses `.task { await viewModel.loadStatusReports() }` for lazy loading on section appear. Added `StatusReportRow` component.

**UI design for community status reports:**
- Status indicator: colored circle based on report text — green for "Heard", red for "Not heard", blue for "Telemetry", gray for other.
- Report text is the primary info (e.g., "Heard", "Active") — shown prominently.
- Reporter metadata (callsign, Maidenhead grid square, time) shown as secondary caption.
- AMSAT attribution footer with tappable link to https://www.amsat.org/status/.
- Section only appears if satellite is in AMSAT database (`AMSATStatusService.hasAMSATName()`).

**Lazy loading pattern:**
- Uses `.task` modifier on the section — fetches only when section is rendered (user scrolls to detail page).
- ViewModel guards with `statusLoadingState` to prevent duplicate fetches if section re-renders.
- Loading state is separate from the main data load (doesn't block pass display).
- Default time window: 24 hours of reports via `Constants.AMSAT.defaultHours`.

**Coordination:** Parker is building `AMSATStatusReport` model, `AMSATStatusService` actor, and `Constants.AMSAT` simultaneously. I'm using the API shape specified in the task — if Parker changes the API, I'll adapt the ViewModel calls.

### 2026-04-23 — AMSAT Status Report Integration

**Dallas spawned:** Updated PassDetailViewModel and PassDetailView for AMSAT status display
- Added `statusReports`, `statusLoadingState` enum (idle/loading/loaded/error), `hasAMSATData` computed property, and `loadStatusReports()` async method to ViewModel
- Added "Satellite Status" section to PassDetailView between Radio and Timing with lazy loading
- Status indicator circles: green for "Heard", red for "Not heard", blue for "Telemetry", gray for other
- Reporter metadata: callsign, Maidenhead grid square, time
- AMSAT attribution footer with link to https://www.amsat.org/status/
- Section only appears if satellite has AMSAT data (via `AMSATStatusService.hasAMSATName()`)

**Cross-team coordination (Parker):**
- Parker created `AMSATStatusReport` model with UUID generation in `Decodable.init(from:)`
- Parker created `AMSATStatusService` actor with non-throwing error handling (returns empty array on failure)
- Parker added static NORAD→AMSAT mapping for 18 satellites (ISS-FM, AO-91, SO-50, etc.)
- Parker updated `Constants.AMSAT` with API URL, website, default 24-hour report window
- Key files: `SatPass/Models/AMSATStatusReport.swift`, `SatPass/Services/AMSATStatusService.swift`, updated `Constants.swift`

### 2026-03-31 — Feature Spawn Integration

**Dallas spawned:** elevation filter, SF Symbol + bundle ID fix, Xcode project, default London location, frequency UI, loading screen  
**Parker spawned:** frequency database with 30+ amateur radio satellites (fixed Dallas stub bugs: ISS 437.800→145.800, AO-91 uplink/downlink swap)

**ADRs added to decisions.md:**
- ADR-007: Elevation Filter UX — segmented picker over slider
- ADR-008: Xcode Project via XcodeGen — declarative, reproducible iOS app generation
- ADR-009: Built-in Frequency Database — static lookup, zero API deps, stable amateur frequency assignments
- ADR-010: LoadingPhase Enum — single source of truth for loading state, progress granularity

**Team coordination:** Orchestration logs written. Decision inbox merged (4 files). Team history updated across Dallas and Parker.
