# wp-03-fsrs — FSRS, Grade, queue

## Contract

- Status: review
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-03
- Branch / PR: `feat/wp-03-fsrs` from `develop` (PR pending)
- Base / head SHA: 70dee4b / f3b7acb
- Dependencies: WP-02a, S-2
- Required reading: ARCHITECTURE §6.2, §6.3; ADR-26; docs/reports/M0_SPIKE.md S-2; spec §FSRS
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: FSRS domain matching the 17 golden vectors, transactional Grade, BuildQueue with calendar day and limits.
- Out of scope: UI; optimizer; per-deck parameters.
- Files / modules allowed to change: core/domain/fsrs, core/domain/dayboundary, core/domain/queue, core/service, core/store, core/proto, core/gen, core/ffi, core/testdata
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
| FSRS golden vectors | `cd core && go test ./domain/fsrs/` (17/17) | 0 | f3b7acb |
| Day boundary | `cd core && go test ./domain/dayboundary/` | 0 | f3b7acb |
| Service and store | `cd core && go test -race ./service/... ./store/...` | 0 | f3b7acb |
| All core | `cd core && go vet ./... && go test -race ./...` | 0 | f3b7acb |
| Contract | `buf lint && buf breaking --against '.git#branch=develop'` | 0 | f3b7acb |
| Xcode build | `xcodebuild build -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS'` | 0 | f3b7acb |

## Coding

- `core/domain/fsrs`: FSRS-6 port matching py-fsrs 6.3.2 arithmetic (Python round-half-even intervals, 21 default weights), `Next`/`Preview` pure with `now_ms`.
- `core/domain/dayboundary`: study day 04:00 boundaries; FSRS elapsed days use it, so 23:55→00:05 stays within one day.
- Contract: `METHOD_GRADE`, `METHOD_BUILD_QUEUE`, queue messages, `GradeResponse.reinsert` (due ≤ now + 20 minutes).
- `store`: card state read/upsert, review log insert, due/new queue queries, daily new count, card existence.
- `service`: Grade in one transaction with previous-state snapshot; BuildQueue = due (learning first) + new within daily limit.
- Tests: 17 golden vectors, day boundary, queue order/limits, Grade response/log/state, bad input and missing card.

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
