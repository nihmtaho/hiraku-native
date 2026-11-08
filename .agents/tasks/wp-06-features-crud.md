# wp-06-features-crud — Folders, decks and words

## Contract

- Status: blocked
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-06
- Branch / PR: `feat/wp-06-features-crud` from `develop`
- Base / head SHA: 2df7fd5 / —
- Dependencies: WP-01; WP-02b; WP-05
- Required reading: use-cases §4.0.1, UC-01, UC-02, UC-03; ADR-18, ADR-27; COPY.md (Q-28 terms)
- Blocking Q / gate: none (GATE-1 closed 2026-11-08)
- Goal: Folder/deck/word CRUD, search, drag reorder, unsaved-change protection, note-type-driven forms.
- Out of scope: Study screens; import.
- Files / modules allowed to change: Packages/Features/FeatureFolders, FeatureDecks, FeatureWords, App/Composition
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

CRUD flows persist through the bridge; search returns paged results under 150 ms on the 50,000-note fixture; drag reorder survives restart; leaving an edited form asks before discarding; empty states render.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-06 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 58 | folders | docs/plans/2026-11-08-m1a.md | open |
| 59 | decks | docs/plans/2026-11-08-m1a.md | open |
| 60 | words | docs/plans/2026-11-08-m1a.md | open |
| 61 | protection | docs/plans/2026-11-08-m1a.md | open |

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
