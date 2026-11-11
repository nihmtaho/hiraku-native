# Adopt Flowkit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (carried over in this session). Steps use checkbox (`- [ ]`) syntax.

**Goal:** Make the already-evaluated Flowkit the live skill set of this repo: 20 skills installed in `.agents/skills/`, the 10 `hiraku-*` skill dirs removed, project scripts moved out of skills, `PROJECT.md` at root, and all policy docs pointing at the new names.

**Architecture:** Copy-in adoption (not move): `.tmp/flowkit/` stays the distributable kit; `.agents/skills/` gets an installed copy. Project-specific scripts move to `.agents/scripts/`. No skill body changes — the installed files must be byte-identical to the evaluated kit.

**Tech Stack:** Git, Markdown, Node 24 (repo skill tests + status script), GitHub Actions config.

**Spec:** `docs/plans/2026-11-11-adopt-flowkit-design.md`

## Global Constraints

- Installed skill files must equal `.tmp/flowkit/skills/<name>/SKILL.md` and `evals/evals.json` (no edits during install).
- Delete only the 10 mapped `hiraku-*` dirs: `hiraku-coordinator`, `hiraku-task`, `hiraku-coding`, `hiraku-create-pr`, `hiraku-review`, `hiraku-ship`, `hiraku-wp-status`, `hiraku-contract`, `hiraku-feature`, `hiraku-spike-report`. Never touch other skills.
- Scripts: `wp-status.mjs` and `task-context.mjs` live at `.agents/scripts/`; every caller uses the new path.
- Historical files stay unchanged: `docs/plans/` older files, `.agents/tasks/`, `docs/archive/`, old CHANGELOG entries, old ADR text (new amendment appended only).
- Name mapping used everywhere: coordinator→`flow-coordinator`, task→`flow-task`, coding→`flow-implement`, create-pr→`flow-pr`, review→`flow-review`, ship→`flow-ship`, wp-status→`flow-status`, contract→`flow-interface`, feature→`flow-feature`, spike-report→`flow-spike`.
- Commit messages: English Conventional Commit, no AI co-author/trailer.
- PR touches policy/checker → PR body must carry the operator-review warning.

## Review Focus

1. **Lost script callers** — grep every use of the old `hiraku-*/scripts/*.mjs` path (tests, CI, docs, PROJECT.md) after the move; any stale path breaks CI silently.
2. **Silent skill deletion damage** — the spike report template and skill evals must survive the `hiraku-*` deletion (`flow-spike/references/`, per-skill `evals/`).
3. **Doc name drift** — a policy doc still naming a deleted skill makes the workflow un-followable; the final grep is the check.
4. **Installed ≠ evaluated** — `diff -r` between kit skills and installed skills must be empty (excluding the references copy).

---

### Task 1: Move project scripts out of skills; fix callers

**Files:**
- Move: `.agents/skills/hiraku-wp-status/scripts/wp-status.mjs` → `.agents/scripts/wp-status.mjs`
- Move: `.agents/skills/hiraku-task/scripts/task-context.mjs` → `.agents/scripts/task-context.mjs`
- Modify: `.agents/hiraku/tests/skills.test.mjs` (imports)
- Modify: `.github/workflows/ci.yml` (status-check command path)

- [ ] **Step 1:** `git mv` both scripts to `.agents/scripts/`.
- [ ] **Step 2:** Update the two imports in `.agents/hiraku/tests/skills.test.mjs` to `../../scripts/wp-status.mjs` and `../../scripts/task-context.mjs` (relative to `.agents/hiraku/tests/`).
- [ ] **Step 3:** Update the CI step command to `node .agents/scripts/wp-status.mjs --check`.
- [ ] **Step 4:** Verify: `node --test .agents/hiraku/tests/*.test.mjs` → all pass; `node .agents/scripts/wp-status.mjs --check` → `ROADMAP §11 và Kanban khớp.`
- [ ] **Step 5:** Commit `refactor: move project scripts out of skills`.

### Task 2: Install Flowkit skills; remove hiraku-* skills

**Files:**
- Create: `.agents/skills/<20 kit skills>/` (copy of `.tmp/flowkit/skills/<name>/`)
- Create: `.agents/skills/flow-spike/references/report-template.md` (from `.agents/skills/hiraku-spike-report/references/`)
- Create: `.agents/skills/LICENSE.pm-skills` (from `.tmp/flowkit/LICENSE.pm-skills`)
- Delete: the 10 mapped `hiraku-*` dirs

