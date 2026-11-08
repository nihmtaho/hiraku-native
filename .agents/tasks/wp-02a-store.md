# wp-02a-store — SQLite store, migrations, repos

## Contract

- Status: blocked
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-02a
- Branch / PR: `feat/wp-02a-store` from `develop`
- Base / head SHA: 2df7fd5 / —
- Dependencies: WP-01
- Required reading: ARCHITECTURE §3, §6; ADR-23, ADR-27, ADR-28, ADR-32; DECISIONS Q-19, Q-24
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: Store with WAL, user_version migrations, repositories, soft delete and duplicate rules, settings scope.
- Out of scope: Bridge and FFI dispatch; UI.
- Files / modules allowed to change: core/store, core/domain/notetype
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

PRAGMA user_version 1 after open; CRUD, paging and substring search on search_text tests pass (FTS5 only if S-1 fails); deleted rows hidden from lists and duplicate checks, purged after 30 days; no app-level settings rows in DB; race tests pass.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-02a section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 44 | schema | docs/plans/2026-11-08-m1a.md | open |
| 45 | repos | docs/plans/2026-11-08-m1a.md | open |
| 46 | soft-delete | docs/plans/2026-11-08-m1a.md | open |
| 47 | notetype | docs/plans/2026-11-08-m1a.md | open |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Store and notetype tests | `cd core && go test -race ./store/... ./domain/notetype/...` | Not run | — |
| Migration version | `manual: PRAGMA user_version = 1 after open` | Not run | — |

## Coding

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
