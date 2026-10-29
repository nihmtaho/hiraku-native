#!/usr/bin/env sh
# Prepare for a safe rebase: show state and create a timestamped backup branch.
set -eu
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not inside a git repository." >&2; exit 1; }

BRANCH=$(git rev-parse --abbrev-ref HEAD)
case "$BRANCH" in
  main|master|HEAD) echo "ERROR: refusing to rebase '$BRANCH'." >&2; exit 1 ;;
esac

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "WARNING: you have uncommitted changes. Commit or stash before rebasing." >&2
fi

BACKUP="backup/${BRANCH}-$(date +%s)"
git branch "$BACKUP"
echo "Safety branch created: $BACKUP"
echo
echo "== Current branch =="; echo "$BRANCH"
echo "== Recent commits =="; git log --oneline -10 --decorate
echo
echo "Recover anytime with: git reset --hard $BACKUP"
