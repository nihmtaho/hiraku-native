# Flowkit eval report

Date: 2026-11-11 · Branch: `feat/portable-skills-kit` · Revision: evals as edited at `9c042c0`;
the first full run was at `69e2a9d`. Four skills whose evals changed after the first run
(`flow-feature`, `flow-status`, `sprint-planning`, `synthesize-research`) were re-run at `9c042c0`
and passed 18/18; the other 16 skills' eval files are unchanged since their run.

Method: repo convention (`<skill>/evals/evals.json`, read-only per prompt). Each skill was run by
one fresh read-only subagent: it read `SKILL.md`, answered every eval prompt against the fixture
stated in the prompt, then graded each assertion strictly. No files were edited, no commands
executed. 8 skills (one prompt each) ran two per subagent; 12 skills (two prompts each) ran one per
subagent.

Gate: `node .tmp/flowkit/scripts/check-kit.mjs` → `flowkit check: OK` (exit 0), run while the kit
lived in `.tmp/flowkit/`. That copy was removed after adoption, so the gate is no longer
reproducible; the current repo checks are `node --test .agents/hiraku/tests/*.test.mjs` and
`node .agents/scripts/wp-status.mjs --check`, and neither tests portability or neutrality.

Result: **101/101 assertions pass** across 20 skills (32 eval prompts: 12 skills × 2 + 8 skills × 1).

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

No assertion failed, so no `SKILL.md` change was needed. Four eval-side false-fail/false-pass
classes were removed during authoring: the debug floating-point premise, the roadmap "what comes
off" demand, the brainstorming conversation rule, and the research quote count.

## Known limits of this evidence

1. **Self-graded.** The same agent that answered also graded. Strictness was instructed, but an
   independent grader would be stronger evidence.
2. **Not blind.** The answering subagent had the eval file open, so `expected_output` and the
   assertions were visible while it wrote each answer; part of 101/101 is therefore self-fulfilling.
   The recommended independent pass should answer from the prompt alone, with the eval file withheld.
3. **Response-only.** Skills whose contract includes running commands or editing files were graded
   on the plan they state, not on real tool output. Command syntax is asserted for form, not for
   execution.
4. **Uniform fixture.** All evals use one neutral TypeScript SaaS fixture, which fits the delivery
   skills well but is less natural for `flow-feature` (SwiftUI-oriented) and the PM skills; the
   skills' own project-specific assumptions are therefore under-tested.
5. **No discriminating baseline.** A 100% pass rate can also mean lenient assertions. If this suite
   is used to compare future skill revisions, run a baseline (skill removed) set to confirm the
   assertions separate good from bad answers.
6. **Structural assertions pass on headings.** Several PM A1s check that the named sections exist,
   so a response that lists headings with thin content still passes; the per-assertion total hides
   this because one structural assertion stands in for the whole structure.
7. PM skill bodies are verbatim upstream copies; only the smoke-level adaptation risks are covered.

## Decision queue

- No skill fix required from this run.
- Deferred (from task reviews, cosmetic): `flow-debug` expected-output/assertion detail on exit
  codes; `flow-debug`/`flow-feature`/`flow-interface` use `PARTIAL` without defining it; sprint
  capacity mixes points and days (inherited from the PM template).
- Recommended before promotion: one independent grading pass and a no-skill baseline for 3–4
  discriminating evals (`flow-ship`, `flow-review`, `flow-debug`, `flow-status`).
