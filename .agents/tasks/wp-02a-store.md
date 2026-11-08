# wp-02a-store — SQLite store, migrations, repos

## Contract

- Status: review
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-02a
- Branch / PR: `feat/wp-02a-store` from `develop` (PR 74)
- Base / head SHA: 87048cb / 3ce7ea9
- Dependencies: WP-01
- Required reading: ARCHITECTURE §3, §6; ADR-23, ADR-27, ADR-28, ADR-32; DECISIONS Q-19, Q-24
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: Store with WAL, user_version migrations, repositories, soft delete and duplicate rules, settings scope.
- Out of scope: Bridge and FFI dispatch; UI.
- Files / modules allowed to change: core/store, core/domain/notetype, core/domain/id
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
| Store and notetype tests | `cd core && go test -race ./store/... ./domain/notetype/...` | 0 | f355cbb |
| All core tests | `cd core && go test -race ./...` | 0 | f355cbb |
| Migration version | `store_test.go`: user_version = 1 after open and reopen; system note type present | 0 | f355cbb |
| Boundary scripts | `core/scripts/check-core.sh && Scripts/check-imports.sh` | 0 (caught `net/url` once and it was removed) | f355cbb |
| Contract lint | `buf lint` | 0 | f355cbb |

## Coding

- `core/store`: Open with WAL/immediate/busy timeout/foreign keys, migration runner over embedded SQL, `Repo` with `Tx`.
- Schema per spec §4 including `note_type_fields` and `card_templates`; system "Từ vựng Nhật" seeded with fixed ids.
- Repositories: folders, decks, notes/cards (create/update/delete, paging, substring search), settings, notetype field reads.
- Soft delete cascades folder → decks → notes → cards in one transaction; `PurgeDeleted`; duplicate check ignores deleted.
- Settings accept only study keys (Q-24), reject app-level keys and out-of-range values.
- Notetype validation: max 10 fields, unique names, exactly one term, one per role except text.
- UUIDv7 in `core/domain/id`; no new dependency.
- Card insert fails loudly when the note type has no template.

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
