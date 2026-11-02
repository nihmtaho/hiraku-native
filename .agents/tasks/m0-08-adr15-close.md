# m0-08-adr15-close — Close ADR-15: dn flip + M0 summary-table update

## Contract

- Status: merged
- Owner: hiraku-coder
- Milestone / WP: M0 / ADR-15 (follow-up of m0-07-adr15, PR 20 merged as `6ec5cb9`)
- Branch / PR: `docs/m0-08-adr15-close` from `develop`
- Base / head SHA: `develop` = `6ec5cb99f626ba7e6cae0b5821bc3c903e131ec2` · branch head `48717a27fec847e19c577269686b610998e0344a` (CHANGELOG PR-21 fill, pushed, Review PASS) · merged as `454d9932f8a5c10ed67e45569d2aa92d51639937`
- Dependencies: m0-07-adr15 (merged); PO merge order on PR 20 = approval of (a)(b)(c) Dat (simulator) + waived shots
- Required reading: `docs/reports/M0_SPIKE.md` §Summary table (ADR-15 row) and §GATE-1 paragraph; `ROADMAP.md` §11 (already flipped to dn in working tree — keep, do not re-run without need)
- Blocking Q / gate: none. Q-11 device waiver still holds for the remaining "chua xac minh" items.
- Goal: record ADR-15 as closed: dn status (already in working tree) + summary-table ADR-15 row updated + one CHANGELOG line, then PR and merge.
- Out of scope: any verdict change, any code, S-3/S-7, device verification.
- Files / modules allowed to change: `ROADMAP.md` + Kanban (already flipped rv→dn, keep), `docs/reports/M0_SPIKE.md` (summary table ADR-15 row + GATE-1 paragraph ADR-15 mention only), `CHANGELOG.md` (`[Unreleased]` one line under Tài liệu), `.agents/tmp/**` if needed.
- Permissions or PO decisions granted: PO ordered PR 20 merge (2026-11-01) = ADR-15 approved with simulator scope; 2 shots waived; macOS/60fps/device stay "chua xac minh".

## Acceptance criteria

1. Summary-table ADR-15 row reads Dat (simulator) with the same scope as §ADR-15: (a)(b)(c) Dat on simulator with Ember tint, 2 shots Mien (PO 2026-11-01), macOS/60fps/device "chua xac minh". No other summary row touched.
2. GATE-1 paragraph listing open evidence no longer lists ADR-15 as missing (S-3 IME, S-7, device numbers stay).
3. `wp-status --check` prints match; CHANGELOG has one new line ending `(ADR-15, PR —)` (Shipper fills the number).

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Status consistency | `node .agents/skills/hiraku-wp-status/scripts/wp-status.mjs --check` | exit 0 — "ROADMAP §11 và Kanban khớp" | `1033e2c` |
| Diff scope | `git diff --name-only 6ec5cb9..1033e2c` (and `gh pr diff 21 --name-only`) shows only ROADMAP.md, Kanban, M0_SPIKE.md, CHANGELOG.md | exit 0 — 4 docs files, no policy/checker path | `1033e2c` |
| CI bắt buộc `ci` | workflow `ci` on PR 21, run `41332040475` | success on head `1033e2c43d1c796d8c456a29d92ea82e87ddbe84` | `1033e2c` |
| CI bắt buộc `ci` (head cuối) | workflow `ci` on PR 21, run `41332337157`, `event=pull_request`, `headSha` khớp | success on head `48717a27fec847e19c577269686b610998e0344a` | `48717a2` |
| Review PASS (head cuối) | status `hiraku/review` = SUCCESS, description "Independent review PASS for 48717a2" | PASS đúng SHA `48717a27fec847e19c577269686b610998e0344a` | `48717a2` |

## Coding

Not started. (Working tree already carries the Lead-run rv→dn flip on this branch.)

## Independent review

