# Contributing to CQ Satellites

Thanks for your interest in improving CQ Satellites.

This repository is maintained as an **iOS-only** app. The canonical contributor workflow uses the checked-in Xcode project and `xcodebuild`, not root-level `swift test`.

## Prerequisites

- macOS with **Xcode 16 or newer**
- iOS Simulator runtime available locally
- Swift 6 toolchain (bundled with supported Xcode versions)
- Optional: [XcodeGen](https://github.com/yonaskolb/XcodeGen) if you need to regenerate the project from `project.yml`

## Getting set up

```bash
git clone https://github.com/m0hdy/cq-satellites.git
cd cq-satellites
open CQSatellites.xcodeproj
```

## Canonical test command

Run this before opening a pull request:

```bash
xcodebuild test \
  -project CQSatellites.xcodeproj \
  -scheme CQSatellites \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

This is the same workflow contributors should expect CI to validate.

## What is authoritative?

- **`CQSatellites.xcodeproj`** is the normal app build/test entry point
- **`project.yml`** is the project-definition source of truth when targets/settings change
- **`Package.swift`** defines dependency/package metadata, but **`swift test` is not the supported contributor validation path**

## Regenerating the Xcode project

If you change project structure, target settings, or package wiring:

1. Edit `project.yml`
2. Regenerate the project:
   ```bash
   xcodegen generate
   ```
3. Verify all of the following before committing:
   - The project is still **iOS-only**
   - The deployment target is still **iOS 17.0**
   - `Package.swift` does not reintroduce macOS support
   - The canonical `xcodebuild test` command still passes

## Common failure modes

### `swift test` fails from the repository root

This is expected for the app surface and is not the contributor gate. Use the documented `xcodebuild test` command instead.

### Simulator name or runtime does not exist

List local simulators with:

```bash
xcrun simctl list devices available
```

Then substitute a compatible iPhone simulator in the `xcodebuild test` command.

### Swift package dependency resolution fails in Xcode

Try either of these:

- Xcode → **File → Packages → Reset Package Caches**
- Re-run package resolution from the command line:
  ```bash
  xcodebuild -resolvePackageDependencies \
    -project CQSatellites.xcodeproj \
    -scheme CQSatellites
  ```

## Reporting bugs and requesting features

- Bugs: use the bug issue template and include iOS version, device, repro steps, and logs/screenshots when possible
- Documentation issues: use the documentation issue template
- Feature requests: use the feature request template and explain the operator use case
- Questions: prefer GitHub Discussions if enabled, otherwise use the question template
- Security issues: follow [SECURITY.md](SECURITY.md) and do **not** post vulnerabilities publicly

## Pull request expectations

Open pull requests from a focused branch and include:

- A short summary of the change
- Linked issue(s), if any
- Testing evidence (`xcodebuild test`, manual device/simulator validation, or both)
- Screenshots or screen recordings for UI changes
- Notes about project regeneration if `project.yml` or project settings changed

## Code and documentation guidelines

- Follow Swift naming and style conventions already used in the repo
- Keep views thin and push logic into models/view models/services where appropriate
- Add or update tests when behavior changes
- Keep README, CONTRIBUTING, workflow docs, and architecture docs in sync with any contributor-facing workflow changes

## Third-party license inventory

If you add, remove, or upgrade a Swift package dependency:

1. Update `CQSatellites/Resources/ThirdPartyLicenses.json`
2. Verify the entry includes the correct package identity, repository URL, and license URL
3. Run the inventory check script:
   ```bash
   swift Scripts/verify-third-party-licenses.swift
   ```
4. Confirm the About screen still renders the full list without errors

## Code of conduct

Please be respectful and constructive in all interactions. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
