# wp-07-study — Study session and flashcard

## Contract

- Status: blocked
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-07
- Branch / PR: `feat/wp-07-study` from `develop`
- Base / head SHA: 2df7fd5 / —
- Dependencies: WP-01; WP-03; WP-05
- Required reading: UC-04, UC-06, UC-07; ADR-27; spec study flow
- Blocking Q / gate: none (GATE-1 closed 2026-11-08)
- Goal: StudyKit session, 2/4-button flashcard, done screen, card face by note type.
- Out of scope: Typing; stats.
- Files / modules allowed to change: Packages/StudyKit, Packages/Features/FeatureStudy, FeatureFlashcard
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

Session builds from the queue, grades through the bridge, shows done screen at zero, handles empty queue and last card; card face follows the note-type template.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-07 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 62 | studykit | docs/plans/2026-11-08-m1a.md | open |
| 63 | flashcard | docs/plans/2026-11-08-m1a.md | open |

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
