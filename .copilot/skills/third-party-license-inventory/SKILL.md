---
name: "third-party-license-inventory"
description: "Maintain the bundled third-party license inventory and About-page listing when dependencies change"
domain: "dependency-governance"
confidence: "high"
source: "project implementation"
---

## Context

CQ Satellites renders third-party library licenses on the About screen from a bundled manifest:

- `CQSatellites/Resources/ThirdPartyLicenses.json`

The manifest is verified against `Package.resolved` by:

- `Scripts/verify-third-party-licenses.swift`

## When to use this skill

Use this skill whenever dependency changes affect any of these files:

- `Package.swift`
- `Package.resolved`
- `project.yml`
- `.github/workflows/*` when dependency resolution or package wiring changes

## Required steps

1. Inspect the dependency delta.
2. Update `CQSatellites/Resources/ThirdPartyLicenses.json`.
3. Add, edit, or remove license entries so they match the resolved dependency set.
4. Keep each entry populated with:
   - `packageIdentity`
   - `name`
   - `license`
   - `repositoryURL`
   - `licenseURL`
   - `summary`
5. Keep `AboutView` data-driven; do not hardcode the license list in the UI.
6. Run:
   ```bash
   swift Scripts/verify-third-party-licenses.swift
   ```
7. If the package set changed materially, make sure contributor-facing docs still describe the inventory workflow.

## Anti-patterns

- Leaving the manifest stale after dependency upgrades
- Removing a dependency without removing its inventory entry
- Hardcoding the license list in the About screen
- Treating the inventory as optional when dependency files changed
