# wp-03-fsrs — FSRS, Grade, queue

## Contract

- Status: blocked
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-03
- Branch / PR: `feat/wp-03-fsrs` from `develop`
- Base / head SHA: 2df7fd5 / —
- Dependencies: WP-02a, S-2
- Required reading: ARCHITECTURE §6.2, §6.3; ADR-26; docs/reports/M0_SPIKE.md S-2; spec §FSRS
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: FSRS domain matching the 17 golden vectors, transactional Grade, BuildQueue with calendar day and limits.
- Out of scope: UI; optimizer; per-deck parameters.
- Files / modules allowed to change: core/domain/fsrs, core/domain/queue, core/service/grade.go, core/service/queue.go, core/testdata
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

17/17 golden vectors match with tolerance 0; Grade writes one card_states update and one review_logs row in one transaction and re-reads inside it; queue honors day boundary, limit, 20-minute reinsert; race tests pass.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-03 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 51 | fsrs | docs/plans/2026-11-08-m1a.md | open |
| 52 | grade | docs/plans/2026-11-08-m1a.md | open |
| 53 | queue | docs/plans/2026-11-08-m1a.md | open |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| FSRS and service tests | `cd core && go test -race ./domain/fsrs/... ./domain/queue/... ./service/...` | Not run | — |

## Coding

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
