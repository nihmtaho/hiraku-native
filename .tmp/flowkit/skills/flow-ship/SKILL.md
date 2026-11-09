---
name: flow-ship
description: >-
  Merge a PR that holds a PASS verdict on its exact head SHA, using the merge mechanism
  named in PROJECT.md §Git & PR. Use when the coordinator holds a PASS and decides to
  merge, or asks whether a PR is ready to merge. Not for tagging or releasing.
compatibility: gh signed in; run from the repository root.
---

Read `PROJECT.md` at the repo root first. If it is missing, stop and ask the user to
create it from `PROJECT.md.example`.

## Workflow

1. Get the state: `gh pr view <pr> --json headRefOid,baseRefName,isDraft,state,statusCheckRollup`.
   - Head differs from the SHA that holds the PASS verdict: stop and tell the
     coordinator to review the new SHA.
   - A required check is pending: wait, then re-check. A check failed: tell the senior
     to fix it.
2. Verify the `[Unreleased]` changelog line and run the status check command listed in
   `PROJECT.md` §Status tracking. Divergent → tell the coordinator before merging.
3. Merge exactly the reviewed SHA with the command in `PROJECT.md` §Git & PR, matching
   the head SHA.
4. If GitHub refuses (for example a required check from a ruleset), report the error
   verbatim. Do not repeat the command and do not use an admin bypass.
5. After the command succeeds, confirm the real state: `gh pr view <pr> --json state,mergeCommit`.
   - `MERGED`: report `MERGED` with the merge SHA.
   - Still `OPEN`: report `AUTO_MERGE_PENDING` or the error; never report merged.
6. Record the PR, SHA, and result in the task record.

## Limits

- No tag, no release, no version bump, no commits pushed after review.
- Never report PASS for a check that was not run.
- Never merge without a PASS on the current head SHA.

## Output

`MERGED`, `AUTO_MERGE_PENDING`, or `BLOCKED` (with the verbatim reason), plus the PR
number, SHA, and commands run.
