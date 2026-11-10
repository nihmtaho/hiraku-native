# Flowkit Evals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (carried over from the kit build in this session) or `executing-plans`. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Add repo-convention evals (`<skill>/evals/evals.json`) for 12 kit-authored skills and 8 PM smoke evals, run all of them read-only in this session, and report per-assertion verdicts.

**Architecture:** Pure content + one controlled run. Eval files live beside each skill; assertions are natural-language checks (repo schema). Grading is done by fresh read-only subagents, one per kit skill and one per two PM skills; controller aggregates. Real failures get fixed in `SKILL.md` and re-run.

**Tech Stack:** JSON, Markdown, Node 24 (checker + JSON validation), git.

**Spec:** `docs/plans/2026-11-10-flowkit-evals-design.md`

## Global Constraints

- Eval path: `.tmp/flowkit/skills/<name>/evals/evals.json`. Schema exactly:
  `{ "skill_name": "<name>", "evals": [ { "id": 1, "prompt": "...", "expected_output": "...", "files": [], "assertions": ["..."] } ] }`
- Eval prompts and assertions in English; 2–3 evals for the 12 kit skills; exactly 1 for PM (`write-spec`, `roadmap-update`, `sprint-planning`, `stakeholder-update`, `synthesize-research`, `competitive-brief`, `metrics-review`, `product-brainstorming`).
- Forbidden tokens apply to every file under `skills/**`, evals included: case-insensitive `hiraku`; case-sensitive `ROADMAP`, `DECISIONS`, `WP-`, `$ARGUMENTS`, `CONNECTORS.md`, `task-context`, `wp-status`. Use a neutral fixture project instead.
- Neutral fixture (state it in each prompt so no files are needed): a repo whose `PROJECT.md` names a status board file, base branch `develop`, check commands, docs map, architecture rules; the agent works read-only.
- Gate after every authoring task: `node .tmp/flowkit/scripts/check-kit.mjs` → `flowkit check: OK`, exit 0, plus all `evals.json` parse as JSON.
- Commits: English Conventional Commit, no AI co-author/trailer; do not modify `.agents/skills/`, `PROJECT.md.example`, `profiles/`, `scripts/check-kit.mjs`, or the 12 `SKILL.md` files in authoring tasks.
- Run tasks are controller-driven (subagents, read-only): no repo writes during grading.

## Review Focus

1. **An eval whose assertion is unfalsifiable** ("be helpful", "follow the process") — every assertion must be checkable from a skill-following answer. Task 1–4 reviews check this.
2. **Prompt/assertion drift from the skill** — a prompt that the skill does not actually cover (e.g. asks about release, which `flow-ship` excludes) would produce false FAILs. Reviewers cross-read the corresponding `SKILL.md`.
3. **Neutrality leak** — hiraku tokens or hiraku-shaped fixture facts slipping into prompts; the gate catches exact tokens only, so reviewers read for "project-specific" facts.
4. **Smoke-only PM evals drifting into deep tests** — one prompt each, 2–3 assertions, focused on the adaptation risks (connector line, command block removal, frontmatter).

---

### Task 1: Adapt 5 eval files from hiraku

**Files:**
- Create: `.tmp/flowkit/skills/flow-task/evals/evals.json`
- Create: `.tmp/flowkit/skills/flow-status/evals/evals.json`
- Create: `.tmp/flowkit/skills/flow-interface/evals/evals.json`
- Create: `.tmp/flowkit/skills/flow-feature/evals/evals.json`
- Create: `.tmp/flowkit/skills/flow-spike/evals/evals.json`

**Source (read-only):** `.agents/skills/hiraku-{task,wp-status,contract,feature,spike-report}/evals/evals.json` — same mapping order.

**Interfaces:** Produces the adapted eval pairs; Tasks 5–6 run and grade them.

- [ ] **Step 1:** Read the 5 source `evals.json` files and the 5 target `SKILL.md` files.
- [ ] **Step 2:** Write each target file: keep the scenario shape and assertion intent, translate to English, replace hiraku-specific facts (WP/Q ids, ROADMAP, `wp-status.mjs`, task files) with neutral-fixture facts (a `PROJECT.md`, a status board, a context command, an interface layer). Keep 2 evals per skill unless the source has 1.
- [ ] **Step 3:** Verify: `node -e "for (const f of process.argv.slice(1)) JSON.parse(require('fs').readFileSync(f,'utf8'))" .tmp/flowkit/skills/flow-{task,status,interface,feature,spike}/evals/evals.json` → no output, exit 0; `node .tmp/flowkit/scripts/check-kit.mjs` → OK.
- [ ] **Step 4:** Commit `feat: add flowkit evals for ported skills`.

