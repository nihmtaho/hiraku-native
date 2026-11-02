---
name: hiraku-create-pr
description: Senior opens or updates a pull request for a pushed task branch against the base, using the repo PR template, with real check evidence. Use after a branch is pushed and before handing off to the coordinator for review.
compatibility: GitHub CLI and Git; run from the repo root. Base branch, template path and CHANGELOG/ROADMAP rules come from the repo binding.
---

## Input

Pushed branch name, the task record path, and the base branch.

## Steps

1. **Check the branch.** Working tree clean, branch pushed, head SHA recorded.
   Refuse if the branch is the base, or if it is behind the base and not yet rebased.
2. **Look for an existing PR.** Search by head branch. If one exists, update it
   and do not open a second one.
3. **Fill the template.** Use the repo PR template. Summary, linked task, changes,
   checks with exit codes and artifact paths, risks, in the language the binding sets.
4. **Update tracking files** the record names (changelog, roadmap
   status). Push them as part of the same branch.
5. **Open or update the PR** against the base. Do not mark ready while checks are
   failing or required evidence is missing.
6. **Report** the PR number and head SHA to the coordinator.

## Edge cases

- **Base has moved:** rebase the branch on the base, re-run checks, push with
  `--force-with-lease`, then update the PR. The old SHA's review no longer applies.
- **Conflict during rebase:** follow the coding skill's conflict rule before
  continuing; never leave conflict markers.
- **Touches policy, checker or CI files:** still open the PR, but mark it so the
  coordinator routes it to the operator. Do not attempt to merge it.
- **Missing evidence for a check:** write `Not run` with the reason. Never write PASS.
- **Attribution:** no AI generation notice, co-author line or robot emoji in the
  title, body or commits.

## Output

PR number, URL, head SHA, base, check table with real results, and whether the PR
touches protected paths. Done when the PR exists and the head SHA is recorded in
the task record.
