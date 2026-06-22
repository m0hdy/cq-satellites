---
name: "satellitekit-propagation"
description: "How to use SatelliteKit for SGP4 orbital propagation and coordinate conversion"
domain: "orbital-mechanics"
confidence: "high"
source: "earned"
---

## Context
When computing satellite positions, passes, or topocentric coordinates (az/el) using the SatelliteKit library (gavineadie/SatelliteKit v2+).

## Patterns

### Creating a propagator
```swift
import SatelliteKit
let propagator = selectPropagator(tle: elements) // returns `any Propagable`
```
Do NOT use `SatelliteKit.Satellite` — the module name is shadowed by a struct.

### Getting ECI position at a Date
```swift
let pv = try propagator.getPVCoordinates(date)  // PVCoordinates in meters
let satECI = Vector(pv.position.x / 1000.0,     // convert to km
                    pv.position.y / 1000.0,
                    pv.position.z / 1000.0)
```

### Computing azimuth/elevation from observer
```swift
let observer = LatLonAlt(latDeg, lonDeg, altKm)  // altitude in KM
let aed = topPosition(julianDays: date.julianDate, satCel: satECI, obsLLA: observer)
// aed.azim (degrees), aed.elev (degrees), aed.dist (km)
```

### Time conversion
```swift
let jd = date.julianDate          // Date → Julian Days
let date = Date(julianDate: jd)   // Julian Days → Date
```

## Examples
See `CQSatellites/Services/PassPredictionService.swift` for the full pass prediction pipeline.

## Anti-Patterns
- ❌ `SatelliteKit.Satellite(elements:)` — compile error due to module/struct name collision
- ❌ Using PVCoordinates directly with geographic functions — must divide by 1000 (meters → km)
- ❌ Passing `GroundStation.altitude` (meters) directly to `LatLonAlt` — must convert to km
- ❌ Creating a new propagator per time step — create once per satellite, reuse across the time window
