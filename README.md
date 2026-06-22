# CQ Satellites

CQ Satellites is an **iOS-only** app for amateur radio operators who want a fast view of upcoming satellite passes, pass details, and AR-assisted pointing.

## What you can do in 30 seconds

- See the next amateur satellite passes for your current location
- Check AOS, LOS, peak elevation, and azimuth details for each pass
- Filter passes by elevation and frequency availability
- Inspect AMSAT status reports for supported satellites
- Open AR mode to visualize satellite direction using the device camera

## Platform and toolchain

- **Supported platform:** iOS only
- **Minimum iOS version:** iOS 17.0
- **Minimum Xcode version:** Xcode 16 or newer
- **Swift version:** Swift 6

> This repository is not intended to support macOS, tvOS, watchOS, or cross-platform packaging.

## Canonical contributor workflow

The checked-in Xcode project is the canonical build and test surface for contributors.

```bash
git clone https://github.com/m0hdy/cq-satellites.git
cd cq-satellites
xcodebuild test \
  -project CQSatellites.xcodeproj \
  -scheme CQSatellites \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

You can also open the app directly in Xcode:

```bash
open CQSatellites.xcodeproj
```

## Project surfaces

- **`CQSatellites.xcodeproj`** — canonical app build/test entry point for day-to-day development
- **`project.yml`** — XcodeGen source of truth when the project structure or target configuration changes
- **`Package.swift`** — package metadata used for dependency definition and automation, but **not** the supported root-level contributor test path

### About `swift test`

`swift test` from the repository root is **not** the supported contributor validation path for this app. The package target includes iOS application sources, so public contributor validation should use `xcodebuild test` against `CQSatellites.xcodeproj`.

## Features

- **Upcoming passes** — view the full list of predicted passes, not just the next one
- **Live countdowns** — track time until AOS and time remaining until LOS
- **Pass details** — inspect azimuth, elevation, timing, and frequency context
- **AMSAT status integration** — surface recent community health reports where available
- **AR mode** — use the device camera and sensors to visualize satellite direction in space
- **Local filters** — persist elevation and frequency filters on-device

## Privacy and data behavior

CQ Satellites is a local-first iOS app. It does not require an account.

### Device permissions

- **Location (When In Use):** used to calculate pass predictions for your current location
- **Camera:** used only for the AR visualization mode

### Network usage

The app fetches satellite-related data from:

- **CelesTrak** — TLE orbital elements
- **AMSAT** — satellite status reports for supported satellites

### Local data

- Filter preferences are stored in `UserDefaults`
- The app keeps in-memory data needed to calculate and display passes
- No analytics, advertising SDKs, or user account systems are present in the repository

### Offline behavior

- Without network access, fresh TLE and AMSAT status data cannot be downloaded
- Without location access, the app falls back to a default location in parts of the UI rather than blocking entirely
- AR mode depends on device capabilities, location/sensor state, and camera access

## Repository layout

Primary contributor surfaces:

- `CQSatellites/` — current app source
- `CQSatellitesTests/` — current automated tests
- `docs/` — maintained project documentation

The legacy Xcode-template directories that previously duplicated the app/test structure have been removed. New work should stay within the `CQSatellites/` and `CQSatellitesTests/` paths.

## Regenerating the project

If you need to change project structure or target settings, update `project.yml` and regenerate the Xcode project with XcodeGen.

Example:

```bash
xcodegen generate
```

After regeneration, verify that the project remains **iOS-only**, that the deployment target is still iOS 17, and that the canonical `xcodebuild test` command still passes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, testing, pull request expectations, and common failure modes.

## Support and security

- Support: [SUPPORT.md](SUPPORT.md)
- Security reporting: [SECURITY.md](SECURITY.md)
- Code of conduct: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Releases and changelog

- Release process and versioning notes live in [CHANGELOG.md](CHANGELOG.md)
- App Store release automation is driven by tagged releases in GitHub Actions

## License

This project is licensed under the ISC License. See [LICENSE](LICENSE) for details.
