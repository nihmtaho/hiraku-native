# m0-06-s8-bridge — Spike S-8: XCFramework + hk_* bridge + runtime measurements

## Contract

- Status: review
- Owner: hiraku-coder
- Milestone / WP: M0 / S-8 (GATE-1 must-achieve)
- Branch / PR: none for this task; keep working on the already-merged-tree state (develop = `340c570` after PR #7); decide the branch at PR time. Do not rebase the open PR #6 branch (`chore/m0-spikes`) into this work.
- Base / head SHA: `develop` = `340c570` (PR #7 merged)
- Dependencies: `m0-05-app-skeleton` (app shell `App/Hiraku.xcodeproj` is the host); `m0-02-mattn` (driver + build script) merged via PR #6 or present in the tree
- Required reading: `docs/architecture/DECISIONS.md` ADR-21, ADR-12/ADR-32, §5 (S-8 fallback conditions); `AGENTS.md` laws G2 (only `core/ffi` imports C), G3 (no `time.Now` in domain/service, no globals), B2 (Swift only `HirakuBridge` calls `hk_*`), timing laws; `docs/product/spec.md` §3.3 S-8, NFR-002/003
- Blocking Q / gate: S-8 is a GATE-1 must-achieve. The proposed threshold "Go runtime start < 300 ms on the reference device" still needs PO confirmation; Q-11 keeps the device half unverified. This spike measures on macOS host and iOS simulator and explicitly marks the device numbers "chưa xác minh".
- Goal: prove the whole path ADR-21 requires — `core/ffi` c-archive → XCFramework → Swift `HirakuBridge` → app run — with a minimal throwaway RPC payload, and measure Go runtime startup, per-call latency and leak behaviour.
- Out of scope: real `hiraku.v1` proto contract and buf codegen (WP-01 owns it; this spike uses empty/placeholder payloads and says so), production FFI surface beyond the four ADR-21 functions, App Group (S-7), IME (S-3), layout (S-4), sync, migrations beyond the smoke table, physical iPhone/iPad runs.
- Files / modules allowed to change: `core/ffi/**`, `core/scripts/spike-build.sh` and new `core/scripts/build-xcframework.sh`, `core/spike/**` (new runtime-startup/leak test hooks only), `App/**` (linking the XCFramework and one debug screen showing the result; no feature behaviour), new Swift `Packages/HirakuBridge` (thin wrapper only), `docs/reports/M0_SPIKE.md` (new `## S-8` section), `CHANGELOG.md` `[Unreleased]`, `ROADMAP.md` §11, `ROADMAP hiraku — Kanban.html`, `.gitignore`, `.agents/tmp/**` (scratch artifacts).
- Permissions or PO decisions granted: PO confirmed the M0 app shell (2026-10-31) and defends the device threshold separately; nothing else pre-decided. The device run itself needs the PO (Verify app on a physical iPhone/iPad) — the agents cannot do it.

## Acceptance criteria

1. **Archive + framework**: `core/scripts/build-xcframework.sh` builds `core/ffi` (c-archive) per slice as `spike-build.sh` does (same CC/sysroot/min-version discipline, `set -eu`, delete-before-build), then wraps the three slices plus headers into `core/.spike/Hiraku.xcframework` with `xcodebuild -create-xcframework` and exits 0. Record the produced layout and framework sizes.
2. **ABI**: `core/ffi` exports exactly the four ADR-21 functions with the stated C signatures (`hk_open(db_path, &handle, &err)`, `hk_call(handle, method, req, &resp)`, `hk_free(bytes)`, `hk_close(handle)`), returns the ADR-21 error codes (0…5) and every exported call has `recover`. The spike payloads are empty bytes; the method namespace is a placeholder (document that `hiraku.v1` golden contract comes in WP-01). Mapping: for this spike `hk_call` accepts only `ping` and returns an empty `HKBytes`, everything else returns code 1; this is stated as throwaway, not a contract.
3. **Bridge**: a thin Swift package `Packages/HirakuBridge` declares the four functions and wraps them behind a type-safe API; it is the only Swift code allowed to touch `hk_*` (e.g. `package`-internal `import C`-style wrapper as the file layout allows). No force unwrap, no `try!`; memory `hk_free` is called right after reading the reply; the app links the framework and one debug-only screen calls it and shows the ping round-trip succeeded.
4. **Runs**: the app builds and launches on macOS and on the iOS simulator with the bridge screen showing a successful ping against the smoke DB (`:memory:` is NOT usable through a path-based `hk_open`; use a scratch DB file path under `.agents/tmp/m0-06/`). Record commands, exit codes, simulator UDID.
5. **Measurements** (macOS host + iOS simulator; device = chưa xác minh):
   - Go runtime startup: time from `hk_open` to first successful `hk_call`, median of 20 runs, and the same measurement cold (fresh process, fresh DB) → compare against the proposed 300 ms threshold, stated as a proposal only.
   - Per-call latency of `hk_call("ping")`: 1.000 calls, median/p95 (NFR p95 ≤ 100 ms).
   - Leak check: run the 1.000-call loop inside the app or a Swift test harness; assert RSS (via `mach_task_basic_info`/`footprint`) and that Go's own counters do not grow monotonically; report RSS before/after and the verdict.
6. **Loop closing**: the report ties each S-8 acceptance line to Đạt/Không đạt/chưa xác minh with the command and exit code; if a slice fails build, stop that slice and PARTIAL, no driver fallback (ADR-21).
7. **Status/docs**: CHANGELOG `[Unreleased]` entry; S-8 row `rv` in `ROADMAP.md` §11 and the Kanban raw array (same value; not `dn`).

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Framework script | `bash core/scripts/build-xcframework.sh` (cwd root) | Not run | |
| Symbols exported | `nm -gU core/.spike/*.a` shows the four `hk_` symbols | Not run | |
| Bridge builds | `xcodebuild -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS' build` | Not run | |
| Mac run + ping | launch, screenshot/log of the ping result | Not run | |
| Simulator run + ping | `xcodebuild` + `simctl` boot/install/launch + log | Not run | |
| Startup/latency/leak | the measurement commands from §5 | Not run | |
| No regression elsewhere | `go test -race -count=1 ./...` (cwd `core/`) | Not run | |
| Status agreement | `node .agents/skills/hiraku-wp-status/scripts/wp-status.mjs --check` | Not run | |

## Coding

Not started.

## Independent review

- Reviewer / session: `ses_e6f04f2a4ffeWqkzhNd1tZOE5Y`
- Revision: working tree on `origin/chore/m0-spikes` (S-8 work uncommitted; PR #6 content excluded), base `develop` = `340c570`
- Verdict: **PASS** — for the host/simulator half only; the overall S-8 stays open until the device run and the threshold confirmation (PO).
- Findings (all minor, assigned): M-1 the "startup" number as measured is `hk_open`→first `hk_call` plus SQLite open; the device-level method must be process-launch→first `hk_call` (proposal-only, already labelled); M-2 two copies of `hk.h` (ffi + package) can drift — WP-01 should generate from one source; M-3 `hksample_*` symbols are global in the archive and pulled in by `-force_load` — spike-only, must not survive into WP-01.
- Checks the reviewer actually ran: `build-xcframework.sh` 0 (24 MB, 3 slices + headers), `nm -gU` × 3 (exactly the four `hk_` symbols), `go vet ./...` 0, `go test -race -count=1 ./...` 0, `plutil -lint` pbxproj 0, `xcodebuild -list` 0, macOS app build SUCCEEDED, macOS harness run reproduced the reported JSON, grep clean, `wp-status --check` 0.
- Reviewer conclusion: ABI faithful to ADR-21, laws respected (G2/G3/B2, no `net`, no `print`/`try!`); measurement JSONs reproduced; linking deviation accepted for the spike with a clear WP-01 follow-up (slice discovery, drop `-force_load` and `hksample_*`).

## Decision

- Host/simulator half of S-8: Đạt (startup ≈1–11 ms, `hk_call` p95 ≈ 1 µs, RSS flat over 1.000 calls).
- Device half (`SC-006`, the proposed 300 ms threshold) remains "chưa xác minh" and is PO-visible only; recorded in the report, not turned into a PASS.
- The 24 MB xcframework size came from three `.a` at 7.9–8 MB each; reducing this is a WP-01/WP-38 packaging concern (strip, `-w`), not a spike goal.

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: required in working tree
- Status: not requested
- CI / integration revision:
- Gate / PO approval:
- Actions actually taken / evidence from the target system:

## Next

On PASS, S-8 remains split into a verified host/simulator half and an unverified device half (`SC-006`, threshold confirmation belongs to the PO). Then S-7 (App Group), S-3 (IME), S-4 (layout) run against this same host, and the M0 spike report closes GATE-1.
