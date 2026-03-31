# SGP4 Integration: Free Functions over SatelliteKit.Satellite

**Date:** 2026-03-31
**Author:** Parker
**Status:** Implemented

## Decision

Use SatelliteKit's **free functions** (`selectPropagator`, `topPosition`, `eci2geo`) instead of its `Satellite` type for orbital propagation. This avoids a naming collision where `SatelliteKit.Satellite` is unresolvable because the module name is shadowed by a `struct SatelliteKit` inside the library.

## Pipeline

1. `selectPropagator(tle:)` → creates SGP4 or SDP4 propagator (`any Propagable`)
2. `propagator.getPVCoordinates(date)` → ECI position/velocity in **meters**
3. `topPosition(julianDays:satCel:obsLLA:)` → azimuth, elevation, distance in **degrees/km**

## Impact

- All code that needs satellite position should use `selectPropagator()` + free functions
- Never reference `SatelliteKit.Satellite` by name — it won't compile
- `LatLonAlt` altitude must be in **km** (our `GroundStation` stores meters)
