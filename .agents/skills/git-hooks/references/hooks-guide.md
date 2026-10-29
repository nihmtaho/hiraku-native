# Git Hooks Guide

## How git finds hooks
Git runs hooks from, in order of precedence:
1. `core.hooksPath` if set — `git config --get core.hooksPath`
2. otherwise `$(git rev-parse --git-path hooks)` (usually `.git/hooks`)

`install-hooks.sh` writes to whichever applies, so it works in plain repos,
worktrees, and repos that already use a shared hooks dir.

## The `commit-msg` hook
Receives the path to the commit message file as `$1`. It:
1. Rejects AI attribution trailers (same patterns as `guard-no-ai-trailer.sh`).
2. Requires the subject to match `^(type)(scope)?!?: summary`.
3. Caps the subject at 72 characters.
Merge, revert, and `fixup!`/`squash!`/`amend!` subjects pass through untouched.

Exit code `0` accepts the commit; non-zero rejects it.

## The `pre-commit` hook
Runs before the message is written. Refuses commits made directly on
`main`/`master`. Override a single commit with `ALLOW_MAIN=1 git commit …`.
Remove it if your project uses a trunk-based flow that commits on main.

## Sharing with the team
`.git/hooks` is NOT committed. Two options:
- **Shared dir in-repo (recommended):**
  ```sh
  mkdir -p .githooks
  cp hooks/commit-msg hooks/pre-commit .githooks/
  git config core.hooksPath .githooks
  git add .githooks/* && git commit -m "ci: add git hooks"
  ```
  Each teammate runs `git config core.hooksPath .githooks` once after cloning
  (or add it to a repo setup script).
- **Per clone:** everyone runs `git-hooks/scripts/install-hooks.sh`.

## Bypassing
`git commit --no-verify` skips the hook for one commit. Use sparingly; it defeats
the enforcement. The agent skills (`git-commit`, etc.) never pass `--no-verify`.

## Relationship to the other skills
This is the enforcement floor. `git-commit`, `git-release`, and `git-pr` also run
`guard-no-ai-trailer.sh` so drafts are clean before they ever reach the hook.
