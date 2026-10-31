# m0-01-spike0 — Spike 0: modernc.org/sqlite builds for Apple slices without `net`

## Contract

- Status: blocked
- Owner: hiraku-coder
- Milestone / WP: M0 / Spike 0 (blocks S-8)
- Branch / PR: `chore/m0-01-spike0` from `develop` (no Git delivery rights; work in working-tree)
- Base / head SHA: `develop` = `62502e9e0996f6f8222c908c67714d725195e33e`; working-tree only
- Dependencies: `m0-00-toolchain` (allowlist applied)
- Required reading: `docs/product/spec.md` §3.3, `docs/architecture/DECISIONS.md` ADR-12/ADR-20/ADR-21/ADR-23, `AGENTS.md` laws G3/G5, `ROADMAP.md` §3.1
- Blocking Q / gate: GATE-1 item; Q-11 partial — iOS results are build-only, not device measurements
- Goal: prove the Go core can be built for the three Apple slices with `modernc.org/sqlite` and that the dependency graph has no `net` package.
- Out of scope: product schema, migrations, RPC contract, Swift app, XCFramework packaging, performance numbers (S-1/S-8).
- Files / modules allowed to change: `core/` only (Go module, `core/.spike/` outputs, `core/scripts/spike-build.sh`), plus `docs/reports/M0_SPIKE.md` result section and `CHANGELOG.md`/`ROADMAP.md` §11/Kanban status.
- Permissions or PO decisions granted: M0 toolchain allowlist applied and verified 2026-10-30 (`node --test .opencode/tests/*.test.mjs` = 63/63); no network besides `go get`.

## Acceptance criteria

- `core/go.mod` declares module `hiraku/core` and pins `modernc.org/sqlite` (latest stable at run time, version recorded).
- `go list -deps ./...` from `core/` lists no package whose import path is or ends in `/net` (verify by filtering the output; record the command and result).
- `bash core/scripts/spike-build.sh` produces three archives without CGO errors:
  - `ios/arm64` device
  - `iossimulator/arm64`
  - `darwin/arm64`
- A minimal `core/spike/sqlite_smoke_test.go` opens an in-memory DB, creates a table, writes and reads one row, and passes with `go test -race ./...` on the host.
- Each result line is Đạt/Không đạt with the exact command, exit code and artifact path. Build-only iOS results are labelled "build verified, not device verified".
- Findings that change ADR-23/ADR-21 go to Lead as a decision request, not silently applied.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Go present | `go version` (cwd `core/`) | PASS — `go1.27.3 darwin/arm64` | working tree 2026-10-30 |
| Module init/tidy | `go mod init hiraku/core`, `go mod tidy` (cwd `core/`) | PASS | `core/go.mod`, `core/go.sum` |
| No `net` | `go list -deps ./...` filtered for `/net` | **FAIL** — exact `net` present via `modernc.org/libc → github.com/google/uuid` | `docs/reports/M0_SPIKE.md` §Spike 0 |
| Host smoke | `go test -race ./...` (cwd `core/`) | PASS — `ok hiraku/core/spike` | working tree |
| Apple slices | `bash core/scripts/spike-build.sh` | PASS (build-only) — 3 archives in `core/.spike/`, warning `loadinternal: cannot find runtime/cgo` | `docs/reports/M0_SPIKE.md` §Spike 0 |

## Coding

Not started.

## Independent review

- Reviewer / session:
- Revision:
- Verdict:
- Findings:
- Checks the reviewer actually ran:

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: required when run
- Status: not requested
- CI / integration revision:
- Gate / PO approval:
- Actions actually taken / evidence from the target system:

## Next

Starts after `m0-00-toolchain` is applied. If `modernc.org/sqlite` cannot build for ios/arm64, stop and report to Lead; do not switch to `mattn/go-sqlite3` without a new ADR.
