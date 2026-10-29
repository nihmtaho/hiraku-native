#!/usr/bin/env sh
# Read-only snapshot of repository state. Safe to run anytime.
set -eu

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not inside a git repository." >&2; exit 1; }

echo "== Branch =="
git rev-parse --abbrev-ref HEAD
echo
echo "== Status =="
git status --short --branch
echo
echo "== Last 10 commits =="
git log --oneline -10 --decorate
echo
echo "== Stashes =="
git stash list || true
echo
echo "== Remotes =="
git remote -v
