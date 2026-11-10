# Flowkit eval report

Date: 2026-11-11 · Branch: `feat/portable-skills-kit` · Revision: evals at `69e2a9d`

Method: repo convention (`<skill>/evals/evals.json`, read-only per prompt). Each skill was run by
one fresh read-only subagent: it read `SKILL.md`, answered every eval prompt against the fixture
stated in the prompt, then graded each assertion strictly. No files were edited, no commands
executed. 8 PM skills ran 2 per subagent; 12 kit skills one each.

Result: **101/101 assertions pass** across 20 skills (36 eval prompts).

## Per-skill results

| Skill | Evals | Assertions | Passed |
|---|---|---|---|
| flow-coordinator | 2 | 6 | 6 |
| flow-task | 2 | 6 | 6 |
| flow-implement | 2 | 6 | 6 |
| flow-pr | 2 | 7 | 7 |
| flow-review | 2 | 7 | 7 |
| flow-ship | 2 | 7 | 7 |
| flow-status | 2 | 6 | 6 |
| flow-interface | 2 | 6 | 6 |
| flow-feature | 2 | 6 | 6 |
| flow-spike | 2 | 6 | 6 |
| flow-debug | 2 | 7 | 7 |
| product-review | 2 | 7 | 7 |
| write-spec | 1 | 3 | 3 |
| roadmap-update | 1 | 3 | 3 |
| sprint-planning | 1 | 3 | 3 |
| stakeholder-update | 1 | 3 | 3 |
| synthesize-research | 1 | 3 | 3 |
| competitive-brief | 1 | 3 | 3 |
| metrics-review | 1 | 3 | 3 |
| product-brainstorming | 1 | 3 | 3 |

## What the run exercised

- Guardrails: PASS-by-SHA void after a new push (coordinator, task, ship), fresh-session review
  (review), dirty tree refusal (pr), scope drift (implement, review), missing `PROJECT.md`
  (implement), reproduce-first and "no fix by deleting tests" (debug), read-only review and
  READY/CHANGES NEEDED verdicts (product-review).
- Adaptation risks in PM skills: output structure present, assumptions/owners called out, no
  `/command` line and no connector placeholder leaked into any response.

## No failures to fix

No assertion failed, so no `SKILL.md` change was needed. Two eval-side false-fail/false-pass
classes were removed during authoring (see review notes): the debug floating-point premise, the
roadmap "what comes off" demand, the brainstorming conversation rule, and the research quote count.

## Known limits of this evidence

1. **Self-graded.** The same agent that answered also graded. Strictness was instructed, but an
   independent grader would be stronger evidence.
2. **Response-only.** Skills whose contract includes running commands or editing files were graded
   on the plan they state, not on real tool output. Command syntax is asserted for form, not for
   execution.
3. **Uniform fixture.** All evals use one neutral TypeScript SaaS fixture, which fits the delivery
   skills well but is less natural for `flow-feature` (SwiftUI-oriented) and the PM skills; the
   skills' own project-specific assumptions are therefore under-tested.
4. **No discriminating baseline.** A 100% pass rate can also mean lenient assertions. If this suite
   is used to compare future skill revisions, run a baseline (skill removed) set to confirm the
   assertions separate good from bad answers.
5. PM skill bodies are verbatim upstream copies; only the smoke-level adaptation risks are covered.

## Decision queue

- No skill fix required from this run.
- Deferred (from task reviews, cosmetic): `flow-debug` expected-output/assertion detail on exit
  codes; `flow-debug`/`flow-feature`/`flow-interface` use `PARTIAL` without defining it; sprint
  capacity mixes points and days (inherited from the PM template).
- Recommended before promotion: one independent grading pass and a no-skill baseline for 3–4
  discriminating evals (`flow-ship`, `flow-review`, `flow-debug`, `flow-status`).
