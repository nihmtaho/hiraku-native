#!/usr/bin/env sh
# Rebase the current branch onto the latest base branch.
# Usage: update-onto-base.sh [<base-branch>]   (auto-detects if omitted)
set -eu

BRANCH=$(git rev-parse --abbrev-ref HEAD)
case "$BRANCH" in
  main|master|HEAD) echo "ERROR: refusing to rebase '$BRANCH'." >&2; exit 1 ;;
esac

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "ERROR: commit or stash your changes before rebasing." >&2; exit 1
fi

BASE="${1:-}"
if [ -z "$BASE" ]; then
  BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)
  if [ -z "$BASE" ]; then
    for c in main master develop; do
      if git show-ref --verify --quiet "refs/heads/$c"; then BASE="$c"; break; fi
    done
  fi
fi
[ -n "$BASE" ] || { echo "ERROR: could not detect base; pass it explicitly." >&2; exit 1; }

echo "Fetching origin/$BASE ..."
git fetch origin "$BASE"

if git show-ref --verify --quiet "refs/remotes/origin/$BASE"; then
  TARGET="origin/$BASE"
else
  TARGET="$BASE"
fi

echo "Rebasing $BRANCH onto $TARGET ..."
git rebase "$TARGET"
echo "Done. If all looks good, push with: git push --force-with-lease"
