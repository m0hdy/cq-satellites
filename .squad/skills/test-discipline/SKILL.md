---
name: "test-discipline"
description: "Swift Testing patterns for SatPass: fixtures, actor testing, orbital validation"
domain: "testing"
confidence: "high"
source: "earned"
---

## Context
Testing Swift 6.0 code with SatelliteKit dependency. Tests use Swift Testing framework (`import Testing`), not XCTest. Actor-isolated methods require `async` test functions.

## Patterns
- **Fixed reference dates**: Use `Date(timeIntervalSinceReferenceDate:)` for deterministic model tests, never `Date.now`.
- **Factory helpers**: `TestFixtures.makePass(aosOffset:losOffset:relativeTo:)` — build passes relative to a reference date to avoid time-sensitive flakiness.
- **Real TLE fixtures**: Use TLE data validated by SatelliteKit's own tests (ISS epoch 24058, INTELSAT 39 epoch 19348). Never fabricate TLE checksums manually.
- **Actor method testing**: `await service.parseTLEText(text)` — actor methods need `await` in `@Test func foo() async { }`.
- **Orbital validation**: ISS (51.6° inclination) visible from equator, NOT from poles. Use this as a physics sanity check.
- **Boundary testing**: Always test AOS/LOS exact boundaries with `isActive(at:)` — both should return `true`.

## Examples
```swift
// Deterministic pass testing
let ref = Date(timeIntervalSinceReferenceDate: 750_000_000)
let pass = TestFixtures.makePass(aosOffset: -60, losOffset: 300, relativeTo: ref)
#expect(pass.isActive(at: ref))

// Actor method testing
let service = TLEService()
let sats = await service.parseTLEText(tleText)
#expect(sats.count == 1)
```

## Anti-Patterns
- **Never pass invalid strings directly to `Satellite.init`** — SatelliteKit crashes instead of throwing. Always validate format first or test through `parseTLEText`.
- **Don't compare SatellitePass arrays with `==`** — no Equatable conformance. Compare by property.
- **Don't use `Date.now` in assertions** — leads to flaky tests. Use fixed reference dates.