- Reviewer / session:
- Revision:
- Verdict:
- Findings:
- Checks the reviewer actually ran:

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: ROADMAP §11 + Kanban `dn` (`--check` exit 0); CHANGELOG line under `[Unreleased]` › `### Tài liệu` ends `(ADR-15, PR 21)`
- Status: MERGED — PR 21 squash-merged into `develop`
- Merge SHA: `454d9932f8a5c10ed67e45569d2aa92d51639937` (`docs(spike): close ADR-15 with the simulator verdict (#21)`), `mergedAt` 2026-11-01T17:40:05Z
- PR: 21 https://github.com/nihmtaho/hiraku-native/pull/21 (`docs/m0-08-adr15-close` → `develop`, head `48717a27fec847e19c577269686b610998e0344a`)
- CI / integration revision: `ci` = SUCCESS on `48717a27fec847e19c577269686b610998e0344a` (workflow `ci`, run `41332337157`, `event=pull_request`)
- Gate / PO approval: PO approval already given via PR 20 merge order
- Actions actually taken / evidence from the target system:
  - Shipper 2026-11-01: verified `origin/docs/m0-08-adr15-close` = `1033e2c` (pushed, not behind `develop` = `6ec5cb9`), diff docs-only, `wp-status.mjs --check` exit 0; opened PR 21 into `develop` with `gh pr create --base develop --body-file .agents/tmp/m0-08-pr-body.md`.
  - `gh pr view 21 --json statusCheckRollup` on head `1033e2c` lists only `ci` (SUCCESS). No `hiraku/review` status exists on that SHA: `delivery.mjs review` requires an open PR, and no PR existed for this branch before PR 21.
  - Merge attempted through the only entrypoint, `node .agents/hiraku/delivery.mjs merge 21 --sha 1033e2c43d1c796d8c456a29d92ea82e87ddbe84` → `BLOCKED: Thiếu hiraku/review PASS cho 1033e2c43d1c796d8c456a29d92ea82e87ddbe84` (exit 1). Nothing was merged; `gh pr view 21` reports `state=OPEN`, `mergeStateStatus=BLOCKED`.
  - Coder 2026-11-01: filled the PR number, `CHANGELOG.md` line now ends `(ADR-15, PR 21)`, head moved `1033e2c` → `48717a2`; Reviewer re-passed `48717a2` (`hiraku/review` SUCCESS, 17:38:26Z) per `GIT_WORKFLOW` §2.
  - Shipper 2026-11-01 merge gate, all verified before merging: PR 21 `state=OPEN`, `baseRefName=develop`, `headRefOid=48717a27fec847e19c577269686b610998e0344a` = `origin/docs/m0-08-adr15-close`; `ci` SUCCESS on that exact SHA (run `41332337157`, `event=pull_request`); `hiraku/review` SUCCESS with description naming `48717a2`; `wp-status.mjs --check` exit 0 ("ROADMAP §11 và Kanban khớp"); `gh pr diff 21 --name-only` = `CHANGELOG.md`, `ROADMAP hiraku — Kanban.html`, `ROADMAP.md`, `docs/reports/M0_SPIKE.md` — no policy/checker path; `mergeStateStatus=CLEAN`.
  - Merge executed through the only entrypoint: `node .agents/hiraku/delivery.mjs merge 21 --sha 48717a27fec847e19c577269686b610998e0344a` → `auto-merge squash enabled @ 48717a2` (exit 0). `gh pr view 21` then reported `state=MERGED`, `mergeCommit.oid=454d9932f8a5c10ed67e45569d2aa92d51639937`; `origin/develop` fast-forwarded `6ec5cb9` → `454d993`.
  - Post-merge check on `origin/develop`: squash commit touches only the 4 docs files (+5/−4); `CHANGELOG.md` line 22 ends `(ADR-15, PR 21)`; `ROADMAP.md` §11 `ADR-15 | dn`; Kanban ADR-15 `dn` (1 match).
  - Branch `docs/m0-08-adr15-close` left in place: deleting it needs push rights held by Coder/operator.

## Next

None for this task. Follow-up owners: Lead reconciles `develop` against the merged task (`GIT_WORKFLOW` §2 step 6); Coder/operator may delete the merged branch.
