# m0-02-mattn — Spike 0 retry with mattn/go-sqlite3 (no `net`)

## Contract

- Status: done (merged via PR 6)
- Owner: hiraku-coder
- Milestone / WP: M0 / Spike 0 (blocks S-8)
- Branch / PR: none; working tree only (the tree already carries the uncommitted `.agents/` migration, do not commit it)
- Base / head SHA: `develop` = `62502e9e0996f6f8222c908c67714d725195e33e` at task start; `develop` moved to `b37073e` (PR #5, agent-config restructure) during execution — the task changes remain uncommitted
- Dependencies: `m0-01-spike0` (modernc built but failed the G5 `net` check)
- Required reading: `docs/product/spec.md` §3.3, `docs/architecture/DECISIONS.md` ADR-12/ADR-20/ADR-21/ADR-26 and §5, `AGENTS.md` G1–G8, `docs/process/AGENT_WORKFLOW.md` §2
- Blocking Q / gate: GATE-1 item; Q-11 partial — iOS results stay build-only
- Goal: replace `modernc.org/sqlite` with `github.com/mattn/go-sqlite3` and prove the dependency graph no longer contains `net`, while all three Apple slices still build.
- Out of scope: schema, migrations, RPC, Swift app, XCFramework, performance numbers, committing the `.agents/` migration.
- Files / modules allowed to change: `core/go.mod`, `core/go.sum`, `core/ffi/ffi.go`, `core/spike/sqlite_smoke_test.go`, `core/scripts/spike-build.sh`, `docs/reports/M0_SPIKE.md`, `CHANGELOG.md` (`[Unreleased]`), `ROADMAP.md` §11, `ROADMAP hiraku — Kanban.html`.
- Permissions or PO decisions granted: PO chose "Chuyển sang mattn/go-sqlite3" on 2026-10-30, per `docs/architecture/DECISIONS.md` §5. Do not edit `docs/architecture/DECISIONS.md` (protected); the ADR patch is for the PO.

## Acceptance criteria

- `core/go.mod` requires `github.com/mattn/go-sqlite3` at a pinned version and no longer requires `modernc.org/sqlite`.
- The smoke test still passes: open `:memory:`, create table, insert `hiraku`, read back, assert.
- `go list -deps ./...` from `core/` prints no package whose import path is exactly `net` (also report `net/netip`, `net/url` if present).
- `bash core/scripts/spike-build.sh` exits 0 and produces `core/.spike/{ios_arm64,iossimulator_arm64,darwin_arm64}.a`; each archive contains `sqlite3` symbols.
- The build script sets `CC` per SDK with `xcrun --sdk iphoneos|iphonesimulator --find clang`; record whether cgo needed extra sysroot flags.
- Every result is Đạt/Không đạt with command, exit code and artifact path; iOS labelled "build verified, not device verified".
- If a slice fails, capture the exact compiler error, stop that slice, and return PARTIAL; never fall back to modernc or a non-cgo driver.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Driver swap | `go get github.com/mattn/go-sqlite3@latest`, `go mod tidy` (cwd `core/`) | PASS — `v1.14.52`; `modernc` gone from `go.mod`/`go.sum` | working tree 2026-10-30 |
| No `net` | `go list -deps ./...` filtered for `(^|/)net$` (cwd `core/`) | PASS — no exact `net`; `net/netip`, `net/url` remain via mattn DSN parsing | Lead re-ran 2026-10-30 |
| Host smoke | `go test -race ./...` (cwd `core/`) | PASS — `ok hiraku/core/spike` | Lead re-ran 2026-10-30 |
| Apple slices | `bash core/scripts/spike-build.sh` (cwd root) | PASS (build-only) — 3 archives, `sqlite3` symbols present | Lead re-ran 2026-10-30 |

## Coding

Round 1 (2026-10-30): driver swapped to `github.com/mattn/go-sqlite3 v1.14.52`, smoke test PASS, no exact `net`, 3 Apple slices build. Reviewer returned CHANGES_REQUESTED; round 2 fixes F2–F6 below. Round 1 report: `docs/reports/M0_SPIKE.md` §Spike 0.

## Round 3 fixes (coder, working tree)

Round 2 review (`ses_e738b31a1ffeQc4WmtE5roCbju`) confirmed F1, F3–F6; remaining documentation gaps:

- F7 Kanban driver text: `ROADMAP hiraku — Kanban.html:207` (`S-1 + S-7`), `:214` (`S-1 bổ sung`), `:235` (`WP-02a`) still say `modernc`; use `github.com/mattn/go-sqlite3` and `ADR-23, ADR-32` in the same field shape. `:190` risk `F-19` ("cần xác minh sớm modernc build được cho iOS") is resolved by Spike 0 — rewrite that risk clause to the remaining risk (`S-1/S-8` unsolved), keeping the JSON shape valid.
- F8 GATE-1 wording not applied: `ROADMAP.md:77` and `:182` say `ADR-20, 21, 23, 24, 26`; change to `ADR-20, 21, 24, 26, 32` (ADR-23 is replaced).
- F9 `docs/product/spec.md:584` SC-012 still requires "golden test pass cho cả hai driver". With modernc rejected that is unachievable; rewrite SC-012 to the driver swap being invisible: golden tests and Swift code unchanged across the switch.

## Round 2 fixes (coder, working tree)

- F2 stale driver name: replace `modernc.org/sqlite` with `github.com/mattn/go-sqlite3` and reference ADR-32 where the ADR is cited, in `docs/product/spec.md` (lines ~32, 70, 84, 119, 137, 138), `docs/architecture/ARCHITECTURE.md` (~24, 50, 72) and `ROADMAP.md` (~61, 70, 100). Do not edit `docs/architecture/DECISIONS.md`. Also update G5 in `docs/architecture/ARCHITECTURE.md` (~198, ~642) to the ADR-32 allowlist wording: allowed `net/url`/`net/netip` only; forbidden `net`, `net/http`, `net/rpc` and other network packages; hiraku code imports none of them.
- F3 `core/scripts/spike-build.sh`: `rm -f "$out/<slice>.a"` before each `go build` so a failed slice cannot leave a stale archive that looks like success.
- F4 `core/scripts/spike-build.sh`: macOS slice uses `CC="$(xcrun --sdk macosx --find clang)"` and `MACOSX_DEPLOYMENT_TARGET=26.0` (ADR-13), not the ambient `cc`.
- F5 `ROADMAP.md` §11 + `ROADMAP hiraku — Kanban.html`: set Spike 0 to `rv` (task is in review); do not mark `dn` before review PASS and PO ADR-32. Update the "Báo cáo spike" row note when appropriate; always use the same value in both files.
- F6 `CHANGELOG.md` `[Unreleased]`: drop the `(Spike 0, chưa có PR)` suffix; the PR number is added by the Shipper.

## PO action — `docs/architecture/DECISIONS.md` (protected; paste by PO)

1. In §2.1, set ADR-23 status to `**Đã thay thế bởi ADR-32**`.
2. In the ADR-23 section heading, add `*(đã thay thế bởi ADR-32)*`.
3. Add after ADR-31:

```markdown
### ADR-32 — SQLite qua `mattn/go-sqlite3` *(thay thế ADR-23)*
- **Bối cảnh**: Spike 0 (2026-10-30) cho thấy `modernc.org/sqlite` kéo `net` vào đồ thị qua `modernc.org/libc → github.com/google/uuid`, vi phạm G5/ADR-12. Chuyển sang `mattn/go-sqlite3` (cgo), ba slice vẫn build và không còn package `net` trong đồ thị.
- **Quyết định**: dùng `github.com/mattn/go-sqlite3` cho `core/store`; Go vẫn sở hữu DB, Swift không mở DB; migration và `PRAGMA user_version` giữ nguyên.
- **G5 áp dụng cho driver mới**: cho phép `net/url`, `net/netip` (chỉ để mattn phân tích DSN); cấm `net`, `net/http`, `net/rpc`, `net/smtp`, `net/mail` và mọi package mạng khác; mã hiraku không được import bất kỳ package `net*` nào. `check-core.sh` kiểm `go list -deps` và so với danh sách cho phép này.
- **Lý do**: ADR-21 đã bắt buộc cgo cho `core/ffi`, nên lý do "khỏi cần C toolchain" của ADR-23 không còn; mattn chỉ kéo hai package thuần cú pháp `net/url`/`net/netip` (không socket, không DNS), giữ được khả năng kiểm toán "không mạng".
- **Hệ quả**: build cần `CC` theo SDK (`iphoneos`, `iphonesimulator`, macOS) và `MACOSX_DEPLOYMENT_TARGET=26.0`; script build đặt `CC`; S-1 đo lại trên driver mới.
- **Thay thế**: ADR-23.
- **Trạng thái**: Đã chốt (PO, 2026-10-30).
```

4. Update `ROADMAP.md` §4 GATE-1 wording from `xác nhận ADR-20, 21, 23, 24, 26` to `ADR-20, 21, 24, 26, 32`.
5. In ADR-12 (`docs/architecture/DECISIONS.md` ~line 150), replace the blanket "không `net`" wording with the allowlist above so ADR-12 and ADR-32 agree.
6. In `AGENTS.md:28`, replace `modernc.org/sqlite` (ADR-23) with `github.com/mattn/go-sqlite3` (ADR-32). Protected file: PO edit.

## Round 3 findings to close

- Reviewer round 2: F7 Kanban driver text (4 rows), F8 `ROADMAP.md:77,182` GATE-1 ADR list, F9 `docs/product/spec.md:584` SC-012. Assigned to coder in "Round 3 fixes".

## Independent review

- Reviewer / session: `ses_e739a3ff2ffeKUEVVnaXwsWel1`
- Revision: working tree (no commit), base `62502e9e0996f6f8222c908c67714d725195e33e`
- Verdict: CHANGES_REQUESTED (round 1)
- Findings: F1 ADR-32/G5/ADR-12 wording must allowlist `net/url`, `net/netip` and forbid `net`/`net/http`/`net/rpc`; F2 stale `modernc` references in spec/ARCHITECTURE/ROADMAP; F3 no output removal before each slice build; F4 macOS slice uses ambient `cc` without deployment target; F5 ROADMAP/Kanban `ip` vs task `review`, stale "Báo cáo spike" and `Coding` text; F6 CHANGELOG suffix.
- Checks the reviewer actually ran: `go test -race ./...` PASS, `go vet ./...` PASS, archive symbol grep PASS, git reads. Did not run `go list -deps` or the build script (allowlist).
- Round 2 scope: F2–F6 by coder; F1 by PO in `docs/architecture/DECISIONS.md`; G5 wording in `docs/architecture/ARCHITECTURE.md` by coder.

### Round 2 verdict (`ses_e738b31a1ffeQc4WmtE5roCbju`)

CHANGES_REQUESTED — F1, F3, F4, F5, F6 resolved; F2 partly: `AGENTS.md:28` (protected), Kanban rows 190/207/214/235, `ROADMAP.md:77,182` GATE-1 list, `spec.md:584` SC-012.

### Round 3 verdict (`ses_e738b31a1ffeQc4WmtE5roCbju`)

**PASS** on the working tree. F7 (Kanban driver text + F-19 risk), F8 (GATE-1 ADR list at `ROADMAP.md:77,182`), F9 (`spec.md:584` SC-012) confirmed. No regression: `core/` untouched this round, `go test -race -count=1 ./...` exit 0, `go vet ./...` exit 0, Kanban `<script>` passes `node --check`.

Checks the reviewer actually ran (round 3): `node --check` on the Kanban script body, `go test -race -count=1 ./...` → 0, `go vet ./...` → 0, `grep modernc` over the four files, `find core -newermt` (no change).

Open items before this task can close:

1. PO-only edits in protected files: `docs/architecture/DECISIONS.md` (ADR-23 status + heading, insert ADR-32, ADR-12 allowlist wording) and `AGENTS.md:28` driver name. Until applied, Spike 0 stays `rv` in ROADMAP/Kanban.
2. Non-blocking: `ROADMAP hiraku — Kanban.html:227` (`ADR 20–26` M0b row) still lists `ADR-23` in the ADR confirmation list; same stale list F8 fixed in `ROADMAP.md`.
3. Not verified anywhere: device runtime, S-1 numbers, S-8 real `import "C"` ABI/RSS, CI (none configured).

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: required in working tree
- Status: not requested
- CI / integration revision:
- Gate / PO approval:
- Actions actually taken / evidence from the target system:

## Next

Review PASS on the working tree (round 3). Spike 0 is blocked on PO-only edits in protected files before it can be `dn`:

1. `docs/architecture/DECISIONS.md` — ADR-23 status `Đã thay thế bởi ADR-32` + heading note; insert ADR-32 (allowlist wording as in "PO action" above); ADR-12 blanket `net` wording replaced by the allowlist.
2. `AGENTS.md:28` — dependency list must name `github.com/mattn/go-sqlite3` (ADR-32) instead of `modernc.org/sqlite` (ADR-23).

After both: set Spike 0 to `dn` in `ROADMAP.md` §11 and the Kanban, then S-1 can start. Not verified by anyone: device runtime, S-1 numbers, S-8 ABI/RSS, CI (none).
