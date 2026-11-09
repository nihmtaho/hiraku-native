# m1-debt-02 — EventHub publish and remaining test strength

## Contract

- Status: review
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-03 follow-up
- Branch / PR: `fix/m1-debt-2` from `develop`
- Base / head SHA: 69441a6 / c1e4666 (checks at c1e4666)
- Dependencies: m1-debt-01
- Required reading: ADR-24, ADR-26
- Blocking Q / gate: none
- Goal: publish ChangeSet from Grade responses through EventHub and close the last test-strength gaps.
- Out of scope: UI consumers of the stream (WP-07).
- Files / modules allowed to change: core/service, core/store, Packages/HirakuBridge, App/HirakuTests, .agents/tasks
- Permissions or PO decisions granted: none needed

## Acceptance criteria

- A successful Grade response with changes is sent to `EventHub`; Ping responses are not.
- Review log test covers a second grade with non-zero steps and a non-null last review.
- Due queue scope has its own test for deck and folder.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (WP-03)

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| — | follow-up | docs/plans/2026-11-08-m1a.md | n/a |

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| All core | `cd core && go vet ./... && go test -race ./...` | 0 | 51aafac |
| Contract | `buf lint && buf breaking --against '.git#branch=develop'` | 0 | 51aafac |
| Xcode tests | `xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS'` | 0, 4 tests | 51aafac |

## Coding

- `HirakuBridge.changeSet(method:response:)` decodes Grade responses; `call` publishes to EventHub.
- Tests: second-grade snapshot, DueCards scope, ChangeSet publish.

## Independent review

## Delivery

## Next

After this merge the recorded M1a debt list is empty.
