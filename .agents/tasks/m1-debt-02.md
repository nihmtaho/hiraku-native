# m1-debt-02 — EventHub publish and remaining test strength

## Contract

- Status: merged
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-03 follow-up
- Branch / PR: `fix/m1-debt-2` / PR 81
- Base / head SHA: 69441a6 / b00bfbf (checks at c1e4666, merge 47c17a7)
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
| All core | `cd core && go vet ./... && go test -race ./...` | 0 | c1e4666 |
| Contract | `buf lint && buf breaking --against '.git#branch=develop'` | 0 | c1e4666 |
| Xcode tests | `xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS'` | 0, 5 tests | c1e4666 |

## Coding

- `HirakuBridge.changeSet(method:response:)` decodes Grade responses; `call` publishes to EventHub.
- Tests: second-grade snapshot, DueCards scope, ChangeSet publish.

## Independent review

- Reviewer / session: independent subagent
- Revision: b00bfbf
- Verdict: PASS @ b00bfbf
- Findings: folder-scope test, publish-through-call test, empty ChangeSet guard, CHANGELOG suffix, record head (all fixed)
- Checks the reviewer actually ran: go vet, go test -race, buf lint/breaking, check scripts, xcodebuild test (5 tests)

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: yes
- Status: merged
- CI / integration revision: PR 81, merge 47c17a7, ci + swift green
- Gate / PO approval: ADR-24, ADR-26
- Actions actually taken / evidence from the target system: GitHub PR 81 merged to develop

## Next

Recorded M1a debt list is empty. Next: WP-04.
