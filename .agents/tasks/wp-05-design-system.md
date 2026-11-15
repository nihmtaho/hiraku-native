# wp-05-design-system — DesignSystem tokens and components

## Contract

- Status: coding
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-05
- Branch / PR: `feat/wp-05-design-system` from `develop`
- Base / head SHA: 3a749ca / —
- Dependencies: Q-5, Q-D2
- Required reading: docs/product/DESIGN.md; ADR-15; DECISIONS Q-5, Q-D2
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: HK tokens, components, Noto Sans JP, Ember AccentColor and glass chrome rules.
- Out of scope: Feature screens.
- Files / modules allowed to change: Packages/DesignSystem, Scripts/check-imports.sh (package allowlist), .github/workflows/ci.yml (build and test the package), docs/product/DESIGN.md (implementation notes), CHANGELOG.md, ROADMAP.md, Kanban, `docs/plans/2026-11-08-m1a.md`
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

Every DESIGN token exists with the documented value; state-learning-ink is #A67C00; bundled font resolves; components pass snapshot-free Swift tests on macOS simulator.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-05 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 56 | tokens | docs/plans/2026-11-08-m1a.md | open |
| 57 | components | docs/plans/2026-11-08-m1a.md | open |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| DesignSystem tests | `swift test --package-path Packages/DesignSystem` | exit 0, 10 tests | `Packages/DesignSystem` |
| App tests | `xcodebuild test -project App/Hiraku.xcodeproj -scheme Hiraku -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO` | exit 0, TEST SUCCEEDED | `App` |
| Swift import law | `./Scripts/check-imports.sh` | exit 0 | DesignSystem allowlist added |
| Go boundary law | `./core/scripts/check-core.sh` | exit 0 | — |

## Coding

- Branch `feat/wp-05-design-system` from `develop` at `3a749ca`.
- `Tokens.swift`: `HKColor` (18 tokens from DESIGN §Colors, hex in `HKHex`), `HKFont` (10 typography styles with platform size and tracking), `HKSpacing`, `HKRadius`, `HKBorder`, `HKHitTarget`, bundled Noto Sans JP registration.
- `Components.swift`: `HKButton` (primary/secondary/dark, pressed, hover, disabled), `HKCard`, `HKField` with inline ink error row.
- `Icons.swift`: `AppIcon` mapping every DESIGN §Iconography symbol.
- Tests: token values, contrast ratios from the DESIGN table, typography per platform column, font resolve, icon mapping, component construction.
- DESIGN §Triển khai updated where the plan and the spike already differ from the old text: colours are code tokens, the font registers at runtime, snapshots stay debt.
- CI now builds and tests the package; `check-imports.sh` gained the DesignSystem allowlist.

## Independent review

## Delivery

## Next

Read the plan section and the open issues above.
