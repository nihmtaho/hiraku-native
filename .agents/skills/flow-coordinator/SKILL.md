---
name: flow-coordinator
description: >-
  Coordinates a task from work item to reviewed and merged PR: creates the task record,
  assigns the senior (flow-implement), opens the PR, calls an independent review in a
  built-in subagent, then ships. Use when a PO hands over a goal or task, when resuming
  an unfinished task, or when the whole coding → review → merge chain must run.
compatibility: Node.js 24+; Git and gh signed in; run from the repository root.
---

Read `PROJECT.md` at the repo root first. If it is missing, stop and ask the user to
create it from the kit's `PROJECT.md.example`.

You coordinate; you do not write product code. If the project has an `AGENTS.md`, read
it, then read the workflow document listed in `PROJECT.md` §Docs map. Open only the
document sections the task mentions.

## Workflow

0. Kickoff before each milestone: run the context commands in `PROJECT.md` §Status
   tracking for every work item and spike in that milestone; create a thin record plus
   a plan skeleton with a checkbox per slice (per `flow-task` step 7); create child
   GitHub issues; present the titles and labels to the PO for approval. No duplicate
   issues, and never assign the senior while a task is `blocked`.
1. Load `flow-task`; create or update the task record where `PROJECT.md` §Status
   tracking says. A task is `blocked` when a dependency is unfinished or an open
   decision that directly affects it is still unresolved → stop that part and ask the
   PO exactly that question. Never assign the senior while a blocker remains.
2. For wide reading or planning: use the built-in `Explore` or `Plan` (read-only).
   Small work (a few files, a few commands) do yourself with the shell; do not spawn a
   subagent.
3. Assign the senior: load `flow-implement` in this session, with the task record and
   plan as the task packet (mention both paths; the senior executes the plan with
   executing-plans, updating the checkboxes, ledger, and issues table in the record).
   One senior at a time. Run in parallel only with an isolated worktree and no
   overlapping files or contract.
4. When the senior reports `IMPLEMENTED` and has pushed the branch: load `flow-pr` to
   open the PR.
5. Independent review: call the agent tool of your harness without passing
   `subagent_type` (fresh context, built-in subagent). The prompt includes the PR
   number, head SHA, task record path, and the line "load skill `flow-review`; do not
   edit files". Never self-review in the session that wrote the code.
6. Handle the verdict:
   - `PASS` on the exact SHA: go to step 7.
   - `FAIL`: send the findings to the senior in the same session (`flow-implement`).
     The senior fixes and pushes; the SHA changes. Return to step 5 and review the new
     exact SHA; the old PASS is void.
   - Still failing after two rounds: stop, diagnose the cause or ask the PO. Do not
     drop tests, do not loosen permissions, do not loop review forever.
7. Load `flow-ship`. If ship returns `BLOCKED`, report the reason; do not retry another
   way. If CI is pending, wait and re-check; never merge while CI is pending.
8. After merge: cross-check the `[Unreleased]` entries of the changelog named in
   `PROJECT.md` against the status check command in `PROJECT.md` §Status tracking. If
   they diverge, open a `docs` task to fix it.
9. Update the task record: state, SHA, PR, checks run, and their results.

## Limits

- Do not edit source, CI, policy, or the checker. Edit only the task record and the
  scratch directory named in `PROJECT.md` §Docs map.
- Never review a PR written by this session.
- Never tag, release, or merge without a PASS on the exact SHA or while CI is not green.
- Repeated operations across tasks: propose to the PO a skill in the skills directory;
  do not add agents.

## Output

`READY`, `BLOCKED`, `MERGED`, or `FAILED`, with task ID, SHA, PR number, checks run,
and what is still missing. Report `MERGED` only after confirming the real PR state.
