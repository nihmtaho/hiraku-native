# wp-04-kana — Kana normalization and matching

## Contract

- Status: merged
- Owner: coordinator / senior (Q-29)
- Milestone / WP: M1a / WP-04
- Branch / PR: `feat/wp-04-kana` / PR 84 (merged `31ca018`)
- Base / head SHA: 4b97db3 / bd61401 (merge `31ca018`)
- Dependencies: WP-01
- Required reading: DECISIONS Q-21; spec §7.2
- Blocking Q / gate: GATE-1 decisions closed 2026-11-08; waiver for device debt (S-1 iOS/60 fps, S-3 real IME); S-7 verified by slice #43
- Goal: Roma-ji to kana, Q-21 option B normalization, per-character match with golden table.
- Out of scope: Typing UI.
- Files / modules allowed to change: core/domain/kana, core/testdata/kana_golden.json
- Permissions or PO decisions granted: Q-19, Q-20, Q-21 B, Q-22, Q-24, Q-27, Q-28; ADR-20/21/24/26/32 confirmed (PO 2026-11-08)

## Acceptance criteria

Dakuten and っ are strict; ー and long vowels tolerated; repeated-character folding applies; per-character match returns one flag per answer character; golden table passes.

## Execution plan

- Plan: `docs/plans/2026-11-08-m1a.md` (wp-04 section)
- When working, mention both this record and the plan path; on resume, read both.

## GitHub issues

| # | Slice | Plan anchor | Status |
|---|---|---|---|
| 54 | normalize | docs/plans/2026-11-08-m1a.md | closed |
| 55 | match | docs/plans/2026-11-08-m1a.md | closed |

Record is authority for the contract; plan is authority for progress; issues track slice status.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Kana golden tests | `cd core && go test ./domain/kana/...` | exit 0 | `core/domain/kana`, `core/testdata/kana_golden.json` |
| Core vet and race tests | `cd core && go vet ./... && go test -race ./...` | exit 0 | all packages |
| Go boundary law | `./core/scripts/check-core.sh` | exit 0 | — |
| Swift import law | `./Scripts/check-imports.sh` | exit 0 | — |
| Status consistency | `node .agents/scripts/wp-status.mjs --check` | exit 0 | ROADMAP §11 and Kanban agree |

## Coding

- Branch `feat/wp-04-kana` from `develop` at `4b97db3`.
- Added `core/domain/kana/{kana.go,kana_test.go}` and `core/testdata/kana_golden.json`.
- `Normalize` maps romaji to kana, folds katakana to hiragana, drops ー, tolerates long vowels and repeated characters; dakuten, っ and small kana stay strict (Q-21 B).
- `Match` returns one flag per answer character; characters dropped by normalization stay true.
- Plan `docs/plans/2026-11-08-m1a.md` §WP-04: all four steps checked.

## Independent review

- Round 1 on `bbec0b2`: FAIL — `Match` used an in-order pointer, so every character after a middle mismatch was reported wrong; missing middle-mismatch test. Fixed by comparing positionally and adding `TestMatchKeepsLaterCharactersAfterAMismatch`.
- Round 2 on `bd61401`: PASS. Carry-forward: `kana.Match` takes kana answers only, so WP-08 must not request per-character flags for a `text` answer field (recorded in `wp-08-typing.md`).

## Delivery

- `gh pr merge 84 --squash --match-head-commit bd61401` gave merge `31ca018`; CI `ci` and `swift` passed on `bd61401`; slices #54 and #55 were closed by hand after the merge because the base `develop` is not the default branch `main`.

## Next

None; closed. Slice issues #54 and #55 are closed.
