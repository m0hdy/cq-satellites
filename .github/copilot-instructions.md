# Copilot instructions for CQ Satellites

## Platform contract

- This repository is an **iOS app only**.
- Do not add or regenerate macOS, tvOS, watchOS, or Catalyst targets unless a maintainer explicitly asks for it.
- Keep the deployment target aligned with the current project contract: **iOS 17.0**.
- Keep the Swift toolchain aligned with the current project contract: **Swift 6**.

## Authoritative project surfaces

- `CQSatellites.xcodeproj` is the canonical contributor build/test surface.
- `project.yml` is the source of truth when project structure or target settings change.
- `Package.swift` must stay aligned with the iOS-only platform contract.

## Validation expectations

After changing project metadata, dependencies, or generated project files:

1. Confirm `project.yml` still declares `platform: iOS`
2. Confirm `Package.swift` still declares only `.iOS(.v17)`
3. Confirm regeneration did not introduce non-iOS targets
4. Run the canonical validation command:
   ```bash
   xcodebuild test \
     -project CQSatellites.xcodeproj \
     -scheme CQSatellites \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
   ```

## Contributor workflow reminders

- Prefer `xcodebuild test` over root-level `swift test` for repository validation.
- Keep README, CONTRIBUTING, architecture docs, and workflows aligned with the real contributor path.
- Do not remove or weaken privacy/security/support documentation when touching public-facing repo surfaces.
