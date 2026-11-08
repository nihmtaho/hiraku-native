# wp-09-settings-home — Settings and home

## Contract

- Status: blocked
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-09
- Branch / PR: `feat/wp-09-settings-home` from `develop`
- Base / head SHA: 2df7fd5 / —
- Dependencies: WP-01; WP-05; WP-06
- Required reading: DECISIONS Q-24, Q-28; DESIGN settings; COPY.md
- Blocking Q / gate: none (GATE-1 closed 2026-11-08)
- Goal: Settings screen split app-level vs profile-level, home due banner.
- Out of scope: Backup; sync.
- Files / modules allowed to change: Packages/Features/FeatureSettings, FeatureHome, App/Composition
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

font_scale and reminder change without touching profile settings; study settings persist per profile; home banner shows the due count for today.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-09 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 66 | settings | docs/plans/2026-11-08-m1a.md | open |
| 67 | home | docs/plans/2026-11-08-m1a.md | open |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Not run | | Not run | |

## Coding

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
