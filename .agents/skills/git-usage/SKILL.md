---
name: git-usage
description: Everyday git operations done safely — status, branching, staging, stashing, syncing, undoing mistakes, resolving conflicts. Use for any general git task that is not specifically committing, releasing, or opening a PR.
---

# Git Usage

Help the user drive git for day-to-day work without losing data.

## Hard rules
- Before any history-rewriting or destructive command (`reset --hard`, `rebase`,
  `clean -fd`, `push --force`, `checkout -- <file>`), state exactly what will be
  lost and get the user's confirmation first.
- Prefer `--force-with-lease` over `--force`.
- Never commit, release, or open a PR here — hand off to `git-commit`,
  `git-release`, or `git-pr` for those.

## Workflow
1. Start every session with a read-only snapshot so you act on real state:
   ```sh
   scripts/inspect.sh
   ```
2. Pick the recipe for the task from `references/recipes.md`.
3. Explain the command, run it, then re-run `scripts/inspect.sh` to confirm the
   result.

## Files
- `references/recipes.md` — copy-paste recipes for common and recovery tasks.
- `scripts/inspect.sh` — safe, read-only repository snapshot.