- [ ] **Step 1:** Copy the 20 skill dirs (`cp -R .tmp/flowkit/skills/<name> .agents/skills/`), preserving `SKILL.md` + `evals/`.
- [ ] **Step 2:** Move `report-template.md` into `.agents/skills/flow-spike/references/`; copy the PM license.
- [ ] **Step 3:** `git rm -r` the 10 mapped `hiraku-*` dirs.
- [ ] **Step 4:** Verify: `diff -r .tmp/flowkit/skills .agents/skills` shows only expected extras (git/domain skills, `flow-spike/references`, `LICENSE.pm-skills`) and no content diff for the 20; `ls .agents/skills | grep '^hiraku-'` → empty; `node .tmp/flowkit/scripts/check-kit.mjs` → OK.
- [ ] **Step 5:** Commit `feat: install flowkit skills and remove hiraku-prefixed skills`.

### Task 3: PROJECT.md at repo root

**Files:**
- Create: `PROJECT.md` (from `.tmp/flowkit/profiles/hiraku-native.md`, adjusted)

- [ ] **Step 1:** Copy the profile; update script paths to `.agents/scripts/task-context.mjs` and `.agents/scripts/wp-status.mjs`; point the example to `.tmp/flowkit/PROJECT.md.example`.
- [ ] **Step 2:** Verify: `grep -c 'task-context.mjs\|wp-status.mjs' PROJECT.md` ≥ 2 and no `.agents/skills/hiraku-` path remains in it.
- [ ] **Step 3:** Commit `docs: add project profile for flowkit skills`.

### Task 4: Update AGENTS.md

**Files:**
- Modify: `AGENTS.md` (skill names, `PROJECT.md`, root file list, kit pointer)

- [ ] **Step 1:** Replace the skill list and workflow mentions with the `flow-*` names; add `PROJECT.md` to the root files line; add one line that the distributable kit lives at `.tmp/flowkit/` and skills read `PROJECT.md`.
- [ ] **Step 2:** Keep every hard rule (contract, Go/Swift boundaries, profiles, field roles, ADR constraints) unchanged.
- [ ] **Step 3:** Verify: `grep -c 'flow-' AGENTS.md` ≥ 8; `grep -n 'hiraku-' AGENTS.md` → only historical/archive mentions if any (target: none).
- [ ] **Step 4:** Commit `docs: point agents harness at flowkit skills`.

### Task 5: Update policy docs, ADR amendment, CHANGELOG

**Files:**
- Modify: `docs/process/AGENT_WORKFLOW.md`, `docs/process/GIT_WORKFLOW.md`, `docs/process/RELEASE.md`, `.claude/README.md`
- Modify: `ROADMAP.md` only if it names a skill
- Modify: `docs/architecture/DECISIONS.md` (append one amendment bullet under ADR-31)
- Modify: `CHANGELOG.md` (`[Unreleased]` → Tài liệu)

- [ ] **Step 1:** Rename every `hiraku-<skill>` reference using the mapping; update script paths to `.agents/scripts/`.
- [ ] **Step 2:** Append the ADR-31 amendment bullet: adopting Flowkit, old skill names replaced 1:1, scripts moved to `.agents/scripts/`, evaluation evidence in `.tmp/flowkit/evals/REPORT.md`.
- [ ] **Step 3:** Add one CHANGELOG line under `Tài liệu` ending `(PR 83)`.
- [ ] **Step 4:** Verify: `grep -rn 'hiraku-\\(coordinator\\|task\\|coding\\|create-pr\\|review\\|ship\\|wp-status\\|contract\\|feature\\|spike-report\\)' AGENTS.md docs/process .claude ROADMAP.md .github/workflows .agents/hiraku/tests` → no hits.
- [ ] **Step 5:** Commit `docs: rename flowkit skills across process docs`.

### Task 6: Final verification, PR update, push

- [ ] **Step 1:** Run: `node --test .agents/hiraku/tests/*.test.mjs`; `node .agents/scripts/wp-status.mjs --check`; `node .tmp/flowkit/scripts/check-kit.mjs`.
- [ ] **Step 2:** `diff -r` check between kit skills and installed skills (20 dirs), plus `git status` clean.
- [ ] **Step 3:** Update PR #83 title/body: adoption scope, new skill list, checks table with these three commands + revisions, operator-review warning for policy files.
- [ ] **Step 4:** Push and confirm `gh pr view 83` head SHA.
- [ ] **Step 5:** Commit nothing if PR body only; report.

## Self-review notes

- Coverage: design §Thay đổi 1→Task 1; 2→Task 2; 3→Task 3; 4→Task 4; 5→Tasks 4–5; 6→Task 5; acceptance 1–6→Tasks 2, 3, 5, 6.
- Consistency: name mapping used identically in Tasks 4–5; script path `.agents/scripts/` used in Tasks 1–5.
- Deferred per design: no ROADMAP §11/Kanban row (no WP), kit not deleted, skill bodies not edited.
