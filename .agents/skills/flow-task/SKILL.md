---
name: flow-task
description: >-
  The coordinator creates or updates a task record from the template, checking work
  items, spikes, dependencies, unresolved open decisions and checkpoints before
  assigning the senior (flow-implement); use when assigning a new task, resuming, or
  changing task state.
compatibility: Git and gh signed in; Node.js 24+; run from the repository root.
---

Read `PROJECT.md` at the repo root first. If it is missing, stop and ask the user to
create it from `.agents/PROJECT.md.example`.

## Workflow

1. Gather compact context instead of reading the status and decision documents end to
   end: run the context commands listed in `PROJECT.md` §Status tracking with the work
   item, spike, or open decision id. They print the work-item line, its dependencies,
   its current state, the unresolved open decisions (direct or through dependencies),
   and the related checkpoint. Open only the document sections that output mentions.
2. Decide whether it can be assigned:
   - A dependency is not yet done, or a directly related open decision that affects
     behavior is still unresolved → the task is `blocked`; ask the PO exactly that
     question. Block only the affected part; independent parts can still be split into
     a separate task.
   - Open decisions reached through a dependency: record them under "Blocking
     decision / checkpoint" so the senior knows; do not resolve them yourself.
3. Name the `task-id` in kebab-case per `PROJECT.md` §Git & PR (for example
   `<milestone>-<number>-<summary>` for a spike, `<area>-<number>-<summary>` for a work
   item). Branch: `<type>/<task-id>-<short-summary>` per `PROJECT.md` §Git & PR.
4. Create the task record where `PROJECT.md` §Status tracking says, from the template
   it names, written in English. Fill the Contract section completely: goal, out of
   scope, files/modules to change, required documents (path + section), blocking open
   decisions/checkpoints, PO decisions already made (verbatim, with their source).
5. Write observable acceptance criteria, including failure/rollback cases and the
   environment/device; never use "tests pass" in place of describing behavior. Fill the
   Checks table with the concrete commands from `PROJECT.md` §Checks and a result
   column left at `Not run`.
6. Record the base: `git rev-parse` on the base branch named in `PROJECT.md` §Git & PR
   (or the working tree). Change the work-item state with `flow-status` — the states
   defined in `PROJECT.md` — when the senior starts. Add an `Execution plan:` line
   pointing to the plan file that keeps per-slice checkboxes; when handing over,
   mention both the record and the plan; on resume, read both.
7. Split the plan into 2–5 slices (code/test/docs/verify; each slice shippable as one
   PR). Check for duplicates before creating: `gh issue list --search "[<task-id>]
   <slice>"`. Create with `gh issue create` using the issue template and labels named
   in `PROJECT.md` §Status tracking and the title `[<task-id>] <slice>: <goal>`,
   linking both the record and the plan anchor. Record the issues table (issue number,
   slice, plan anchor, state) in the record. The record is the contract, the plan is
   progress, the issues are slice state.
8. Resume: re-read the record and the plan, compare the actual revision with the
   record; if the revision changed, mark the old review/approval void under "Next".

## Handoff and stop conditions

The task packet for the senior includes: record and plan paths, base, file scope,
acceptance criteria, check commands, and the blocking open decision. Missing behavioral
information or a directly related open decision still unresolved → the record stays
`blocked`; return BLOCKED with a concrete question for the PO instead of making the
senior guess.

If you are reviewing: use the steps as a checklist to verify the record has enough
scope, criteria, and decisions; do not edit the record (that is the coordinator's job).
