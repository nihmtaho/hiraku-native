#!/usr/bin/env sh
# Read-only view of what is currently staged, to help write the commit message.
set -eu

if git diff --cached --quiet; then
  echo "Nothing staged."
  exit 0
fi

echo "== Branch =="
git rev-parse --abbrev-ref HEAD
echo
echo "== Staged files =="
git diff --cached --name-status
echo
echo "== Staged diffstat =="
git diff --cached --stat
