# m0b-01-agent-lean — Streamline agents to coordinator + senior with common skills

## Contract

- Status: applied in PR #34 (`chore/m0b-01-agent-lean`), not merged. Scope and guard/CI decisions from the PO answers below supersede PO-1…PO-4 where they conflict; ADR-31/33 amendment and GitHub ruleset update are still open.
- Owner: operator (PO side) for migration; Lead for baseline (done)
- Milestone / WP: M0b / process housekeeping (no WP; agent infrastructure, not product logic)
- Branch / PR: `chore/m0b-01-agent-lean`, PR #34 (base `develop`)
- Base / head SHA: `develop` = `db6bb6f75b5c702a440a6436544f53277b6a1565`; working tree dirty at record creation (`M .agents/tasks/m0-09-task-records.md`, `M .claude/settings.json`, `?? .serena/`)
- Dependencies: none (no WP dependency; blocked on PO decisions below, not on other WPs)
- Required reading: `docs/process/AGENT_WORKFLOW.md` (§1 shared sources incl. "skills do not grant rights, do not remake task/review/delivery into skills"; §2 roles/rights; §4 merge/release, ADR-33); `docs/process/GIT_WORKFLOW.md` (§1 branches, §3 pre-merge incl. policy-toucher rule); `docs/architecture/DECISIONS.md` (ADR-31, ADR-33, Q-29 partially open); `.agents/hiraku/roles/*.md`, `.agents/hiraku/guard.mjs`, `.agents/hiraku/sync.mjs`, `.agents/hiraku/models.json`; existing skills `hiraku-task`, `hiraku-wp-status` as reuse reference
- Blocking Q / gate:
  1. PO-1: Policy implementation path — roles/guard/generator/`AGENTS.md`/agent configs are protected paths (`guard.mjs` protectedPath, AGENT_WORKFLOW §4). Normal Coder→Reviewer→Shipper delivery cannot land them (`delivery.mjs` refuses; operator merges). Confirm: operator applies the migration directly (possibly assisted by read-only agent research), vs PO grants a one-off exception.
  2. PO-2: Merge rights — plan gives `hiraku-coordinator` review + merge via delivery checker and drops `hiraku-shipper`. Current rule: no self-merge role; Shipper enables merge, tag/publish closed (ADR-33). Confirm: keep Shipper + `delivery.mjs` (coordinator requests, shipper executes) vs grant coordinator merge.
  3. PO-3: Parallelism — plan allows multiple concurrent senior sessions; ROADMAP §1 + Q-29 say one sequential AI coding. Confirm: keep sequential vs allow parallel seniors on isolated worktrees.
  4. PO-4: Scope first step — full migration at once vs read-only baseline first (worktree check, context measurement, duplication inventory, no policy edits).
- Goal: reduce to two agent roles (`hiraku-coordinator`, `hiraku-senior`), move repeated workflows into short reusable common skills (`hiraku-task`, `hiraku-coding`, `hiraku-review`, `hiraku-create-pr`, `hiraku-ship`), shrink always-on context (invariants/rights/skill routing only), keep independent review bound to head SHA and all existing merge gates. Plan text supplied by user (VN + JP, 2026-11-02); it is a proposal, not a decided outcome.
- Out of scope: product logic (Go/Swift/proto), tag/release, Apple Developer account, CI job changes, changing review/CI/gate strictness to make checks pass, one-off docs work that should stay as docs (not skills).
- Files / modules allowed to change (once PO-1 decided; operator-applied if policy): `.agents/hiraku/roles/`, `.agents/hiraku/sync.mjs`, `.agents/hiraku/guard.mjs`, `.agents/hiraku/models.json`, `.agents/hiraku/tests/`, `.agents/skills/hiraku-*/SKILL.md` (new common skills), generated adapter configs (`.opencode/`, `.pi/`, `.commandcode/`, `.claude/` via generator only, never hand-edited), `AGENTS.md` (always-on trimming only), `docs/process/AGENT_WORKFLOW.md`, `docs/process/GIT_WORKFLOW.md` if workflow changes, `docs/architecture/DECISIONS.md` only via PO decision, `CHANGELOG.md` `[Unreleased]`, `ROADMAP.md` §11 + Kanban if a WP is attached (none currently).
- Permissions or PO decisions granted (PO, 2026-11-02, via task questions): (1) operator applies all policy edits directly (agent does read-only research only); (2) keep `hiraku-shipper` + `delivery.mjs` merge gate, coordinator does NOT merge — ADR-31/ADR-33 unchanged; (3) stay sequential, one senior session at a time on isolated worktrees (Q-29 unchanged); (4) baseline-first: read-only measurement before any migration; (5) PO, later: agents review bound to the exact head SHA and merge PRs into `develop` through `delivery.mjs` once `hiraku/review` and `ci` pass on that SHA; agents do NOT tag or release unless PO explicitly asks in that session (ADR-33 tag/publish stays closed by default). (6) PO, supersedes PO-2 for the 2-role target: flow is coordinator assigns task → senior implements, self-reviews, creates PR, reports result → coordinator reviews PR quality via independent session and either sends findings back to senior or merges through `delivery.mjs`. So the coordinator is the merge caller; `hiraku-shipper` is dropped in the target. Skill-only roles: `hiraku-coordinator` and `hiraku-senior` only invoke skills (`hiraku-task`, `hiraku-coding`, `hiraku-review`, `hiraku-create-pr`, `hiraku-ship`). Limits that stay: senior self-review is not the independent PASS; the `hiraku/review` verdict comes from the coordinator session that did not write the code; policy/checker PRs remain operator-merged; tag/release closed. Operator must apply the guard change (coordinator allowed `delivery.mjs merge`) and the matching AGENT_WORKFLOW §2/§4 update.
(7) PO, 2026-11-03, confirmed: (a) coordinator may both review and merge (accepts that review and merge are not split across people); (b) senior may run `git push --force-with-lease` on its own task branch only, after rebase; never on `develop`/`main`, never bare `--force`; (c) CI must handle pending state (wait/re-check, no merge on pending, report fail back to senior). Items (a)–(c) need operator changes in `guard.mjs`, `delivery.mjs`/`ci.yml` and AGENT_WORKFLOW §2/§4 and ADR-31/33 wording; Lead does not apply them.

