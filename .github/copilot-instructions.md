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

After changing project metadata, dependencies, generated project files, or contributor-facing documentation:

1. Confirm `project.yml` still declares `platform: iOS`
2. Confirm `project.yml` still declares `deploymentTarget.iOS: "17.0"`
3. Confirm `project.yml` still declares `SWIFT_VERSION: "6.0"`
4. Confirm `Package.swift` still declares only `.iOS(.v17)`
5. Confirm regeneration did not introduce macOS, tvOS, watchOS, or Catalyst targets
6. Confirm `README.md`, `CONTRIBUTING.md`, workflows, and other contributor-facing docs still describe the same iOS 17+ / Swift 6 / Xcode-based workflow
7. Run the canonical validation command:
   ```bash
   xcodebuild test \
     -project CQSatellites.xcodeproj \
     -scheme CQSatellites \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
   ```

## Dependency and license inventory workflow

If a change touches `Package.swift`, `Package.resolved`, `project.yml`, or dependency-related workflow wiring:

1. Read `.copilot/skills/third-party-license-inventory/SKILL.md` before making changes.
2. Update `CQSatellites/Resources/ThirdPartyLicenses.json` to match the resolved dependency set.
3. Run `swift Scripts/verify-third-party-licenses.swift`.
4. Confirm the About screen still renders the inventory from the bundled manifest.
5. Treat a stale or missing inventory entry as a review blocker for dependency PRs.

## Pull request review guardrails

When reviewing a pull request, pay extra attention to changes in:

- `project.yml`
- `Package.swift`
- `CQSatellites.xcodeproj`
- `.github/workflows/`
- `README.md`
- `CONTRIBUTING.md`
- `docs/ARCHITECTURE.md`
- `.github/copilot-instructions.md`
- `CQSatellites/Resources/ThirdPartyLicenses.json`
- `Scripts/verify-third-party-licenses.swift`

For any pull request that touches those files, reviewers should explicitly verify all of the following:

1. The repository is still templated for **iOS only**
2. No unsupported platform target has been added back anywhere
3. The minimum supported OS is still **iOS 17+** unless a maintainer intentionally changes the platform contract
4. Swift/toolchain expectations remain aligned with **Swift 6** and the documented Xcode workflow
5. Contributor instructions, CI, and project metadata all still agree with one another
6. Any regeneration or template change did not silently reintroduce cross-platform drift
7. Dependency changes kept the third-party license inventory and verification script in sync

If a pull request changes the platform contract intentionally, the reviewer should expect the PR description to explain:

- why the platform/version change is needed
- which files were updated to keep the contract aligned
- what validation was run to confirm the new contract

## Contributor workflow reminders

- Prefer `xcodebuild test` over root-level `swift test` for repository validation.
- Keep README, CONTRIBUTING, architecture docs, and workflows aligned with the real contributor path.
- Do not remove or weaken privacy/security/support documentation when touching public-facing repo surfaces.
