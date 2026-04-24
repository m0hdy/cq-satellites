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

### 2026-04-23 — Landscape Orientation Support

**Files touched:**
- `Info.plist` — Added `UIInterfaceOrientationLandscapeLeft` and `UIInterfaceOrientationLandscapeRight` to `UISupportedInterfaceOrientations` (was portrait-only).
- `SatPass/Views/Components/AzimuthView.swift` — Made `compassSize` dynamic via `@Environment(\.verticalSizeClass)`: 150pt in landscape (compact height), 200pt in portrait. Reduced vertical padding in landscape.
- `SatPass/Views/Components/CountdownView.swift` — Added `verticalSizeClass` environment. Countdown font: 40pt landscape, 56pt portrait. Reduced vertical padding in compact height.
- `SatPass/Views/Components/LoadingView.swift` — Split layout: portrait keeps original VStack, landscape uses HStack (globe left, text right) with 0.85 scale orbital animation. Both share `.onAppear` animations.
- `SatPass/Views/PassListView.swift` — Filter sheet detent changed from `.height(380)` only to `.medium` + `.height(380)` so the sheet works in landscape where screen height < 380pt.

**SwiftUI patterns used:**
- `@Environment(\.verticalSizeClass)` is the primary landscape detection: `.compact` = landscape on iPhone.
- Conditional layout branching via `Group { if verticalSizeClass == .compact { ... } else { ... } }` for LoadingView.
- Computed properties for dynamic sizing (`compassSize`, `countdownFontSize`) — cleaner than inline ternaries.
- `.presentationDetents([.medium, .height(380)])` — SwiftUI picks the best-fit detent automatically.

**Design decisions:**
- Compass shrinks from 200→150pt in landscape — still large enough to read AOS/LOS/cardinals, but doesn't eat the entire viewport on a ~350pt-tall landscape screen.
- Countdown font shrinks from 56→40pt — still hero-sized and instantly readable, but leaves room for the rest of the detail view.
- LoadingView goes side-by-side in landscape — vertical stacking wastes horizontal space and clips vertically.
- PassDetailView and PassListView didn't need layout changes — List scrolls naturally in both orientations.
- PassRowView is fine as-is — HStack layout adapts to width automatically.
- All portrait layouts are completely unchanged — landscape is purely additive.

### 2026-04-23 — AR Satellite Overlay Implementation

**Files touched:**
- `SatPass/AR/SatelliteARViewModel.swift` — Full replacement of placeholder. `@MainActor @Observable` class with 10Hz update loop using `SatelliteTracker`. Tracks target satellite position and all visible satellites. Uses `Task` with `Task.sleep(nanoseconds:)` for non-blocking update interval. `[weak self]` in Task closure to prevent retain cycles.
- `SatPass/AR/SatelliteARView.swift` — Full replacement of placeholder. SwiftUI view wrapping ARKit/RealityKit. `ARViewContainer` (UIViewRepresentable) with Coordinator managing entity lifecycle. `#if os(iOS)` / `#else` guard for macOS fallback since ARKit is iOS-only.
- `SatPass/Views/PassDetailView.swift` — Added `@Environment(SatelliteStore.self)`, `@State showARView`, toolbar ARKit button, `.fullScreenCover` for AR view. Explicitly passes `store` environment to fullScreenCover.
- `Info.plist` — Added `NSCameraUsageDescription` for camera permission.

**ARKit/RealityKit patterns:**
- `ARWorldTrackingConfiguration` with `worldAlignment = .gravityAndHeading` — X=east, Y=up, Z=south, aligned with magnetic north. Matches `SatellitePosition.arDirection` coordinate system.
- Entity hierarchy per satellite: parent Entity (positioned at `arDirection * markerDistance`) → sphere child (ModelEntity) + labelParent child (Entity, billboarded) → textEntity child (ModelEntity with generateText).
- Billboard effect: `labelParent.look(at: cameraPos, from:, relativeTo: nil)` + 180° Y-axis rotation (text faces +Z, look orients -Z toward target).
- Text mesh recreation throttled by tracking `lastRenderedElevations` per satellite — only regenerates text when rounded elevation changes by ≥1°.
- Stale entity cleanup: tracks `activeIDs` set per frame, removes entities for satellites that left visibility.
- `UnlitMaterial(color: .white)` for text labels — visible against any sky background without lighting artifacts.

**Design decisions:**
- Target satellite: green sphere (0.3 radius), larger text (0.15 font), placed 0.8 above sphere.
- Other satellites: blue sphere (0.15 radius), smaller text (0.1 font), placed 0.5 above sphere.
- Bottom info panel: `.ultraThinMaterial` background, shows compass direction (using `Formatters.compassDirection`), elevation, distance, above/below horizon status.
- Close button top-left, visible satellite count top-right.
- AR view works in both portrait and landscape (per ADR-006 discussion — camera feed rotates naturally with ARKit).
- `LocationService` created locally in AR view — gets current position on appear, falls back to London default.
- `SatelliteStore` passed explicitly via `.environment(store)` on fullScreenCover to guarantee propagation.

**Platform guards:**
- `#if os(iOS)` wraps entire AR view implementation. macOS gets `ContentUnavailableView` fallback.
- PassDetailView AR button and fullScreenCover wrapped in `#if os(iOS)`.
- ViewModel needs no platform guard (no ARKit/RealityKit imports).
- `swift build` (macOS target) and `swift test` both pass cleanly (83 tests).

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
