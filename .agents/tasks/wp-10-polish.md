# wp-10-polish — XCUITest, accessibility, polish

## Contract

- Status: blocked
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-10
- Branch / PR: `feat/wp-10-polish` from `develop`
- Base / head SHA: 2df7fd5 / —
- Dependencies: WP-01…WP-09
- Required reading: TEST_PLAN.md; SC-001…SC-004, SC-007…SC-009; DESIGN a11y
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: End-to-end scenarios, a11y, crash/relaunch, performance, fixes.
- Out of scope: iPad/Mac layout; release.
- Files / modules allowed to change: App/HirakuUITests, feature packages, App/Resources
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

Every in-scope UC has a scenario; VoiceOver and Dynamic Type pass; kill mid-session recovers; 50,000-note performance meets NFR-002.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-10 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 68 | xcuitest | docs/plans/2026-11-08-m1a.md | open |
| 69 | a11y | docs/plans/2026-11-08-m1a.md | open |
| 70 | resilience | docs/plans/2026-11-08-m1a.md | open |
| 71 | perf | docs/plans/2026-11-08-m1a.md | open |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| UI tests | `xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination "platform=iOS Simulator,name=iPhone 18 Pro"` | Not run | — |
| Performance | `manual: 50,000 notes against NFR-002` | Not run | — |

## Coding

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
