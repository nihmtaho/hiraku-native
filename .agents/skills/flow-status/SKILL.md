---
name: flow-status
description: >-
  Change a task's state everywhere at once: run the status commands from PROJECT.md
  §Status tracking so the board, the task record and the changelog stay in step, and
  the status check passes. Use when assigning a task, opening a PR, merging, or when
  blocked, and when a review needs the places checked for consistency.
compatibility: Node.js 24+; run from the repository root.
---

Read `PROJECT.md` at the repo root first. If it is missing, stop and ask the user to
create it from `.agents/PROJECT.md.example`.

This skill is a protocol: it names no scripts of its own. Every command it needs is
listed in `PROJECT.md` §Status tracking.

## When

Every time a state changes per `PROJECT.md` §Git & PR: assigning a task (to the
in-progress state), opening a PR (to in review), merging with every exit criterion met
(to done), or being blocked (keep the state and record the blocker). The state values
are the ones defined in `PROJECT.md`; never invent one. If a task appears on no board,
report it; do not invent a state.

## Workflow

1. Read the exact task id as it appears on the status board named in `PROJECT.md`
   §Status tracking. Never invent a new id; an id with no card on the board → report
   to the coordinator.
2. Update every place in one go with the status commands listed in `PROJECT.md`
   §Status tracking. A state change always carries a fresh note; the old note is
   usually stale now. If a command reports a missing card or a note it cannot write:
   fix that place by hand; do not skip it.
3. For a PR with changes: add one line under the right one of the changelog groups
   named in `PROJECT.md` §Status tracking, in the `[Unreleased]` section of the
   changelog named there, in English (or the language named in `PROJECT.md`
   §Quality rules), ending with `(<task-id>, PR <n>)`. No PR number yet → write
   `PR —`; the coordinator fills it in. Never edit the history below `[Unreleased]`.
4. Check consistency and put the result in the handoff: run the status check command
   listed in `PROJECT.md` §Status tracking. It must pass before the task can be
   closed.

`done` only when every exit criterion of the task is met; a partial PR stays in
progress and records the remainder in the note. Merging does not mean the PO accepted
the milestone.

## Handoff and stop conditions

Return: task id, old → new state, changelog line added, status check result. Missing
board card, a state that contradicts the exit criteria, or an open decision blocking
the task and not yet recorded → BLOCKED; never switch to done to get past it.

If you are reviewing: run only the status check command and read the changelog diff;
divergence or a missing line is a blocking finding. Do not run update commands, do not
edit files.
