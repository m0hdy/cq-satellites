import Foundation

/// Static lookup of amateur radio satellite frequencies keyed by NORAD catalog ID.
///
/// TLE data only carries orbital elements — frequency info comes from AMSAT
/// and operator community sources. This database is bundled with the app and
/// updated with releases. Frequencies sourced from AMSAT status page and
/// community reports.
enum FrequencyDatabase {

    // MARK: - Public API

    /// Returns all known frequency entries for the given NORAD catalog ID.
    static func frequencies(for noradID: String) -> [SatelliteFrequency] {
        database[noradID] ?? []
    }

    /// Whether the satellite has any known amateur radio frequencies.
    static func hasFrequencies(for noradID: String) -> Bool {
        !(database[noradID] ?? []).isEmpty
    }

    // MARK: - Database

    private static let database: [String: [SatelliteFrequency]] = {
        var db: [String: [SatelliteFrequency]] = [:]

        // -----------------------------------------------------------
        // ISS (ZARYA) — NORAD 25544
        // -----------------------------------------------------------
        db["25544"] = [
            SatelliteFrequency(
                uplink: "145.990 MHz",
                downlink: "145.800 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/V FM cross-band repeater"
            ),
            SatelliteFrequency(
                uplink: nil,
                downlink: "145.825 MHz",
                beacon: "145.825 MHz",
                mode: "FM/APRS",
                description: "APRS digipeater / packet radio"
            ),
            SatelliteFrequency(
                uplink: nil,
                downlink: "145.800 MHz",
                beacon: nil,
                mode: "FM",
                description: "Voice downlink / SSTV events"
            ),
        ]

        // -----------------------------------------------------------
        // SO-50 (SaudiSat-1C) — NORAD 27607
        // -----------------------------------------------------------
        db["27607"] = [
            SatelliteFrequency(
                uplink: "145.850 MHz (67.0 Hz CTCSS)",
                downlink: "436.795 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater — requires 67.0 Hz tone for access"
            ),
        ]

        // -----------------------------------------------------------
        // AO-91 (Fox-1B / RadFxSat) — NORAD 43017
        // -----------------------------------------------------------
        db["43017"] = [
            SatelliteFrequency(
                uplink: "145.960 MHz (67.0 Hz CTCSS)",
                downlink: "435.250 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater"
            ),
        ]

        // -----------------------------------------------------------
        // AO-92 (Fox-1D) — NORAD 43137
        // -----------------------------------------------------------
        db["43137"] = [
            SatelliteFrequency(
                uplink: "145.880 MHz (67.0 Hz CTCSS)",
                downlink: "435.350 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater (L-band uplink alternate: 1267.350 MHz)"
            ),
        ]

        // -----------------------------------------------------------
        // CAS-3H / LilacSat-2 — NORAD 40908
        // -----------------------------------------------------------
        db["40908"] = [
            SatelliteFrequency(
                uplink: "144.350 MHz",
                downlink: "437.200 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater"
            ),
            SatelliteFrequency(
                uplink: nil,
                downlink: "437.200 MHz",
                beacon: "437.200 MHz",
                mode: "CW",
                description: "CW telemetry beacon"
            ),
        ]

        // -----------------------------------------------------------
        // PO-101 / DIWATA-2 — NORAD 43678
        // -----------------------------------------------------------
        db["43678"] = [
            SatelliteFrequency(
                uplink: "145.900 MHz",
                downlink: "437.500 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater"
            ),
        ]

        // -----------------------------------------------------------
        // RS-44 (DOSAAF-85) — NORAD 44909
        // -----------------------------------------------------------
        db["44909"] = [
            SatelliteFrequency(
                uplink: "145.935–145.995 MHz",
                downlink: "435.610–435.670 MHz",
                beacon: "435.590 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "Mode B (V/U) inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // FO-99 / NEXUS — NORAD 43937
        // -----------------------------------------------------------
        db["43937"] = [
            SatelliteFrequency(
                uplink: "145.900 MHz",
                downlink: "435.900 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM digipeater"
            ),
        ]

        // -----------------------------------------------------------
        // IO-117 / GreenCube — NORAD 53106
        // -----------------------------------------------------------
        db["53106"] = [
            SatelliteFrequency(
                uplink: "435.310 MHz",
                downlink: "435.310 MHz",
                beacon: nil,
                mode: "Digipeater",
                description: "UHF digipeater — 1200/9600 baud"
            ),
        ]

        // -----------------------------------------------------------
        // TEVEL satellites — NORAD 50988 through 50998
        // -----------------------------------------------------------
        let tevelFrequency = SatelliteFrequency(
            uplink: "145.970 MHz",
            downlink: "436.400 MHz",
            beacon: nil,
            mode: "FM",
            description: "V/U FM repeater (TEVEL constellation)"
        )
        for norad in 50988...50998 {
            db[String(norad)] = [tevelFrequency]
        }

        // -----------------------------------------------------------
        // AO-7 — NORAD 7530 (oldest operational amateur satellite)
        // -----------------------------------------------------------
        db["7530"] = [
            SatelliteFrequency(
                uplink: "145.850–145.950 MHz",
                downlink: "29.400–29.500 MHz",
                beacon: "29.502 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "Mode A (V/HF) — sunlit only, no batteries"
            ),
            SatelliteFrequency(
                uplink: "432.125–432.175 MHz",
                downlink: "145.975–145.925 MHz",
                beacon: "145.975 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "Mode B (U/V) inverting — sunlit only"
            ),
        ]

        // -----------------------------------------------------------
        // XW-2A (CAS-3A) — NORAD 40903
        // -----------------------------------------------------------
        db["40903"] = [
            SatelliteFrequency(
                uplink: "145.660–145.700 MHz",
                downlink: "435.030–435.070 MHz",
                beacon: "435.045 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "Mode V/U inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // XW-2B (CAS-3B) — NORAD 40911
        // -----------------------------------------------------------
        db["40911"] = [
            SatelliteFrequency(
                uplink: "145.730–145.770 MHz",
                downlink: "435.090–435.130 MHz",
                beacon: "435.091 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "Mode V/U inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // XW-2C (CAS-3C) — NORAD 40906
        // -----------------------------------------------------------
        db["40906"] = [
            SatelliteFrequency(
                uplink: "145.795–145.815 MHz",
                downlink: "435.150–435.170 MHz",
                beacon: "435.154 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "Mode V/U inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // XW-2F (CAS-3F) — NORAD 40910
        // -----------------------------------------------------------
        db["40910"] = [
            SatelliteFrequency(
                uplink: "145.980–146.000 MHz",
                downlink: "435.330–435.350 MHz",
                beacon: "435.331 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "Mode V/U inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // JO-97 (JY1Sat) — NORAD 43803
        // -----------------------------------------------------------
        db["43803"] = [
            SatelliteFrequency(
                uplink: "145.855 MHz",
                downlink: "435.100 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater"
            ),
            SatelliteFrequency(
                uplink: "145.840–145.860 MHz",
                downlink: "435.100–435.120 MHz",
                beacon: nil,
                mode: "Linear Transponder (SSB/CW)",
                description: "V/U inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // CAS-4A (ZHUHAI-1 01) — NORAD 42761
        // -----------------------------------------------------------
        db["42761"] = [
            SatelliteFrequency(
                uplink: "145.860–145.880 MHz",
                downlink: "435.210–435.230 MHz",
                beacon: "435.220 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "V/U inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // CAS-4B (ZHUHAI-1 02) — NORAD 42759
        // -----------------------------------------------------------
        db["42759"] = [
            SatelliteFrequency(
                uplink: "145.920–145.940 MHz",
                downlink: "435.270–435.290 MHz",
                beacon: "435.280 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "V/U inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // EO-88 / FUNcube-5 (Nayif-1) — NORAD 42017
        // -----------------------------------------------------------
        db["42017"] = [
            SatelliteFrequency(
                uplink: "435.015–435.045 MHz",
                downlink: "145.960–145.930 MHz",
                beacon: "145.940 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "U/V inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // AO-73 / FUNcube-1 — NORAD 39444
        // -----------------------------------------------------------
        db["39444"] = [
            SatelliteFrequency(
                uplink: "435.130–435.150 MHz",
                downlink: "145.950–145.970 MHz",
                beacon: "145.935 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "U/V inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // NOAA 15 — NORAD 25338 (weather sat, popular with hams)
        // -----------------------------------------------------------
        db["25338"] = [
            SatelliteFrequency(
                uplink: nil,
                downlink: "137.620 MHz",
                beacon: nil,
                mode: "APT",
                description: "APT weather image downlink"
            ),
        ]

        // -----------------------------------------------------------
        // NOAA 18 — NORAD 28654
        // -----------------------------------------------------------
        db["28654"] = [
            SatelliteFrequency(
                uplink: nil,
                downlink: "137.9125 MHz",
                beacon: nil,
                mode: "APT",
                description: "APT weather image downlink"
            ),
        ]

        // -----------------------------------------------------------
        // NOAA 19 — NORAD 33591
        // -----------------------------------------------------------
        db["33591"] = [
            SatelliteFrequency(
                uplink: nil,
                downlink: "137.100 MHz",
                beacon: nil,
                mode: "APT",
                description: "APT weather image downlink"
            ),
        ]

        // -----------------------------------------------------------
        // Meteor-M N2-3 — NORAD 57166
        // -----------------------------------------------------------
        db["57166"] = [
            SatelliteFrequency(
                uplink: nil,
                downlink: "137.900 MHz",
                beacon: nil,
                mode: "LRPT",
                description: "LRPT weather image downlink"
            ),
        ]

        // -----------------------------------------------------------
        // HUSKYSAT-1 / HO-113 — NORAD 45119
        // -----------------------------------------------------------
        db["45119"] = [
            SatelliteFrequency(
                uplink: "145.910–145.950 MHz",
                downlink: "435.800–435.840 MHz",
                beacon: nil,
                mode: "Linear Transponder (SSB/CW)",
                description: "V/U linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // QO-100 / Es'hail-2 — NORAD 43700 (geostationary)
        // -----------------------------------------------------------
        db["43700"] = [
            SatelliteFrequency(
                uplink: "2400.050–2400.300 MHz",
                downlink: "10489.550–10489.800 MHz",
                beacon: "10489.500 MHz",
                mode: "Linear Transponder (SSB/CW)",
                description: "Narrowband transponder (S/X) — geostationary"
            ),
            SatelliteFrequency(
                uplink: "2401.500–2409.500 MHz",
                downlink: "10491.000–10499.000 MHz",
                beacon: nil,
                mode: "DVB-S",
                description: "Wideband transponder (digital TV) — geostationary"
            ),
        ]

        // -----------------------------------------------------------
        // FALCONSAT-3 — NORAD 30776
        // -----------------------------------------------------------
        db["30776"] = [
            SatelliteFrequency(
                uplink: "145.840 MHz",
                downlink: "435.103 MHz",
                beacon: "435.103 MHz",
                mode: "Digipeater",
                description: "BBS / digipeater on UHF"
            ),
        ]

        // -----------------------------------------------------------
        // CAS-6 / TO-108 (TIANQIN-1) — NORAD 44881
        // -----------------------------------------------------------
        db["44881"] = [
            SatelliteFrequency(
                uplink: "145.925 MHz",
                downlink: "435.600 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater"
            ),
            SatelliteFrequency(
                uplink: "145.890–145.930 MHz",
                downlink: "435.150–435.190 MHz",
                beacon: nil,
                mode: "Linear Transponder (SSB/CW)",
                description: "V/U inverting linear transponder"
            ),
        ]

        // -----------------------------------------------------------
        // AO-27 — NORAD 22825
        // -----------------------------------------------------------
        db["22825"] = [
            SatelliteFrequency(
                uplink: "145.850 MHz",
                downlink: "436.795 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater — schedule-based activation"
            ),
        ]

        // -----------------------------------------------------------
        // MESAT-1 — NORAD 55576
        // -----------------------------------------------------------
        db["55576"] = [
            SatelliteFrequency(
                uplink: "145.915 MHz",
                downlink: "435.800 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater"
            ),
        ]

        // -----------------------------------------------------------
        // HADES — NORAD 46839
        // -----------------------------------------------------------
        db["46839"] = [
            SatelliteFrequency(
                uplink: "145.925 MHz",
                downlink: "436.888 MHz",
                beacon: nil,
                mode: "FM",
                description: "V/U FM repeater"
            ),
        ]

        // -----------------------------------------------------------
        // UVSQ-SAT / LATMOS — NORAD 47438
        // -----------------------------------------------------------
        db["47438"] = [
            SatelliteFrequency(
                uplink: nil,
                downlink: "437.020 MHz",
                beacon: "437.020 MHz",
                mode: "CW",
                description: "CW telemetry beacon"
            ),
        ]

        return db
    }()
}