## Acceptance criteria

1. Exactly two functional agent roles; old `coder`/`reviewer`/`shipper` (+ helper `explore`/`general`/`plan` as standalone delegates) no longer discoverable by any of the four adapters (OpenCode, Pi, Command Code, Claude Code) after `sync.mjs`.
2. Senior session can carry a task from survey to pushed branch + created/updated PR without coordinator editing source; coordinator never edits source and senior never self-approves or merges (negative checks demonstrable in tests or adapter permission dumps).
3. Every new/changed skill has a `description` that triggers auto-invocation, minimal inputs, steps, key error/edge branches, outputs and done-conditions; workflow part contains no hiraku-specific paths/branches/commands (binding separated).
4. Review verdicts stay bound to exact head SHA: any new commit/rebase invalidates a prior PASS (re-review required); required CI, review threads and PO gates unchanged; PRs touching policy/checker still go to the operator.
5. `node .agents/hiraku/sync.mjs` and `node --test .agents/hiraku/tests/*.test.mjs` pass; adapter-specific checks per each tool README pass or are reported as not runnable with reason; context measured before/after on the same journey (tokens, not lines).
6. `CHANGELOG.md` `[Unreleased]` entry plus `ROADMAP.md` §11/Kanban consistency per `hiraku-wp-status --check` (or documented `chore` reason in PR if no WP attached).

## Checks

| Criterion | Command / manual check | Result / exit code | Revision / artifact |
|---|---|---|---|
| Sync + unit | `node .agents/hiraku/sync.mjs && node --test .agents/hiraku/tests/*.test.mjs` | Not run | |
| Status consistency | `node .agents/skills/hiraku-wp-status/scripts/wp-status.mjs --check` | Not run | |
| Negative perms | senior-attempts-review/merge denied; coordinator-attempts-source-edit denied (adapter test or guard test) | Not run | |
| Discovery | role/agent listing on OpenCode, Pi, Command Code, Claude Code shows only 2 roles | Not run | |
| Context delta | before/after token measurement on same journey | Not run | |

## Coding

Baseline (read-only, Lead, 2026-11-02, base `db6bb6f` on `develop`, single worktree, no other worktrees):

- Worktree: clean single checkout on `develop`; dirty: `M .agents/tasks/m0-09-task-records.md`, `M .claude/settings.json`, untracked `?? .serena/` + this new record. No task branches open.
- Always-on context floor: `AGENTS.md` (6.4 KB) + `AGENT_WORKFLOW.md` (12.7 KB) + `GIT_WORKFLOW.md` (7.8 KB) + 7 role prompts (14.8 KB total) ≈ 41.7 KB before any skill loads.
- Skills total ≈ 81.4 KB across 18 `SKILL.md`; only `description` frontmatter loads until invoked. Notable overlap candidates: `delivery.mjs`/verdict flow duplicated in `reviewer.md` + `shipper.md` + `AGENT_WORKFLOW.md` §4; head-SHA binding stated in 4+ places; 7 git skills (`git-branch/commit/pr/rebase/release/hooks/usage`, ≈ 13 KB) overlap `GIT_WORKFLOW.md`; `AGENTS.md` command table partially duplicates skill contents.
- Consequence for migration: 2-role target keeps `reviewer`/`shipper` duties (independent review + delivery gate stay — PO decision 2) so the roles are renamed/reassigned, not deleted; `explore`/`general`/`plan` helpers fold into senior self-work per existing cost rule; new `hiraku-coding`/`hiraku-review`/`hiraku-create-pr`/`hiraku-ship` skills must NOT restate policy (rights stay in `AGENT_WORKFLOW.md` + `guard.mjs`) and must NOT turn task/review/delivery into skill-granted rights (AGENT_WORKFLOW §1).

No source, policy, or config files touched by agent in this step.

## Independent review

- Reviewer / session:
- Revision:
- Verdict:
- Findings:
- Checks the reviewer actually ran:

## Delivery

- CHANGELOG entry and ROADMAP/Kanban status updated in the PR: no (blocked, no PR)
- Status: blocked
- CI / integration revision:
- Gate / PO approval:
- Actions actually taken / evidence from the target system:

## Next

PO decisions PO-1…PO-4 recorded 2026-11-02; baseline done. Next action: migration is in PR #34; operator decides ruleset `hiraku/review`, ADR-31/33 amendment and merge of policy PRs (roles, `sync.mjs`, `guard.mjs`, `models.json`, adapter regen, new `hiraku-*` skills, `AGENTS.md` trim, workflow docs, tests, CHANGELOG `[Unreleased]`), honoring: no self-merge role, review bound to head SHA, policy PRs operator-merged, sequential seniors, tag/release still closed. No Coder/Reviewer/Shipper subagents to dispatch for this task — agent delivery path is closed by design here. Any change of revision invalidates earlier review and approval; re-read this record on resume.

(8) PO, 2026-11-03 (confirmed in session): removal of `.agents/hiraku/delivery.mjs` and the tool-level guard (`guard.mjs` and per-tool hooks/plugins/extensions) is confirmed. Merge and verdict are by convention; no automated gate.
