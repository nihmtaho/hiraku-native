---
name: hiraku-coding
description: Senior implements an assigned task end to end — survey, branch or worktree, code and tests, self-review, commit, push, rebase or conflict fixes, and feedback from the coordinator. Use whenever a task record is handed to a senior session or findings come back for changes.
compatibility: Git; run from the repo root. Binding (base, paths, test commands) lives in the task record and repo docs.
---

## Input

Task record path (the binding names where records live), base branch, and any review findings.
Stop and report if the record is missing or its acceptance criteria are empty.

## Steps

1. **Survey.** Read the record, then only the docs and code it names. Confirm the
   working tree state before touching anything.
2. **Isolate.** Create a branch `<type>/<task-id>` from the base, or a dedicated
   worktree. Never reuse a dirty tree from another task.
3. **Implement.** Change only the files listed in the record. Keep comments and
   identifiers as the binding requires. Do not change policy, generated output or CI unless the
   record names them.
4. **Test.** Run every check in the record's Checks table. Record the real exit
   code and output path. A skipped or missing command is `Not run`, never PASS.
5. **Self-review.** Read your own diff against the acceptance criteria. Note the
   result for the coordinator; this is not an independent verdict.
6. **Commit.** Small, conventional commits. Never `--amend` a pushed commit, never
   skip hooks.
7. **Push.** `git push -u origin <branch>`. After a rebase on the base, use
   `git push --force-with-lease origin <branch>` on this branch only.

## Edge cases

- **Conflict on rebase or merge:** resolve in the branch, re-run the checks, and
  record the conflict and its resolution in the handoff. If the resolution changes
  behavior outside the record's scope, stop and report.
- **Pending CI after push:** report pending. Do not declare done.
- **Findings from review:** fix only the listed findings. Any new commit makes the
  previous review void; say so in the handoff.
- **Blocker or unknown requirement:** stop, list the open question, and wait.
- **Never** push to the base branch, use bare `--force`, or edit tags or releases.

## Output

Handoff to the coordinator: branch, head SHA, PR link if one exists, each check
with exit code and artifact path, the self-review result, and open risks. Update
the record's Coding and Checks sections; do not change its Contract.

Done when the record's checks have real results and the branch is pushed.
