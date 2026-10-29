#!/usr/bin/env sh
# Install the suite's git hooks into the current repository.
# Honors a configured core.hooksPath; otherwise uses .git/hooks.
set -eu
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SRC_DIR="$DIR/../hooks"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERROR: run this from inside a git repository." >&2; exit 1; }

HOOKS_PATH=$(git config --get core.hooksPath || true)
if [ -n "$HOOKS_PATH" ]; then
  DEST_DIR="$HOOKS_PATH"
else
  DEST_DIR="$(git rev-parse --git-path hooks)"
fi
mkdir -p "$DEST_DIR"

for h in commit-msg pre-commit; do
  if [ -f "$SRC_DIR/$h" ]; then
    cp "$SRC_DIR/$h" "$DEST_DIR/$h"
    chmod +x "$DEST_DIR/$h"
    echo "Installed $h -> $DEST_DIR/$h"
  fi
done

echo "Test: git commit --allow-empty -m 'bad message'   (should be rejected)"
