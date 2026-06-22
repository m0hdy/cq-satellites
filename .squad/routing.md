# Work Routing

How to decide who handles what.

## Routing Table

| Work Type | Route To | Examples |
|-----------|----------|----------|
| Architecture & design | Ripley | System design, module boundaries, data flow |
| Code review | Ripley | Review PRs, check quality, architectural fitness |
| iOS UI & views | Dallas | SwiftUI views, navigation, layout, animations |
| CoreLocation & GPS | Dallas | Location permissions, heading, compass |
| ARKit & AR overlay | Dallas | AR scene, satellite positioning in 3D space |
| Orbital mechanics | Parker | SGP4 propagation, pass prediction, azimuth/elevation |
| TLE data & parsing | Parker | CelesTrak fetch, TLE format parsing, data models |
| Data layer & caching | Parker | Satellite data storage, refresh logic, offline support |
| Testing | Lambert | Write tests, find edge cases, verify orbital math |
| Test validation | Lambert | Compare predictions against reference data |
| Open source readiness | Ash | README, CONTRIBUTING, governance, contributor workflow clarity |
| Governance & community | Ash | CODEOWNERS, PR template, changelog policy, support/security surfaces |
| Scope & priorities | Ripley | What to build next, trade-offs, decisions |
| RAI review | Rai | Content safety, privacy/bias review, credential scanning |
| Session logging | Scribe | Automatic — never needs routing |

## Issue Routing

| Label | Action | Who |
|-------|--------|-----|
| `squad` | Triage: analyze issue, assign `squad:{member}` label | Lead |
| `squad:{name}` | Pick up issue and complete the work | Named member |

### How Issue Assignment Works

1. When a GitHub issue gets the `squad` label, the **Lead** triages it — analyzing content, assigning the right `squad:{member}` label, and commenting with triage notes.
2. When a `squad:{member}` label is applied, that member picks up the issue in their next session.
3. Members can reassign by removing their label and adding another member's label.
4. The `squad` label is the "inbox" — untriaged issues waiting for Lead review.

## Rules

1. **Eager by default** — spawn all agents who could usefully start work, including anticipatory downstream work.
2. **Scribe always runs** after substantial work, always as `mode: "background"`. Never blocks.
3. **Quick facts → coordinator answers directly.** Don't spawn an agent for "what port does the server run on?"
4. **When two agents could handle it**, pick the one whose domain is the primary concern.
5. **"Team, ..." → fan-out.** Spawn all relevant agents in parallel as `mode: "background"`.
6. **Anticipate downstream work.** If a feature is being built, spawn the tester to write test cases from requirements simultaneously.
7. **Issue-labeled work** — when a `squad:{member}` label is applied to an issue, route to that member. The Lead handles all `squad` (base label) triage.
