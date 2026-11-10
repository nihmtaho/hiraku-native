---
name: flow-debug
description: >-
  Diagnose and fix a defect: reproduce it first with the exact command and output,
  narrow the cause from evidence, fix the root cause in shared code once, and prove
  the fix with a regression test that fails before it and passes after. Use when a
  bug, failing test, or unexpected behavior must be found and fixed.
compatibility: Git; the language toolchain named in PROJECT.md; run from the repository root.
---

Read `PROJECT.md` at the repo root first. If it is missing, stop and ask the user to
create it from the kit's `PROJECT.md.example`.

You debug a defect inside a task. Read the architecture rules named in `PROJECT.md`
§Architecture rules, including the sections the suspect code lives in. If the project
has an `AGENTS.md`, read it before editing.

## Workflow

1. Reproduce first: run the smallest command that shows the defect and record the
   exact command and output. No fix without a reproduction — or a written reason in
   the report that it cannot be reproduced.
2. Gather evidence: failing test, error output, logs, recent changes around the
   suspect path. Narrow the search space, then write the hypothesis before editing.
   Never edit on a hunch.
3. Find the root cause in the shared code — fix it once; never patch every caller.
4. Smallest fix that fully solves the defect. Add a regression test that fails before
   the fix and passes after; behavioral and short, one assertion theme.
5. Never "fix" by deleting tests, disabling checks, or swallowing errors.
6. Run the smallest check in `PROJECT.md` §Checks that covers the change; widen it
   when an interface is touched. Record the command and exit code.
7. Land the fix like any task change: update the documents the behavior change
   requires (paths per `PROJECT.md` §Docs map), commit per the `git-commit` skill,
   and update the task record with `flow-status` per `PROJECT.md` §Status tracking.

## Limits

- Stay inside the task scope; no refactors by preference, no new dependencies without
  PO approval.
- A check not run is recorded `Not run`; never report PASS for it.
- Never read signing or credential secrets (`.env*` except `.env.example`, `*.p8`,
  `*.p12`, `*.pem`, `*.key`).

## Output

`FIXED`, `PARTIAL`, or `BLOCKED`: reproduction command and output, root cause, fix
and regression-test locations, checks with exit codes, and unverified parts.
