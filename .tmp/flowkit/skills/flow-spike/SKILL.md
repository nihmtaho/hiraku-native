---
name: flow-spike
description: >-
  Run a time-boxed spike and record its evidence in the spike report file named in
  PROJECT.md §Docs map: question and pass criteria written before running, raw logs
  kept outside the repo, toolchain and git revision recorded, the verification ladder,
  and a four-value verdict. Use when performing or reporting a spike, measuring
  performance, or verifying feasibility before a gate.
compatibility: The toolchain the spike names; run from the repository root.
---

Read `PROJECT.md` at the repo root first. If it is missing, stop and ask the user to
create it from the kit's `PROJECT.md.example`.

A spike is a time-boxed experiment: it answers one question and produces evidence, not
product code.

## Input and sources

Receive the task packet with the spike id. Read the spike line in the spec named in
`PROJECT.md` §Docs map (its question and pass criteria), the milestone and gate
content in the planning document it names, and the decision records referenced there.
A criterion still marked "proposed, PO to confirm": measure and record the number;
never conclude pass against a threshold that is not confirmed.

## Workflow

1. Write down before running: the question, the pass criteria (quoted verbatim), the
   environment needed (simulator/emulator, workstation, real device — the project
   names its real environment), and the planned commands.
2. Keep experiment code out of product code (location named in `PROJECT.md`
   §Architecture rules). No imports from product packages into the spike, and none
   from the spike into product packages. New dependencies still need a decision record
   and PO approval.
3. Run commands one at a time; keep every exit code and its output. Raw logs go to
   the temp directory named in `PROJECT.md` §Docs map — outside the repository. Build
   artifacts go to the module's build directory (gitignored). The report quotes only
   the parts needed as evidence.
4. Record toolchain and environment: language toolchain, SDK and OS, machine model,
   library versions actually in use, and the revision (`git rev-parse HEAD`, or the
   working-tree state).
5. Tag every result with its **verification level** and never raise it. The ladder is
   `build-only → local run → real environment`; the project names its real environment
   in `PROJECT.md` §Docs map or in the task. A missing environment is recorded as
   "not verified in <level>", never replaced by a lower level's result.
6. Conclude each item with exactly one of: **Pass**, **Fail**, **Not run**,
   **Blocked** (Blocked names what blocks it). Only Pass counts; Not run and Blocked
   never count as a pass. Never weaken or downgrade a criterion after the fact to make
   it pass.
7. Add or replace the `## <spike-id>` section in the spike report file named in
   `PROJECT.md` §Docs map, following the report template named there. Never delete
   another spike's results; a re-run records a new date and keeps the reason for the
   change.
8. A spike that misses a mandatory criterion at the gate: state the fallback option
   already recorded in the spec or decision records, then stop and wait for the PO;
   never change the architecture yourself.
9. Update status with `flow-status` per `PROJECT.md` §Status tracking.

## Handoff and stop conditions

Return: the spike code, a table of item → command → exit code → result → verification
level, the conclusions, remaining work, and decisions the PO must make. Missing
environment, toolchain, or unconfirmed criteria: PARTIAL/BLOCKED; never report Pass.

If you are reviewing: check the report against the spec's criteria, that commands are
re-runnable, and that verification levels and numbers match the raw logs; do not re-run
measurements on real devices on the tester's behalf, and do not edit the report.
