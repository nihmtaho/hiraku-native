# wp-08-typing — Typing mode

## Contract

- Status: blocked
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-08
- Branch / PR: `feat/wp-08-typing` from `develop`
- Base / head SHA: 2df7fd5 / —
- Dependencies: WP-04, WP-07, S-3
- Required reading: UC-07, spec §7.2; DECISIONS Q-21; S-3 report
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: IME-safe kana field, per-character feedback, reveal answer.
- Out of scope: Handwriting; drawing.
- Files / modules allowed to change: Packages/Features/FeatureTyping, App/Hiraku/KanaInputField.swift
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

Marked text and composition do not double-insert; full-width and half-width input accepted; per-character flags match Q-21 B; wrong answer reveals the correct one.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-08 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 64 | field | docs/plans/2026-11-08-m1a.md | open |
| 65 | feedback | docs/plans/2026-11-08-m1a.md | open |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Typing tests | `xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination "platform=macOS"` | Not run | — |
| IME manual | `manual: marked text on iPhone simulator` | Not run | — |

## Coding

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
