---
name: git-rebase
description: Clean up branch history safely before review — squash/reword/reorder commits with interactive rebase, update a branch onto its latest base, and recover if a rebase goes wrong. Use when the user wants to tidy commits, rebase onto main, or resolve rebase conflicts. Never rewrites shared history without confirmation.
---

# Git Rebase

Tidy a feature branch's history so it reviews cleanly, without losing work.

## Hard rules
- Rewriting history is destructive. Before ANY rewrite, confirm with the user and
  make a safety ref: `git branch backup/<branch>-$(date +%s)`.
- Only rewrite branches that are unshared, or where everyone agrees.
- After a rewrite, push with `--force-with-lease`, never plain `--force`.
- Never rebase `main`/`master` or any protected branch.

## Workflow
1. Snapshot and create a safety backup branch:
   ```sh
   scripts/safe-start.sh                 # shows state + creates backup/<branch>-<ts>
   ```
2. Pick the operation:
   - **Update onto latest base** (resolve "behind main"):
     ```sh
     scripts/update-onto-base.sh         # or: scripts/update-onto-base.sh <base>
     ```
   - **Clean up commits** (squash/reword/reorder) — this opens your editor:
     ```sh
     git rebase -i "$(git merge-base HEAD <base>)"
     ```
     Guidance for the todo list is in `references/rebase-guide.md`.
3. If conflicts appear: fix files, `git add`, then `git rebase --continue`.
   To bail out at any point: `git rebase --abort` (returns to the pre-rebase state).
4. Push the tidied branch:
   ```sh
   git push --force-with-lease
   ```
5. If something went wrong, recover from the backup branch or `git reflog`
   (see the guide).

## Files
- `references/rebase-guide.md` — interactive commands, conflict and recovery steps.
- `scripts/safe-start.sh` — snapshot + create a timestamped backup branch.
- `scripts/update-onto-base.sh` — fetch base and rebase the branch onto it.
