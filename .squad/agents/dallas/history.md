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
