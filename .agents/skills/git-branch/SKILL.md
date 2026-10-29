---
name: git-branch
# Cross-tool rule keys (ignored by Claude Code / OpenCode):
alwaysApply: false         # Cursor
trigger: model_decision    # Windsurf
inclusion: manual          # Kiro
description: Create and name branches consistently, tied to the work type and issue. Use when the user starts new work, asks to create/switch a branch, or wants a branch naming convention. Keeps branch names aligned with Conventional Commit types.
---

# Git Branch

Create well-named branches off an up-to-date base.

## Hard rules
- Branch off the latest base (default branch), not stale local state.
- Never create work directly on `main`/`master`.
- One branch per logical unit of work.

## Naming convention
```
<type>/<short-kebab-summary>
<type>/<issue-id>-<short-kebab-summary>
```
`<type>` matches commit types: `feat`, `fix`, `hotfix`, `chore`, `docs`,
`refactor`, `test`, `release`. Examples:
- `feat/passkey-login`
- `fix/142-null-token-crash`
- `release/v1.2.0`

See `references/branch-convention.md` for the full table.

## Workflow
1. Create the branch from a fresh base (updates base, then branches):
   ```sh
   scripts/new-branch.sh feat passkey login            # -> feat/passkey-login
   scripts/new-branch.sh fix 142 null token crash      # -> fix/142-null-token-crash
   scripts/new-branch.sh -b develop feat dark mode     # explicit base via -b
   ```
2. The script validates the type, builds a safe kebab-case name, fetches, and
   switches you onto the new branch.
3. Hand off to `git-commit` for the first commit.

## Files
- `references/branch-convention.md` — type table + naming rules.
- `scripts/new-branch.sh` — validate, build name, update base, create + switch.
