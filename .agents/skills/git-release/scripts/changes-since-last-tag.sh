#!/usr/bin/env sh
# List commits since the last release, oldest first (tab-separated: sha, subject, author).
#
# Usage:
#   changes-since-last-tag.sh              # since the most recent tag
#   changes-since-last-tag.sh <base-ref>   # since an explicit ref (e.g. origin/main)
set -eu

BASE="${1:-}"
if [ -z "$BASE" ]; then
  BASE=$(git describe --tags --abbrev=0 2>/dev/null || true)
fi

if [ -n "$BASE" ]; then
  echo "# Changes since $BASE"
  RANGE="$BASE..HEAD"
else
  echo "# No previous tag found — listing all commits"
  RANGE="HEAD"
fi
echo

git log --no-merges --reverse --pretty=format:'%h%x09%s%x09%an' "$RANGE"
echo
