# wp-04-kana — Kana normalization and matching

## Contract

- Status: blocked
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-04
- Branch / PR: `feat/wp-04-kana` from `develop`
- Base / head SHA: 2df7fd5 / —
- Dependencies: WP-01
- Required reading: DECISIONS Q-21; spec §7.2
- Blocking Q / gate: none (GATE-1 closed 2026-11-08)
- Goal: Roma-ji to kana, Q-21 option B normalization, per-character match with golden table.
- Out of scope: Typing UI.
- Files / modules allowed to change: core/domain/kana, core/testdata/kana_golden.json
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

Dakuten and っ are strict; ー and long vowels tolerated; repeated-character folding applies; per-character match returns one flag per answer character; golden table passes.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-04 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 54 | normalize | docs/plans/2026-11-08-m1a.md | open |
| 55 | match | docs/plans/2026-11-08-m1a.md | open |

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
