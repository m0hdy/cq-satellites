# Decision: Xcode Project via XcodeGen

**Author:** Dallas (iOS Dev)
**Date:** 2026-03-31
**Status:** Implemented

## Context

The project was structured as an SPM `.executableTarget` in Package.swift. This does not produce an iOS app bundle — SPM executable targets don't process Info.plist, set bundle identifiers, or support simulator/device deployment. Xcode was erroring: "Cannot index window tabs due to missing main bundle identifier."

## Decision

Use **XcodeGen** (`project.yml`) to generate a proper `SatPass.xcodeproj` with:
- iOS App target (`SatPass`) referencing all sources in `SatPass/`
- Unit test target (`SatPassTests`)
- SatelliteKit as an SPM dependency
- Bundle ID: `com.satpass.app`
- Deployment target: iOS 17.0
- Swift 6.0 with strict concurrency

Package.swift is kept for `swift build`/`swift test` CLI compatibility.

## Rationale

- XcodeGen is declarative (YAML) and reproducible — avoids brittle manual .pbxproj edits.
- `project.yml` is small, readable, and diffable. The generated `.xcodeproj` is tracked in git so the team doesn't need XcodeGen installed to open the project.
- Keeping Package.swift means CI can still use `swift test` without Xcode.

## Regeneration

After editing `project.yml`, run: `xcodegen generate`

## Impact

- **All team members:** Open `SatPass.xcodeproj` in Xcode (not Package.swift) for simulator/device builds.
- **CI:** Can use either `swift test` (Package.swift) or `xcodebuild` (SatPass.xcodeproj).
- **New dependencies:** Add to both `project.yml` (packages section) and `Package.swift`.
