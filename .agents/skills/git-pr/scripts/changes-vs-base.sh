#!/usr/bin/env sh
# Summarize what the current branch adds over its base branch (read-only).
#
# Usage:
#   changes-vs-base.sh                 # auto-detect base (origin/HEAD, then main/master/develop)
#   changes-vs-base.sh <base-branch>   # compare against an explicit base
set -eu

BASE="${1:-}"
if [ -z "$BASE" ]; then
  BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null \
    | sed 's#^origin/##' || true)
  if [ -z "$BASE" ]; then
    for c in main master develop; do
      if git show-ref --verify --quiet "refs/heads/$c"; then BASE="$c"; break; fi
    done
  fi
fi
[ -n "$BASE" ] || { echo "ERROR: could not detect base branch; pass it explicitly." >&2; exit 1; }

MB=$(git merge-base "$BASE" HEAD)
SHORT=$(git rev-parse --short "$MB")

echo "# Base: $BASE  (merge-base $SHORT)"
echo
echo "== Commits on this branch =="
git log --no-merges --reverse --pretty=format:'- %s' "$MB..HEAD"
echo
echo
echo "== Files changed =="
git diff --stat "$MB..HEAD"
