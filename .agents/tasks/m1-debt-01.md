# m1-debt-01 — M1a debt from WP-03

## Contract

- Status: review
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-03 follow-up
- Branch / PR: `fix/m1-debt` from `develop`
- Base / head SHA: 17d2c37 / 553ffa2
- Dependencies: WP-03
- Required reading: spec §7.3, ADR-26; .agents/tasks/wp-03-fsrs.md Next
- Blocking Q / gate: none
- Goal: close the recorded WP-03 debts before WP-04.
- Out of scope: UI session behavior (WP-07); optimizer work.
- Files / modules allowed to change: core/proto, core/gen, core/service, core/store, core/domain/fsrs, docs/plans, .agents/tasks
- Permissions or PO decisions granted: none needed

## Acceptance criteria

- Queue can be scoped to all, one folder, or one deck.
- Queue limit is capped so a client cannot request unbounded rows.
- FSRS has a behavior test for a review crossing 04:00 (long-term formula).
- Grade log test asserts `prev_learning_steps` and `prev_last_review`.
- `elapsed_days`/`scheduled_days` are persisted from the schedule instead of zero.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (WP-03 and WP-07 sections)
- Record and plan travel together.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| — | debt follow-up | docs/plans/2026-11-08-m1a.md | n/a |

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| All core | `cd core && go vet ./... && go test -race ./...` | 0 | 553ffa2 |
| Contract | `buf lint && buf breaking --against '.git#branch=develop'` | 0 | 553ffa2 |
| Xcode build | `xcodebuild build -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS'` | 0 | 553ffa2 |

## Coding

- Contract: `BuildQueueRequest.folder_id`/`deck_id`; store `Scope` filters due and new queries.
- Service caps queue requests at 500 and passes the scope.
- FSRS sets `ElapsedDays`/`ScheduledDays`; store persists and loads them.
- Tests: folder/deck scope, cap, cross-04:00 long-term formula, full snapshot columns, persisted day columns.

## Independent review

## Delivery

## Next

WP-04 after merge.
