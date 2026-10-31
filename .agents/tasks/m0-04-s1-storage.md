# m0-04-s1-storage — Spike S-1 (Go slice): SQLite performance on 50k words / 200k logs, MacBook only

## Contract

- Status: done (merged via PR 6)
- Owner: hiraku-coder
- Milestone / WP: M0 / S-1 (Go half; feeds GATE-1)
- Branch / PR: none; working tree only (the tree already carries the uncommitted `.agents/` migration and the Spike 0/S-2 files — do not commit)
- Base / head SHA: `develop` = `62502e9e0996f6f8222c908c67714d725195e33e` at task start; `develop` moved to `b37073e` (PR #5, agent-config restructure) during execution — the task changes remain uncommitted
- Dependencies: none. Uses the driver chosen in `m0-02-mattn` (`github.com/mattn/go-sqlite3 v1.14.52`) and must not change it.
- Required reading: `docs/product/spec.md` §4 (schema), §7.3 (queue build, study day), §3.3 S-1/S-1 bổ sung, NFR-002/NFR-003/SC-006, §7.1 (grade); `docs/architecture/DECISIONS.md` ADR-23/ADR-24/ADR-27/ADR-32 and §5; `AGENTS.md` G1–G8
- Blocking Q / gate: Q-11 chốt một phần — **MacBook của PO only**; iPhone/iPad numbers must be recorded as "chưa xác minh". S-1 is a GATE-1 item.
- Goal: measure, on the MacBook, whether the Go core with `mattn/go-sqlite3` reaches NFR-002's storage-side targets at 50.000 từ + 200.000 log on the spec §4 schema, and decide the NFR-003 integrity-check policy and the `search_text` index.
- Out of scope: Swift app, 60 fps scrolling (needs UI), XCFramework/S-8, real FSRS scheduling (S-2 chose self-implementation — do not implement FSRS; the grade transaction benchmark may write a fixed next state), production `core/store` package and migrations, backup/export, iCloud.
- Files / modules allowed to change: `core/spike/**` (new `core/spike/storage/` package and fixture), `core/go.mod`, `core/go.sum` (no new module expected), `docs/reports/M0_SPIKE.md` (new `## S-1` section), `CHANGELOG.md` `[Unreleased]`, `ROADMAP.md` §11, `ROADMAP hiraku — Kanban.html`, `.agents/tmp/**` (scratch DB files, gitignored).
- Permissions or PO decisions granted: measure on the PO MacBook only (Q-11, 2026-10-30). Driver `mattn/go-sqlite3` already approved (ADR-32, pending PO paste). No network needed beyond an already-cached module.

## Acceptance criteria

1. **Fixture**: a deterministic generator (fixed seed) creates 50.000 notes, 50.000 cards, 50.000 `card_states` and 200.000 `review_logs` across ~50 decks / 2 folders, with the spec §4 tables and indexes that matter for the measured queries (`folders`, `decks`, `note_types`, `note_type_fields`, `card_templates`, `notes`, `cards`, `card_states`, `review_logs`, `settings`). Records the exact schema DDL used and the DB file size on disk after creation and after a `PRAGMA wal_checkpoint(TRUNCATE)` + `VACUUM`.
2. **Cold open** (NFR-002 < 1,5 s, storage side): time `sql.Open` + first query with `PRAGMA quick_check` vs `PRAGMA integrity_check`, WAL on, on the 50k/200k DB. Report both, plus the time with no integrity check, 5 runs each; state the recommendation for NFR-003.
3. **Queue build** (NFR-002 < 200 ms): one query implementing spec §7.3 rules 1–3 (due learning/relearning before review, then due, then new limited by `new_cards_per_day`), for a study day with a realistic mix; 20 runs, report median and p95.
4. **Search** (NFR-002 < 150 ms): `search_text` lookup for 1, 2 and 3-character queries (prefix and substring) against 50k rows, both with a plain `LIKE '%…%'` and with an FTS5 index over `search_text`; 20 runs each, median and p95. Recommend one and state the index/migration cost.
5. **Grade transaction**: one transaction that reads `card_states`, writes the next state, inserts one `review_log`, and commits; 100 runs; report median/p95 and confirm no lost-write path (single writer, `busy_timeout`). WAL mode, `PRAGMA synchronous` value stated.
6. **ChangeSet reload (ADR-24, Go side only)**: time the query that returns rows changed since a revision (e.g. `updated_at > ?` scan over the 50k notes plus the review log tail) and report the cost; state explicitly that the 60 fps UI reload is **not** measured here and stays "chưa xác minh".
7. **Verdict per NFR-002 storage targets**: Đạt/Không đạt for cold open, queue build, search, each with the actual number against the threshold; SC-006 remains "chưa xác minh" because no device and no UI were involved.
8. **Evidence**: `docs/reports/M0_SPIKE.md` `## S-1` with the exact command, exit code, machine description (`sw_vers`, chip, RAM), Go version, driver version, every number, and a "không chạy / chưa xác minh" list. Benchmark code lives in `core/spike/storage` and `go test -race ./...` stays green.
9. **Docs/status**: CHANGELOG `[Unreleased]` entry; S-1 row `rv` in `ROADMAP.md` §11 and the Kanban raw array (same value, do not set `dn`).

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Machine + versions | `sw_vers`, `sysctl -n machdep.cpu.brand_string hw.memsize`, `go version` | Not run | |
| Fixture + DB size | `go test -run TestBuildFixture -v ./spike/storage` (cwd `core/`) | Not run | |
| Cold open | `go test -run TestColdOpen -v -count=1 ./spike/storage` | Not run | |
| Queue build | `go test -run TestQueueBuild -v -count=1 ./spike/storage` | Not run | |
| Search LIKE vs FTS5 | `go test -run TestSearch -v -count=1 ./spike/storage` | Not run | |
| Grade transaction | `go test -run TestGradeTx -v -count=1 ./spike/storage` | Not run | |
| ChangeSet reload | `go test -run TestChangeSetQuery -v -count=1 ./spike/storage` | Not run | |
| No regression | `go test -race ./...` (cwd `core/`) | Not run | |
| Status consistency | `node .agents/skills/hiraku-wp-status/scripts/wp-status.mjs --check` | Not run | |

## Coding

Round 1 (2026-10-30): fixture 50k/50k/50k/200k, all measurements run on the PO MacBook (M4 Pro, macOS 27.2), report `docs/reports/M0_SPIKE.md` §S-1. Storage-side NFR-002 Đạt on the MacBook; SC-006 unverified.

Round 2 fixes (reviewer `ses_e724661f1ffeOaIt4aLQJmtTlE`, CHANGES_REQUESTED):

- F1 `core/spike/storage/grade_test.go`: `TestGradeTx` fails on a second run (`UNIQUE constraint failed: review_logs.id`) because the log ID is derived from a fixed `now`. Make each run self-contained (build its own fixture/copy, or derive unique IDs from an insert counter), and make the test independent of run order.
- F2 report §S-1: the fixture distribution is 70% Review / 20% Learning / 10% Relearning with Review `due ±100 ngày` and Learning/Relearning `±60 phút`; fix the text and state the real due population (~32.5k cards).
- F3 report §S-1: the queue query is capped with `LIMIT 1000`, which §7.3 does not have. Measure the uncapped query too (the reviewer's `sqlite3` probe suggests ~+8 ms), state the population and the `firstReviewsToday` cost separately from the main query.
- F4 `core/spike/storage/*_test.go`: add the `deleted_at IS NULL` filters and the soft-deleted handling the real rule set needs (queue, new-card anti-join, `review_logs` count, search, and the ChangeSet query, which currently can never return soft-deleted rows). Costs ~0 on a fixture without deleted rows; say so.
- F5/F6/F7/F9 report: state the average `search_text` length (22 B) and that real data is longer; mark `idx_notes_updated` as an index the spike added, not part of spec §4; add "open after crash/WAL recovery" and "FTS5 write/trigger cost" to the "chưa xác minh" list; fix the 4,5% arithmetic; note that the ChangeSet log counts depend on `TestGradeTx` having run first.
- F8: either keep `s1-run.log`/`race*.log` in `.agents/tmp/m0-04/` or remove their paths from the report; do not cite files that do not exist.

## Independent review

- Reviewer / session: `ses_e724661f1ffeOaIt4aLQJmtTlE`
- Revision: working tree (no commit), base `62502e9e0996f6f8222c908c67714d725195e33e`
- Verdict: **PASS** (draft — working tree only, not merge-eligible) after round 2
- Findings: round 1 CHANGES_REQUESTED — F1 `TestGradeTx` not re-runnable (`review_logs.id` collision), F2 wrong fixture distribution in the report, F3 undocumented `LIMIT 1000` and unstated due population, F4 missing `deleted_at` handling, F5 short `search_text`, F6 stray `idx_notes_updated`, F7 cold open not after crash + missing from the unverified list, F8 cited log files absent, F9 arithmetic and run-order dependency. All fixed and confirmed; only non-blocking notes remain (`copyFixture` does not copy `-wal`; host load makes queue numbers ~10% slower; `.serena/` untracked).
- Checks the reviewer actually ran: two consecutive `TestGradeTx` runs 0, queue/search/ChangeSet measurements 0, FTS5 0, `go test -race -count=1 ./...` 0, `sqlite3` population counts matching the report, `wp-status --check` 0.
- Reviewer conclusion: storage-side NFR-002 Đạt on the MacBook with the reported margins; SC-006 unverified.

## Decision

- Storage side on the MacBook: cold open, queue build and search all Đạt; uncapped queue median 149,1 ms (p95 150,6 ms) leaves ~1,3× margin to the 200 ms target, so the device half of S-1 can still fail NFR-002 — recorded, not assumed away.
- NFR-003 recommendation: synchronous `quick_check` on open (90,0 ms) plus background `integrity_check` (324,1 ms).
- Search: keep `LIKE` on `search_text`, no FTS5 in M1–M3 (trigram cannot serve 1–2 character queries; +4,76 MB and a driver build tag that would affect the iOS archive).

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: required in working tree
- Status: not requested
- CI / integration revision:
- Gate / PO approval:
- Actions actually taken / evidence from the target system:

## Next

Review PASS on the working tree. Remaining before `dn`: PO-only edits in `docs/architecture/DECISIONS.md` (ADR-32/ADR-12/ADR-23, ADR-26) and `AGENTS.md:28`, plus deciding whether the spike-only `idx_notes_updated` and the `quick_check`-on-open policy go into spec §4 and NFR-003.
Still open and not measurable here: iOS/iPadOS numbers (Q-11), 60 fps scroll and ChangeSet reload in the UI, open after crash/WAL recovery, FTS5 write cost, S-1 bổ sung. Those need a runnable Swift app and a device.