### Task 2: New evals — coordinator, implement, pr, ship, review

**Files:**
- Create: `.tmp/flowkit/skills/flow-coordinator/evals/evals.json`
- Create: `.tmp/flowkit/skills/flow-implement/evals/evals.json`
- Create: `.tmp/flowkit/skills/flow-pr/evals/evals.json`
- Create: `.tmp/flowkit/skills/flow-ship/evals/evals.json`
- Create: `.tmp/flowkit/skills/flow-review/evals/evals.json`

**Interfaces:** same schema; Task 5 runs them.

- [ ] **Step 1:** Write `flow-coordinator` (2 evals): (a) task blocked by an open decision — block and ask, do not start; (b) a recorded PASS for revision A but head is now B — the old PASS is void, re-review B before shipping.
- [ ] **Step 2:** Write `flow-implement` (2): (a) a request that drifts beyond task scope — refuse the extra, keep the smallest change; (b) `PROJECT.md` missing — stop and ask to create it from the kit's `PROJECT.md.example`.
- [ ] **Step 3:** Write `flow-pr` (2): (a) pushed branch + template — correct English `type(scope): subject`, body filled from `PROJECT.md` facts, no AI trailer; (b) dirty working tree — stop and ask the senior to push/commit first.
- [ ] **Step 4:** Write `flow-ship` (2): (a) PASS on SHA X, head moved to Y — refuse to merge; (b) PASS on current SHA — merge with the command from `PROJECT.md`, squash, matched head, never report merged before confirming.
- [ ] **Step 5:** Write `flow-review` (2): (a) diff touches files outside scope and no checks were run — FAIL with file:line findings and "Not run" as a finding; (b) the same session that wrote the code wants to review — refuse, require a fresh subagent.
- [ ] **Step 6:** Verify JSON + gate (same commands as Task 1), commit `feat: add flowkit evals for the delivery loop`.

### Task 3: New evals — debug, product-review

**Files:**
- Create: `.tmp/flowkit/skills/flow-debug/evals/evals.json`
- Create: `.tmp/flowkit/skills/product-review/evals/evals.json`

- [ ] **Step 1:** `flow-debug` (2): (a) a bug report with no reproduction — reproduce first, no blind fix; (b) a "quick fix" that deletes the failing test — refuse, fix the root cause in shared code and add a regression test.
- [ ] **Step 2:** `product-review` (2): (a) a spec without success metrics or acceptance criteria — verdict `CHANGES NEEDED` with blocker findings; (b) review stays read-only and cites location + why per finding.
- [ ] **Step 3:** Verify JSON + gate; commit `feat: add flowkit evals for debug and product review`.

### Task 4: PM smoke evals (1 each)

**Files:**
- Create: `.tmp/flowkit/skills/{write-spec,roadmap-update,sprint-planning,stakeholder-update,synthesize-research,competitive-brief,metrics-review,product-brainstorming}/evals/evals.json`

- [ ] **Step 1:** One realistic prompt per skill that exercises its core structure; 2–3 assertions each, focused on: correct output structure exists, decisions/assumptions called out, no `/command` or connector placeholder leaking into the response.
- [ ] **Step 2:** Verify JSON + gate; commit `feat: add flowkit pm smoke evals`.

### Task 5: Run all evals (controller-driven)

**Files:** Create `.tmp/flowkit/evals/REPORT.md`

- [ ] **Step 1:** For each of the 12 kit skills dispatch one read-only subagent: prompt it to read `SKILL.md`, answer each eval prompt as if in the neutral fixture, write nothing, and return a per-assertion PASS/FAIL table with evidence.
- [ ] **Step 2:** For the 8 PM skills dispatch 4 subagents (2 skills each), same contract.
- [ ] **Step 3:** Aggregate into `REPORT.md`: table per skill (assertions passed/failed), FAIL details, and a decision queue (fix skill / fix eval / known limitation).
- [ ] **Step 4:** Commit the report `docs: add flowkit eval report`.

### Task 6: Fix real failures and re-run

- [ ] **Step 1:** For each real FAIL (skill instruction missing/wrong/ambiguous), edit the affected `SKILL.md` minimally.
- [ ] **Step 2:** Re-run only the affected evals (fresh subagent), append results to `REPORT.md`.
- [ ] **Step 3:** Update report decision queue; gate green; commit `fix: correct skills found by evals` and push.

## Self-review notes

- Coverage: design §Scope → Tasks 1–4; design §Run → Task 5; design §Failures → Task 6; acceptance items 1–3 → Tasks 1–4 verify + Task 5 report; item 4 → Task 6 push.
- Consistency: all tasks use the same schema, fixture, and gate commands.
- Deferred per design: no automated model runner; PM evals stay shallow; no promotion.
