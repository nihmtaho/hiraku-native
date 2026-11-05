# m0-09-task-records — Commit the m0-07/m0-08 task records

## Contract

- Status: superseded 2026-11-04 — record m0-09 is merged; status updates are plainly done via ROADMAP §11 and the PR flow since ADR-31's replacement.
- Owner: hiraku-coder
- Milestone / WP: M0 / housekeeping (follows m0-07-adr15 PR 20 and m0-08-adr15-close PR 21, both merged)
- Branch / PR: `docs/m0-09-task-records` from `develop`; PR #22 https://github.com/nihmtaho/hiraku-native/pull/22
- Base / head SHA: `develop` = `454d9932f8a5c10ed67e45569d2aa92d51639937`
- Dependencies: none
- Required reading: `.agents/tasks/m0-07-adr15.md`, `.agents/tasks/m0-08-adr15-close.md` (content frozen — commit as-is, do not edit)
- Blocking Q / gate: none
- Goal: commit the two untracked task records so they join the tracked set like m0-00…m0-06.
- Out of scope: editing the records, touching source/docs, `.serena/` (leave untracked).
- Files / modules allowed to change: `.agents/tasks/m0-07-adr15.md`, `.agents/tasks/m0-08-adr15-close.md`, `.agents/tasks/m0-09-task-records.md` (add only, records frozen — commit as-is, do not edit content). CHANGELOG: none (pure `chore`, housekeeping of agent records — state the reason in the PR).
- Permissions or PO decisions granted: PO ordered "commit tài liệu lên trước" (2026-11-01).

## Acceptance criteria

1. `git status` shows all three record files tracked; `git diff --cached --stat` lists exactly those three files.
2. No other file added, modified, or deleted; `.serena/` stays untracked.

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Scope | `git status --short` + `git diff --cached --stat` | Not run | |
| Consistency | `node .agents/skills/hiraku-wp-status/scripts/wp-status.mjs --check` | Not run | |

## Coding

Not started.

## Independent review

- Reviewer / session:
- Revision:
- Verdict:
- Findings:
- Checks the reviewer actually ran:

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: n/a (`chore` housekeeping, reason in PR)
- Status: merged as `db6bb6f` (PR 22, squash, 2026-11-02). Operator published `hiraku/review` PASS on `60d8218` and ran `delivery.mjs merge`; Shipper verified CI SUCCESS on the exact head (run 41385144798) + --check exit 0 before merging.
- CI / integration revision: `ci` SUCCESS @ `60d8218d771fc916614703d36192f8f70ce26fb8` (run 41385144798, 2026-11-02T03:51:37Z)
- Gate / PO approval: PO ordered the commit (2026-11-01); independent review PASS on `60d8218`; operator published the review status
- Actions actually taken / evidence from the target system: PR #22 merged into `develop` as `db6bb6f`; the three records are now tracked on develop; Lead reconciled (`--check` match).

## Next

Done 2026-11-02: merged (`db6bb6f`). No further action; branch cleanup (delete merged task branches) needs Coder/operator push rights.
