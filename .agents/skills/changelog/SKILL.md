---
name: Changelog
# Cross-tool rule keys (ignored by Claude Code / OpenCode):
alwaysApply: false         # Cursor
trigger: model_decision    # Windsurf
inclusion: manual          # Kiro
description: Maintain a cumulative CHANGELOG.md in Keep a Changelog format. Use when the user wants to add entries under an Unreleased section, or stamp Unreleased into a dated version during a release. Pairs with git-release (one-off notes) by keeping a durable, hand-curated history.
---

# Changelog

Keep a durable, human-curated `CHANGELOG.md` across releases, in
[Keep a Changelog](https://keepachangelog.com/) format with SemVer versions.

This differs from `git-release`: that skill drafts one release's notes from git
log; this skill maintains the running file that lives in the repo.

## Hard rules
- Never add AI attribution lines.
- Write for humans: group by change category, newest version on top.
- Keep an `## [Unreleased]` section at the top for in-progress work.

## Workflow
1. If the file is missing, create the scaffold:
   ```sh
   scripts/changelog.sh init
   ```
2. Add an entry under `## [Unreleased]` (category: added|changed|deprecated|removed|fixed|security):
   ```sh
   scripts/changelog.sh add fixed "Reject expired refresh tokens"
   ```
3. At release time, stamp Unreleased into a dated version and open a fresh
   Unreleased section:
   ```sh
   scripts/changelog.sh release 1.2.0
   ```
4. Review the diff, then verify no AI trailers slipped in:
   ```sh
   ../git-commit/scripts/guard-no-ai-trailer.sh CHANGELOG.md
   ```

## Files
- `references/changelog-format.md` — section order, categories, example.
- `scripts/changelog.sh` — `init` | `add <category> <text>` | `release <version>`.
