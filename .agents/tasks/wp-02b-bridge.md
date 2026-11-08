# wp-02b-bridge — FFI dispatch and Swift bridge

## Contract

- Status: review
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-02b
- Branch / PR: `feat/wp-02b-bridge` from `develop` (PR pending)
- Base / head SHA: cf7f1b4 / 42ce728
- Dependencies: WP-01, WP-02a
- Required reading: ARCHITECTURE §6.4, §7; ADR-21, ADR-24; DECISIONS Q-20
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: hk_call dispatch over the real contract, error codes with sub_code, HirakuBridge actor, EventHub, fake bridge.
- Out of scope: Feature UI; FSRS logic.
- Files / modules allowed to change: core/ffi, core/service, Packages/HirakuBridge, Packages/HirakuTesting
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

Unknown method returns code 2; malformed protobuf returns code 1; panic returns code 5 with no response; bridge maps proto to models and exposes sub_code; EventHub emits ChangeSet; fake bridge compiles for controller tests.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-02b section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 48 | dispatch | docs/plans/2026-11-08-m1a.md | open |
| 49 | bridge | docs/plans/2026-11-08-m1a.md | open |
| 50 | fake | docs/plans/2026-11-08-m1a.md | open |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| FFI tests | `cd core && go test -race ./ffi/...` | Not run | — |
| Swift bridge tests | `xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination "platform=macOS"` | Not run | — |

## Coding

- `hk_call` now takes the contract `Method` enum as `uint32`; `hk.h` updated in both copies.
- `dispatch` is the only FFI logic: handle lookup, service call, panic recovery, `hiraku.v1.Error` body on failure.
- `service` adds PING and error mapping (not found, business sub-codes, storage).
- Go tests: ping, unknown method, malformed payload, invalid handle, error round-trip.
- Swift: generated protobuf (SwiftProtobuf), `HirakuBridge` actor, `EventHub`, `HirakuTesting.FakeBridge`.
- App spike views use the actor; bridge test opens a temp DB, pings, checks unknown method.
- Package links `hk_*` from the app archive via `dynamic_lookup`.

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
